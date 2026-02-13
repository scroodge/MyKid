-- Base schema required for later migrations (children, set_updated_at).
-- Full schema is in docs/full_schema.sql for one-off apply; this allows local supabase start.

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  text text not null default '',
  assets jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists journal_entries_user_id_idx on public.journal_entries (user_id);
alter table public.journal_entries enable row level security;
create policy "Users can manage own journal entries"
  on public.journal_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create trigger journal_entries_updated_at
  before update on public.journal_entries for each row execute function public.set_updated_at();

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  date_of_birth date,
  immich_album_id uuid,
  immich_person_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists children_user_id_idx on public.children (user_id);
alter table public.children enable row level security;
create policy "Users can manage own children"
  on public.children for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create trigger children_updated_at
  before update on public.children for each row execute function public.set_updated_at();

alter table public.journal_entries
  add column if not exists child_id uuid references public.children(id) on delete set null;
create index if not exists journal_entries_child_id_idx on public.journal_entries (child_id);

-- Households (required by 20250210000000 set_household_immich_config_for_managed)
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (household_id, user_id)
);
alter table public.households enable row level security;
alter table public.household_members enable row level security;
create policy "Allow all households for local dev" on public.households for all using (true) with check (true);
create policy "Allow all household_members for local dev" on public.household_members for all using (true) with check (true);

create table if not exists public.household_settings (
  household_id uuid primary key references public.households(id) on delete cascade,
  immich_server_url text,
  immich_vault_secret_id uuid,
  updated_at timestamptz not null default now()
);
alter table public.household_settings enable row level security;
create policy "Allow all household_settings for local dev" on public.household_settings for all using (true) with check (true);
