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

-- Los usuarios anónimos no tienen ningún permiso sobre la tabla.
revoke all on public.cotizador_items from anon;
grant select, insert, update, delete on public.cotizador_items to authenticated;
