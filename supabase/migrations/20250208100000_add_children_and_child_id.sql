-- Children profiles: name, date of birth, optional Immich album id
create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  date_of_birth date,
  immich_album_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_user_id_idx on public.children (user_id);

alter table public.children enable row level security;

create policy "Users can manage own children"
  on public.children
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create trigger children_updated_at
  before update on public.children
  for each row execute function public.set_updated_at();

-- Link journal entry to a child (optional)
alter table public.journal_entries
  add column if not exists child_id uuid references public.children(id) on delete set null;

create index if not exists journal_entries_child_id_idx on public.journal_entries (child_id);
