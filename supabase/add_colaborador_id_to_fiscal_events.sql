-- Migration: vincula fiscal_events com colaboradores
-- Execute no Supabase SQL Editor

alter table public.fiscal_events
  add column if not exists colaborador_id uuid
    references public.colaboradores(id)
    on delete set null;

create index if not exists idx_fiscal_events_colaborador_id
  on public.fiscal_events(colaborador_id);

comment on column public.fiscal_events.colaborador_id is
  'FK para colaboradores.id — vincula o evento ao colaborador identificado (manual ou automático)';
