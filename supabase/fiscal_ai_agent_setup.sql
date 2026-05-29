-- Fiscal AI agent persistence.
-- Run this in the Supabase SQL editor before using the Fiscal AI screen.

create extension if not exists pgcrypto;

create table if not exists public.fiscal_ai_snapshots (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid not null,
  intent text not null default 'analyze',
  question text,
  target jsonb,
  context_snapshot jsonb not null default '{}'::jsonb,
  result jsonb not null,
  provider text,
  model text,
  action_tool text,
  action_status text,
  created_at timestamptz not null default now()
);

create table if not exists public.fiscal_ai_actions (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid not null,
  snapshot_id uuid references public.fiscal_ai_snapshots(id) on delete set null,
  intent text not null default 'analyze',
  source text not null default 'agent',
  status text not null default 'suggested',
  mode text not null default 'suggest',
  tool_name text,
  title text not null,
  description text not null,
  reason text,
  confidence numeric not null default 0.7,
  confirmation_required boolean not null default false,
  arguments jsonb not null default '{}'::jsonb,
  target jsonb,
  context_snapshot jsonb not null default '{}'::jsonb,
  action_result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  approved_at timestamptz,
  approved_by uuid,
  resolved_by uuid
);

create index if not exists fiscal_ai_snapshots_fiscal_created_idx
  on public.fiscal_ai_snapshots (fiscal_id, created_at desc);

create index if not exists fiscal_ai_actions_fiscal_status_created_idx
  on public.fiscal_ai_actions (fiscal_id, status, created_at desc);

alter table public.fiscal_ai_snapshots enable row level security;
alter table public.fiscal_ai_actions enable row level security;

drop policy if exists "Fiscal AI snapshots are owner scoped" on public.fiscal_ai_snapshots;
create policy "Fiscal AI snapshots are owner scoped"
  on public.fiscal_ai_snapshots
  for all
  using (auth.uid() = fiscal_id)
  with check (auth.uid() = fiscal_id);

drop policy if exists "Fiscal AI actions are owner scoped" on public.fiscal_ai_actions;
create policy "Fiscal AI actions are owner scoped"
  on public.fiscal_ai_actions
  for all
  using (auth.uid() = fiscal_id)
  with check (auth.uid() = fiscal_id);
