create extension if not exists pgcrypto with schema extensions;

create table if not exists public.operation_audit_logs (
  id uuid primary key default gen_random_uuid(),
  fiscal_id text not null,
  area text not null,
  action text not null,
  entity_type text,
  entity_id text,
  severity text not null default 'info'
    check (severity in ('info', 'success', 'warning', 'critical')),
  title text,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists operation_audit_logs_fiscal_created_idx
  on public.operation_audit_logs (fiscal_id, created_at desc);

create index if not exists operation_audit_logs_area_idx
  on public.operation_audit_logs (fiscal_id, area, action);

alter table public.operation_audit_logs enable row level security;

drop policy if exists "operation audit select own" on public.operation_audit_logs;
create policy "operation audit select own"
  on public.operation_audit_logs
  for select
  using (fiscal_id = auth.uid()::text);

drop policy if exists "operation audit insert own" on public.operation_audit_logs;
create policy "operation audit insert own"
  on public.operation_audit_logs
  for insert
  with check (fiscal_id = auth.uid()::text);

create table if not exists public.operation_attachments (
  id uuid primary key default gen_random_uuid(),
  fiscal_id text not null,
  module text not null,
  entity_type text,
  entity_id text not null,
  file_name text not null,
  file_url text not null,
  storage_bucket text not null default 'anexos',
  storage_path text,
  content_type text,
  file_size_bytes integer,
  is_image boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists operation_attachments_entity_idx
  on public.operation_attachments (fiscal_id, module, entity_id, created_at desc);

alter table public.operation_attachments enable row level security;

drop policy if exists "operation attachments select own" on public.operation_attachments;
create policy "operation attachments select own"
  on public.operation_attachments
  for select
  using (fiscal_id = auth.uid()::text);

drop policy if exists "operation attachments insert own" on public.operation_attachments;
create policy "operation attachments insert own"
  on public.operation_attachments
  for insert
  with check (fiscal_id = auth.uid()::text);

drop policy if exists "operation attachments delete own" on public.operation_attachments;
create policy "operation attachments delete own"
  on public.operation_attachments
  for delete
  using (fiscal_id = auth.uid()::text);

create table if not exists public.operation_notification_queue (
  id uuid primary key default gen_random_uuid(),
  fiscal_id text not null,
  area text not null,
  entity_type text,
  entity_id text,
  priority text not null default 'normal'
    check (priority in ('low', 'normal', 'high', 'critical')),
  status text not null default 'pending'
    check (status in ('pending', 'delivered', 'dismissed', 'failed')),
  title text not null,
  message text not null,
  action_label text,
  action_payload jsonb not null default '{}'::jsonb,
  scheduled_for timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists operation_notification_queue_pending_idx
  on public.operation_notification_queue (fiscal_id, status, priority, created_at desc);

alter table public.operation_notification_queue enable row level security;

drop policy if exists "operation notification select own" on public.operation_notification_queue;
create policy "operation notification select own"
  on public.operation_notification_queue
  for select
  using (fiscal_id = auth.uid()::text);

drop policy if exists "operation notification insert own" on public.operation_notification_queue;
create policy "operation notification insert own"
  on public.operation_notification_queue
  for insert
  with check (fiscal_id = auth.uid()::text);

drop policy if exists "operation notification update own" on public.operation_notification_queue;
create policy "operation notification update own"
  on public.operation_notification_queue
  for update
  using (fiscal_id = auth.uid()::text)
  with check (fiscal_id = auth.uid()::text);

create table if not exists public.operation_sla_rules (
  id uuid primary key default gen_random_uuid(),
  fiscal_id text not null,
  area text not null,
  trigger_key text not null,
  title text not null,
  max_minutes integer not null,
  severity text not null default 'warning'
    check (severity in ('info', 'warning', 'critical')),
  enabled boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (fiscal_id, area, trigger_key)
);

alter table public.operation_sla_rules enable row level security;

drop policy if exists "operation sla select own" on public.operation_sla_rules;
create policy "operation sla select own"
  on public.operation_sla_rules
  for select
  using (fiscal_id = auth.uid()::text);

drop policy if exists "operation sla manage own" on public.operation_sla_rules;
create policy "operation sla manage own"
  on public.operation_sla_rules
  for all
  using (fiscal_id = auth.uid()::text)
  with check (fiscal_id = auth.uid()::text);

create table if not exists public.operation_media_insights (
  id uuid primary key default gen_random_uuid(),
  fiscal_id text not null,
  source text not null default 'manual_upload',
  source_id text,
  media_type text not null check (media_type in ('text', 'image', 'audio', 'document')),
  file_url text,
  transcript_text text,
  vision_summary text,
  extracted_entities jsonb not null default '{}'::jsonb,
  linked_area text,
  linked_entity_id text,
  confidence numeric(5, 4),
  status text not null default 'pending'
    check (status in ('pending', 'analyzed', 'linked', 'ignored', 'failed')),
  created_at timestamptz not null default now(),
  analyzed_at timestamptz
);

create index if not exists operation_media_insights_fiscal_idx
  on public.operation_media_insights (fiscal_id, status, created_at desc);

alter table public.operation_media_insights enable row level security;

drop policy if exists "operation media select own" on public.operation_media_insights;
create policy "operation media select own"
  on public.operation_media_insights
  for select
  using (fiscal_id = auth.uid()::text);

drop policy if exists "operation media insert own" on public.operation_media_insights;
create policy "operation media insert own"
  on public.operation_media_insights
  for insert
  with check (fiscal_id = auth.uid()::text);

drop policy if exists "operation media update own" on public.operation_media_insights;
create policy "operation media update own"
  on public.operation_media_insights
  for update
  using (fiscal_id = auth.uid()::text)
  with check (fiscal_id = auth.uid()::text);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'anexos',
  'anexos',
  true,
  52428800,
  array[
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/octet-stream'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "operation anexos read own" on storage.objects;
create policy "operation anexos read own"
  on storage.objects
  for select
  using (
    bucket_id = 'anexos'
    and auth.uid()::text = split_part(name, '/', 1)
  );

drop policy if exists "operation anexos insert own" on storage.objects;
create policy "operation anexos insert own"
  on storage.objects
  for insert
  with check (
    bucket_id = 'anexos'
    and auth.uid()::text = split_part(name, '/', 1)
  );

drop policy if exists "operation anexos update own" on storage.objects;
create policy "operation anexos update own"
  on storage.objects
  for update
  using (
    bucket_id = 'anexos'
    and auth.uid()::text = split_part(name, '/', 1)
  )
  with check (
    bucket_id = 'anexos'
    and auth.uid()::text = split_part(name, '/', 1)
  );
