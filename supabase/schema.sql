-- Cotizador · Vestí Tu Negocio
-- Pegá todo esto en Supabase → SQL Editor → New query → Run. Se puede correr más de una vez.
--
-- Una sola tabla guarda clientes, productos, cotizaciones y ajustes como JSON.
-- Cada fila queda atada al usuario que la creó y Row Level Security impide
-- que otro usuario (o alguien con la clave pública) la lea o la cambie.

create table if not exists public.cotizador_items (
  user_id    uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  kind       text        not null check (kind in ('clients', 'products', 'quotes', 'settings')),
  id         text        not null,
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, id)
);

alter table public.cotizador_items enable row level security;

drop policy if exists "cada usuario ve y edita solo lo suyo" on public.cotizador_items;
create policy "cada usuario ve y edita solo lo suyo"
  on public.cotizador_items
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.cotizador_items from anon;
grant select, insert, update, delete on public.cotizador_items to authenticated;

-- ------------------------------------------------------------------
-- Numeración de cotizaciones
-- El número lo reparte la base: un contador por usuario que se bloquea
-- mientras se incrementa, así dos sesiones al mismo tiempo nunca reciben
-- el mismo número. El primero que lo pide se lleva el siguiente.
-- ------------------------------------------------------------------

create table if not exists public.cotizador_counters (
  user_id           uuid    primary key default auth.uid() references auth.users (id) on delete cascade,
  last_quote_number integer not null default 0
);

alter table public.cotizador_counters enable row level security;

drop policy if exists "cada usuario usa solo su contador" on public.cotizador_counters;
create policy "cada usuario usa solo su contador"
  on public.cotizador_counters
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.cotizador_counters from anon;
grant select, insert, update on public.cotizador_counters to authenticated;

-- Devuelve el próximo número libre. Arranca después del número más alto que
-- ya exista en las cotizaciones guardadas, así se respetan las anteriores.
create or replace function public.cotizador_next_quote_number()
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  max_used integer;
  next_number integer;
begin
  if uid is null then
    raise exception 'Hay que iniciar sesión para pedir un número';
  end if;

  select coalesce(max((data ->> 'number')::integer), 0)
    into max_used
    from public.cotizador_items
   where user_id = uid
     and kind = 'quotes'
     and jsonb_typeof(data -> 'number') = 'number';

  insert into public.cotizador_counters as c (user_id, last_quote_number)
  values (uid, max_used + 1)
  on conflict (user_id) do update
    set last_quote_number = greatest(c.last_quote_number, max_used) + 1
  returning last_quote_number into next_number;

  return next_number;
end;
$$;

-- Devuelve un número reservado que no se usó (cotización descartada), solo si
-- sigue siendo el último que se entregó: así no quedan huecos ni se pisa nada.
create or replace function public.cotizador_release_quote_number(p_number integer)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  update public.cotizador_counters
     set last_quote_number = last_quote_number - 1
   where user_id = uid
     and last_quote_number = p_number
     and not exists (
       select 1 from public.cotizador_items
        where user_id = uid
          and kind = 'quotes'
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

-- Red de seguridad: la base rechaza dos cotizaciones con el mismo número.
create unique index if not exists cotizador_items_quote_number_unique
  on public.cotizador_items (user_id, ((data ->> 'number')::integer))
  where kind = 'quotes' and jsonb_typeof(data -> 'number') = 'number';
