-- Households (family) and members. Enables shared access and household-level Immich.
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists households_owner_id_idx on public.households (owner_id);

create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create index if not exists household_members_household_id_idx on public.household_members (household_id);
create index if not exists household_members_user_id_idx on public.household_members (user_id);

alter table public.households enable row level security;
alter table public.household_members enable row level security;

-- Helper function to check if user is member of a household (bypasses RLS).
-- Must be created BEFORE policies that use it.
create or replace function public.is_household_member(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid()
  );
$$ language sql stable security definer set search_path = public;

-- Helper function to check if user is owner of a household (bypasses RLS).
create or replace function public.is_household_owner(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.household_members
    where household_id = p_household_id and user_id = auth.uid() and role = 'owner'
  );
$$ language sql stable security definer set search_path = public;

-- Only members can read/update household (name). Only owner can delete (optional: add policy later).
create policy "Members can read household"
  on public.households for select
  using (public.is_household_member(households.id));

create policy "Members can update household"
  on public.households for update
  using (public.is_household_member(households.id))
  with check (true);

create policy "Authenticated can insert household"
  on public.households for insert to authenticated
  with check (owner_id = auth.uid());

-- Members: members can read; only owner can insert/delete (invite/remove). Users can delete own membership (leave).
-- Use SECURITY DEFINER function to avoid infinite recursion.
create policy "Members can read household_members"
  on public.household_members for select
  using (public.is_household_member(household_members.household_id));

-- Allow: (1) household owner adding themselves as first member, (2) existing owner member adding others
create policy "Owner or household owner can insert household_members"
  on public.household_members for insert to authenticated
  with check (
    (user_id = auth.uid() and exists (
      select 1 from public.households h where h.id = household_members.household_id and h.owner_id = auth.uid()
    ))
    or public.is_household_owner(household_members.household_id)
  );

create policy "Owner or self can delete household_members"
  on public.household_members for delete
  using (
    user_id = auth.uid()
    or public.is_household_owner(household_members.household_id)
  );

-- Trigger updated_at for households
create trigger households_updated_at
  before update on public.households
  for each row execute function public.set_updated_at();

-- Returns array of household ids the current user is a member of (for RLS and app).
-- SECURITY DEFINER allows this function to bypass RLS when checking membership.
create or replace function public.user_household_ids()
returns uuid[] as $$
  select array_agg(household_id) from public.household_members where user_id = auth.uid();
$$ language sql stable security definer set search_path = public;
