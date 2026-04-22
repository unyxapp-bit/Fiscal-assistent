-- ─────────────────────────────────────────────────────────────────
--  Fase 2 — Novos campos em fiscal_events + tabelas auxiliares
--  Todas as colunas são NULLABLE ou têm default → não quebra dados existentes
-- ─────────────────────────────────────────────────────────────────

-- 1. Novas colunas em fiscal_events
alter table public.fiscal_events
  add column if not exists resolved_at    timestamptz,
  add column if not exists resolved_by    text,
  add column if not exists notes          text,
  add column if not exists caixa_numero   int,
  add column if not exists scheduled_time time,
  add column if not exists turno          text
    check (turno in ('manha', 'tarde', 'noite')),
  add column if not exists source         text not null default 'whatsapp'
    check (source in ('whatsapp', 'manual', 'sistema')),
  add column if not exists priority       text not null default 'normal'
    check (priority in ('baixa', 'normal', 'alta', 'critica'));

-- Índice para buscar eventos de alta prioridade rapidamente
create index if not exists idx_fiscal_events_priority
  on public.fiscal_events(priority)
  where priority in ('alta', 'critica');

-- 2. Histórico de edições (audit log)
create table if not exists public.fiscal_event_history (
  id           bigserial primary key,
  event_id     int not null references public.fiscal_events(id) on delete cascade,
  campo        text not null,
  valor_antes  text,
  valor_depois text,
  editado_em   timestamptz not null default now(),
  editado_por  text
);

create index if not exists idx_fiscal_event_history_event
  on public.fiscal_event_history(event_id);

-- 3. Tabela de correções para retroalimentar as regras
create table if not exists public.fiscal_corrections (
  id               bigserial primary key,
  raw_message      text not null,
  categoria_errada text,
  categoria_certa  text not null,
  corrigido_em     timestamptz not null default now()
);
