-- Tabela principal de eventos capturados do WhatsApp
-- Execute no SQL Editor do Supabase

create table if not exists fiscal_events (
  id            bigint generated always as identity primary key,
  category      text not null,              -- caixa | ausencia | atestado | horario_especial | ferias | vale | problema_operacional | aviso_geral | midia_pendente
  description   text not null,
  employee_name text,
  amount        numeric(10, 2),
  sender        text,                       -- nome de quem enviou no WhatsApp
  raw_message   text,
  event_date    timestamptz,
  status        text default 'pending',     -- pending | resolved | ignored
  confidence    numeric(3, 2),
  media_type    text,                       -- 'audio' | 'foto' | null
  needs_review  boolean default false,      -- true = aguardando preenchimento manual
  created_at    timestamptz default now()
);

-- Índices
create index if not exists idx_fiscal_events_category     on fiscal_events(category);
create index if not exists idx_fiscal_events_status       on fiscal_events(status);
create index if not exists idx_fiscal_events_event_date   on fiscal_events(event_date desc);
create index if not exists idx_fiscal_events_employee     on fiscal_events(employee_name);
create index if not exists idx_fiscal_events_needs_review on fiscal_events(needs_review);

-- RLS
alter table fiscal_events enable row level security;

-- SELECT: qualquer usuário autenticado pode ler
create policy "Autenticados leem fiscal_events"
  on fiscal_events for select
  using (auth.role() = 'authenticated');

-- INSERT: qualquer usuário autenticado pode inserir
-- (usado pelo app para salvar mídias diretamente)
create policy "Autenticados inserem fiscal_events"
  on fiscal_events for insert
  with check (auth.role() = 'authenticated');

-- UPDATE: qualquer usuário autenticado pode atualizar
-- (usado para marcar status: resolved / ignored e preencher mídias)
create policy "Autenticados atualizam fiscal_events"
  on fiscal_events for update
  using (auth.role() = 'authenticated');

-- DELETE: qualquer usuário autenticado pode excluir
create policy "Autenticados excluem fiscal_events"
  on fiscal_events for delete
  using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────────────────────────────────────
-- Se a tabela já existir, rode apenas os blocos abaixo:
-- ─────────────────────────────────────────────────────────────────────────────

-- alter table fiscal_events add column if not exists media_type   text;
-- alter table fiscal_events add column if not exists needs_review boolean default false;

-- Policies adicionais (caso só o SELECT já exista):
-- create policy "Autenticados inserem fiscal_events"  on fiscal_events for insert  with check (auth.role() = 'authenticated');
-- create policy "Autenticados atualizam fiscal_events" on fiscal_events for update  using (auth.role() = 'authenticated');
-- create policy "Autenticados excluem fiscal_events"  on fiscal_events for delete  using (auth.role() = 'authenticated');
