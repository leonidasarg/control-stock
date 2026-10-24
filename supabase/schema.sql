-- Cotizador · Vestí Tu Negocio
-- Pegá todo esto en Supabase → SQL Editor → New query → Run. Se puede correr más de una vez:
-- nunca borra datos cargados.
--
-- Un solo espacio de trabajo para el negocio: todos los usuarios aprobados ven y editan los
-- mismos clientes, productos y cotizaciones. La primera cuenta que se registra es la del dueño;
-- las siguientes quedan pendientes hasta que el dueño las aprueba desde la app.

-- ------------------------------------------------------------------
-- Versión anterior (datos por usuario): se borra solo si está vacía.
-- ------------------------------------------------------------------
do $$
begin
  if to_regclass('public.cotizador_items') is not null
     and not exists (select 1 from public.cotizador_items) then
    drop table public.cotizador_items;
  end if;
  if to_regclass('public.cotizador_counters') is not null
     and not exists (select 1 from public.cotizador_counters) then
    drop table public.cotizador_counters;
  end if;
end $$;
drop function if exists public.cotizador_next_quote_number();
drop function if exists public.cotizador_release_quote_number(integer);

-- ------------------------------------------------------------------
-- Usuarios del cotizador y sus permisos
-- ------------------------------------------------------------------
create table if not exists public.cotizador_members (
  user_id    uuid        primary key references auth.users (id) on delete cascade,
  email      text        not null,
  role       text        not null default 'pending' check (role in ('owner', 'member', 'pending')),
  created_at timestamptz not null default now()
);

alter table public.cotizador_members enable row level security;

-- Se consultan desde las políticas; security definer evita que la política de
-- cotizador_members se llame a sí misma.
create or replace function public.cotizador_is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.cotizador_members
     where user_id = (select auth.uid()) and role in ('owner', 'member')
  );
$$;

create or replace function public.cotizador_is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.cotizador_members
     where user_id = (select auth.uid()) and role = 'owner'
  );
$$;

revoke all on function public.cotizador_is_member() from public, anon;
revoke all on function public.cotizador_is_owner() from public, anon;
grant execute on function public.cotizador_is_member() to authenticated;
grant execute on function public.cotizador_is_owner() to authenticated;

drop policy if exists "ver la propia cuenta y, si está aprobado, el equipo" on public.cotizador_members;
create policy "ver la propia cuenta y, si está aprobado, el equipo"
  on public.cotizador_members for select to authenticated
  using (user_id = (select auth.uid()) or (select public.cotizador_is_member()));

drop policy if exists "el dueño aprueba o cambia a los demás" on public.cotizador_members;
create policy "el dueño aprueba o cambia a los demás"
  on public.cotizador_members for update to authenticated
  using ((select public.cotizador_is_owner()) and user_id <> (select auth.uid()))
  with check (role in ('member', 'pending'));

drop policy if exists "el dueño quita a los demás" on public.cotizador_members;
create policy "el dueño quita a los demás"
  on public.cotizador_members for delete to authenticated
  using ((select public.cotizador_is_owner()) and user_id <> (select auth.uid()));

revoke all on public.cotizador_members from anon;
grant select, update, delete on public.cotizador_members to authenticated;

-- Cada cuenta nueva entra como pendiente; la primera de todas, como dueño.
create or replace function public.cotizador_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.cotizador_members (user_id, email, role)
  values (
    new.id,
    coalesce(new.email, ''),
    case when exists (select 1 from public.cotizador_members where role = 'owner') then 'pending' else 'owner' end
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function public.cotizador_handle_new_user() from public, anon, authenticated;

drop trigger if exists cotizador_on_auth_user_created on auth.users;
create trigger cotizador_on_auth_user_created
  after insert on auth.users
  for each row execute function public.cotizador_handle_new_user();

-- Cuentas que ya existían antes de correr este script.
insert into public.cotizador_members (user_id, email, role)
select u.id, coalesce(u.email, ''),
       case when row_number() over (order by u.created_at) = 1
             and not exists (select 1 from public.cotizador_members where role = 'owner')
            then 'owner' else 'pending' end
  from auth.users u
 where not exists (select 1 from public.cotizador_members m where m.user_id = u.id);

-- ------------------------------------------------------------------
-- Datos del negocio: clientes, productos, cotizaciones y ajustes como JSON
-- ------------------------------------------------------------------
create table if not exists public.cotizador_data (
  kind       text        not null check (kind in ('clients', 'products', 'quotes', 'settings')),
  id         text        not null,
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  updated_by uuid        default auth.uid() references auth.users (id) on delete set null,
  primary key (kind, id)
);

alter table public.cotizador_data enable row level security;

drop policy if exists "solo usuarios aprobados" on public.cotizador_data;
create policy "solo usuarios aprobados"
  on public.cotizador_data for all to authenticated
  using ((select public.cotizador_is_member()))
  with check ((select public.cotizador_is_member()));

revoke all on public.cotizador_data from anon;
grant select, insert, update, delete on public.cotizador_data to authenticated;

-- Red de seguridad: la base rechaza dos cotizaciones con el mismo número.
create unique index if not exists cotizador_data_quote_number_unique
  on public.cotizador_data (((data ->> 'number')::integer))
  where kind = 'quotes' and jsonb_typeof(data -> 'number') = 'number';

create index if not exists cotizador_data_updated_by_idx on public.cotizador_data (updated_by);

-- ------------------------------------------------------------------
-- Numeración de cotizaciones, compartida por todo el equipo.
-- El contador se bloquea mientras se incrementa: si dos personas piden número
-- al mismo tiempo, la segunda espera y recibe el siguiente.
-- ------------------------------------------------------------------
create table if not exists public.cotizador_counter (
  id                boolean primary key default true check (id),
  last_quote_number integer not null default 0
);

alter table public.cotizador_counter enable row level security;

drop policy if exists "solo usuarios aprobados" on public.cotizador_counter;
create policy "solo usuarios aprobados"
  on public.cotizador_counter for all to authenticated
  using ((select public.cotizador_is_member()))
  with check ((select public.cotizador_is_member()));

revoke all on public.cotizador_counter from anon;
grant select, insert, update on public.cotizador_counter to authenticated;

create or replace function public.cotizador_next_quote_number()
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  max_used integer;
  next_number integer;
begin
  if not public.cotizador_is_member() then
    raise exception 'Tu cuenta todavía no está aprobada';
  end if;

  select coalesce(max((data ->> 'number')::integer), 0)
    into max_used
    from public.cotizador_data
   where kind = 'quotes' and jsonb_typeof(data -> 'number') = 'number';

  insert into public.cotizador_counter as c (id, last_quote_number)
  values (true, max_used + 1)
  on conflict (id) do update
    set last_quote_number = greatest(c.last_quote_number, max_used) + 1
  returning last_quote_number into next_number;

  return next_number;
end;
$$;

-- Devuelve un número reservado que no se usó, solo si sigue siendo el último entregado.
create or replace function public.cotizador_release_quote_number(p_number integer)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.cotizador_counter
     set last_quote_number = last_quote_number - 1
   where id
     and last_quote_number = p_number
     and not exists (
       select 1 from public.cotizador_data
        where kind = 'quotes'
          and jsonb_typeof(data -> 'number') = 'number'
          and (data ->> 'number')::integer = p_number
     );
  return found;
end;
$$;

revoke all on function public.cotizador_next_quote_number() from public, anon;
revoke all on function public.cotizador_release_quote_number(integer) from public, anon;
grant execute on function public.cotizador_next_quote_number() to authenticated;
grant execute on function public.cotizador_release_quote_number(integer) to authenticated;
