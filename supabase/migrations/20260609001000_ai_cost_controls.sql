create extension if not exists pgcrypto with schema extensions;

create table if not exists public.ai_usage_logs (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid,
  function_name text not null,
  intent text,
  provider text,
  model text,
  source text,
  status text not null default 'unknown',
  cache_status text,
  request_hash text,
  prompt_tokens integer,
  completion_tokens integer,
  total_tokens integer,
  cached_tokens integer,
  latency_ms integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ai_usage_logs_fiscal_created_idx
  on public.ai_usage_logs (fiscal_id, created_at desc);

create index if not exists ai_usage_logs_function_created_idx
  on public.ai_usage_logs (function_name, created_at desc);

create index if not exists ai_usage_logs_request_hash_idx
  on public.ai_usage_logs (request_hash, created_at desc);

alter table public.ai_usage_logs enable row level security;

drop policy if exists "AI usage logs select own" on public.ai_usage_logs;
create policy "AI usage logs select own"
  on public.ai_usage_logs
  for select
  using (fiscal_id = auth.uid());

create table if not exists public.ai_request_cache (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid,
  function_name text not null,
  request_hash text not null,
  result jsonb not null,
  provider text,
  model text,
  source text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (function_name, request_hash)
);

create index if not exists ai_request_cache_fiscal_idx
  on public.ai_request_cache (fiscal_id, function_name, expires_at desc);

create index if not exists ai_request_cache_expires_idx
  on public.ai_request_cache (expires_at);

alter table public.ai_request_cache enable row level security;

drop policy if exists "AI request cache select own" on public.ai_request_cache;
create policy "AI request cache select own"
  on public.ai_request_cache
  for select
  using (fiscal_id = auth.uid());

create table if not exists public.ai_provider_health (
  provider text primary key,
  status text not null default 'healthy'
    check (status in ('healthy', 'degraded', 'cooldown')),
  failure_count integer not null default 0,
  last_error text,
  cooldown_until timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.ai_provider_health enable row level security;

drop policy if exists "AI provider health readable" on public.ai_provider_health;
create policy "AI provider health readable"
  on public.ai_provider_health
  for select
  using (true);

create table if not exists public.ai_budget_policies (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid unique,
  mode text not null default 'economico'
    check (mode in ('economico', 'equilibrado', 'completo')),
  daily_request_limit integer not null default 80,
  daily_token_limit integer not null default 250000,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.ai_budget_policies enable row level security;

drop policy if exists "AI budget policies select own or default" on public.ai_budget_policies;
create policy "AI budget policies select own or default"
  on public.ai_budget_policies
  for select
  using (
    fiscal_id = auth.uid()
    or fiscal_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

create table if not exists public.ai_context_summaries (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid not null,
  summary_date date not null default current_date,
  context_hash text not null,
  summary jsonb not null default '{}'::jsonb,
  source_snapshot_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (fiscal_id, summary_date)
);

create index if not exists ai_context_summaries_fiscal_date_idx
  on public.ai_context_summaries (fiscal_id, summary_date desc);

alter table public.ai_context_summaries enable row level security;

drop policy if exists "AI context summaries owner scoped" on public.ai_context_summaries;
create policy "AI context summaries owner scoped"
  on public.ai_context_summaries
  for all
  using (fiscal_id = auth.uid())
  with check (fiscal_id = auth.uid());

insert into public.ai_budget_policies (
  fiscal_id,
  mode,
  daily_request_limit,
  daily_token_limit,
  enabled
)
values (
  '00000000-0000-0000-0000-000000000000'::uuid,
  'economico',
  80,
  250000,
  true
)
on conflict (fiscal_id) do nothing;
