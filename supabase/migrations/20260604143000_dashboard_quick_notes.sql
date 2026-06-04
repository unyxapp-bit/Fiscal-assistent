create table if not exists public.dashboard_quick_notes (
  id uuid primary key default gen_random_uuid(),
  fiscal_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (
    char_length(trim(content)) > 0
    and char_length(content) <= 1000
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists dashboard_quick_notes_fiscal_created_idx
  on public.dashboard_quick_notes (fiscal_id, created_at desc);

alter table public.dashboard_quick_notes enable row level security;

drop policy if exists "dashboard quick notes select own" on public.dashboard_quick_notes;
create policy "dashboard quick notes select own"
  on public.dashboard_quick_notes
  for select
  using (auth.uid() = fiscal_id);

drop policy if exists "dashboard quick notes insert own" on public.dashboard_quick_notes;
create policy "dashboard quick notes insert own"
  on public.dashboard_quick_notes
  for insert
  with check (auth.uid() = fiscal_id);

drop policy if exists "dashboard quick notes update own" on public.dashboard_quick_notes;
create policy "dashboard quick notes update own"
  on public.dashboard_quick_notes
  for update
  using (auth.uid() = fiscal_id)
  with check (auth.uid() = fiscal_id);

drop policy if exists "dashboard quick notes delete own" on public.dashboard_quick_notes;
create policy "dashboard quick notes delete own"
  on public.dashboard_quick_notes
  for delete
  using (auth.uid() = fiscal_id);

create or replace function public.set_dashboard_quick_notes_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists dashboard_quick_notes_set_updated_at
  on public.dashboard_quick_notes;

create trigger dashboard_quick_notes_set_updated_at
  before update on public.dashboard_quick_notes
  for each row
  execute function public.set_dashboard_quick_notes_updated_at();
