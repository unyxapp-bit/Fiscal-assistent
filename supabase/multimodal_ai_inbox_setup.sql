-- Multimodal AI inbox for Balcao Fiscal.
-- Idempotent: safe to run more than once with the Supabase CLI.

create extension if not exists pgcrypto;

alter table public.fiscal_events
  add column if not exists fiscal_id uuid references auth.users(id) on delete set null,
  add column if not exists ai_inbox_item_id uuid,
  add column if not exists content_hash text,
  add column if not exists source_title text,
  add column if not exists raw_title text,
  add column if not exists raw_content text,
  add column if not exists media_storage_bucket text,
  add column if not exists media_storage_path text,
  add column if not exists media_public_url text,
  add column if not exists media_file_name text,
  add column if not exists media_content_type text,
  add column if not exists media_transcript text,
  add column if not exists media_summary text,
  add column if not exists media_analysis jsonb not null default '{}'::jsonb,
  add column if not exists analysis_provider text,
  add column if not exists analysis_model text,
  add column if not exists analysis_status text not null default 'analyzed',
  add column if not exists analysis_error text,
  add column if not exists analyzed_at timestamptz;

create index if not exists idx_fiscal_events_fiscal_event_date
  on public.fiscal_events(fiscal_id, event_date desc);

create index if not exists idx_fiscal_events_ai_inbox_item_id
  on public.fiscal_events(ai_inbox_item_id);

create unique index if not exists idx_fiscal_events_content_hash
  on public.fiscal_events(fiscal_id, content_hash)
  where fiscal_id is not null and content_hash is not null;

create table if not exists public.ai_inbox_items (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid references auth.users(id) on delete set null,
  source text not null default 'manual_upload',
  source_app text,
  source_title text,
  sender text,
  raw_text text,
  raw_title text,
  raw_content text,
  content_type text not null default 'text',
  media_type text,
  storage_bucket text not null default 'fiscal-media',
  storage_path text,
  file_name text,
  mime_type text,
  size_bytes bigint,
  content_hash text,
  event_date timestamptz not null default now(),
  analysis_status text not null default 'pending',
  analysis_provider text,
  analysis_model text,
  transcript text,
  image_text text,
  summary text,
  structured_result jsonb not null default '{}'::jsonb,
  fiscal_event_id bigint references public.fiscal_events(id) on delete set null,
  skipped_reason text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ai_inbox_content_type_check
    check (content_type in ('text', 'audio', 'image', 'document', 'video', 'unknown')),
  constraint ai_inbox_analysis_status_check
    check (analysis_status in ('pending', 'processing', 'analyzed', 'skipped', 'needs_review', 'needs_file', 'error'))
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'fiscal_events_ai_inbox_item_fk'
      and conrelid = 'public.fiscal_events'::regclass
  ) then
    alter table public.fiscal_events
      add constraint fiscal_events_ai_inbox_item_fk
      foreign key (ai_inbox_item_id)
      references public.ai_inbox_items(id)
      on delete set null;
  end if;
end $$;

create index if not exists idx_ai_inbox_items_fiscal_created
  on public.ai_inbox_items(fiscal_id, created_at desc);

create index if not exists idx_ai_inbox_items_status
  on public.ai_inbox_items(analysis_status, created_at desc);

create unique index if not exists idx_ai_inbox_items_fiscal_hash
  on public.ai_inbox_items(fiscal_id, content_hash)
  where fiscal_id is not null and content_hash is not null;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_ai_inbox_items_updated_at on public.ai_inbox_items;
create trigger set_ai_inbox_items_updated_at
  before update on public.ai_inbox_items
  for each row
  execute function public.set_updated_at();

alter table public.ai_inbox_items enable row level security;

drop policy if exists "AI inbox select own items" on public.ai_inbox_items;
create policy "AI inbox select own items"
  on public.ai_inbox_items
  for select
  using (auth.uid() = fiscal_id or fiscal_id is null);

drop policy if exists "AI inbox insert own items" on public.ai_inbox_items;
create policy "AI inbox insert own items"
  on public.ai_inbox_items
  for insert
  with check (auth.uid() = fiscal_id or fiscal_id is null);

drop policy if exists "AI inbox update own items" on public.ai_inbox_items;
create policy "AI inbox update own items"
  on public.ai_inbox_items
  for update
  using (auth.uid() = fiscal_id or fiscal_id is null)
  with check (auth.uid() = fiscal_id or fiscal_id is null);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'fiscal-media',
  'fiscal-media',
  false,
  52428800,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'audio/mpeg',
    'audio/mp3',
    'audio/mp4',
    'audio/mpga',
    'audio/m4a',
    'audio/wav',
    'audio/webm',
    'audio/ogg',
    'audio/opus',
    'video/mp4',
    'application/pdf',
    'text/plain'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Fiscal media select own files" on storage.objects;
create policy "Fiscal media select own files"
  on storage.objects
  for select
  using (
    bucket_id = 'fiscal-media'
    and auth.uid()::text = split_part(name, '/', 1)
  );

drop policy if exists "Fiscal media insert own files" on storage.objects;
create policy "Fiscal media insert own files"
  on storage.objects
  for insert
  with check (
    bucket_id = 'fiscal-media'
    and auth.uid()::text = split_part(name, '/', 1)
  );

drop policy if exists "Fiscal media update own files" on storage.objects;
create policy "Fiscal media update own files"
  on storage.objects
  for update
  using (
    bucket_id = 'fiscal-media'
    and auth.uid()::text = split_part(name, '/', 1)
  )
  with check (
    bucket_id = 'fiscal-media'
    and auth.uid()::text = split_part(name, '/', 1)
  );

drop policy if exists "Fiscal media delete own files" on storage.objects;
create policy "Fiscal media delete own files"
  on storage.objects
  for delete
  using (
    bucket_id = 'fiscal-media'
    and auth.uid()::text = split_part(name, '/', 1)
  );
