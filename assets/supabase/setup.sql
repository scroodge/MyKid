-- From 20250208000000_create_journal_entries.sql
-- Journal entries: id, user_id, date, text, assets (JSONB), created_at, updated_at
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
create index if not exists journal_entries_user_id_date_idx on public.journal_entries (user_id, date desc);

alter table public.journal_entries enable row level security;

create policy "Users can manage own journal entries"
  on public.journal_entries
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Keep updated_at in sync
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger journal_entries_updated_at
  before update on public.journal_entries
  for each row execute function public.set_updated_at();


-- From 20250208100000_add_children_and_child_id.sql
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


-- From 20250208100001_storage_avatars_bucket.sql
-- Avatars bucket for profile photos. Public so getPublicUrl() works without signed URLs.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

-- RLS: authenticated users can upload only to their own folder (path = auth.uid()/...)
create policy "Users can upload own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.jwt()->>'sub')
);

-- RLS: users can update/overwrite their own file (upsert). owner_id in storage.objects is text.
create policy "Users can update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
)
with check (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
);

-- RLS: users can select (read) their own objects; public bucket also allows anon read
create policy "Users can read own avatar"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
);

-- Allow public read for avatars bucket (so profile photos load without auth in URLs)
create policy "Public read avatars"
on storage.objects
for select
to public
using (bucket_id = 'avatars');


-- From 20250208100002_children_avatar_url.sql
-- Child profile avatar URL (Supabase Storage public URL)
alter table public.children
  add column if not exists avatar_url text;

-- RLS: allow upload to path children/{user_id}/{child_id}/avatar.jpg (child avatars in same bucket)
create policy "Users can upload child avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = 'children'
  and (storage.foldername(name))[2] = (select auth.jwt()->>'sub')
);


-- From 20250208200000_add_journal_entry_location.sql
-- Optional location (e.g. from photo EXIF: city, country)
alter table public.journal_entries
  add column if not exists location text;


-- From 20250208300000_households_and_members.sql
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


-- From 20250208300001_household_settings_immich_vault.sql
-- Household-level Immich settings. API key stored in Supabase Vault (encrypted).
-- Requires Supabase Vault extension (enabled by default on Supabase Cloud).

create table if not exists public.household_settings (
  household_id uuid primary key references public.households(id) on delete cascade,
  immich_server_url text,
  immich_vault_secret_id uuid,
  updated_at timestamptz not null default now()
);

create trigger household_settings_updated_at
  before update on public.household_settings
  for each row execute function public.set_updated_at();

alter table public.household_settings enable row level security;

create policy "Members can read household_settings"
  on public.household_settings for select
  using (public.is_household_member(household_settings.household_id));

create policy "Members can insert household_settings"
  on public.household_settings for insert to authenticated
  with check (public.is_household_member(household_settings.household_id));

create policy "Members can update household_settings"
  on public.household_settings for update
  using (public.is_household_member(household_settings.household_id))
  with check (true);

-- Returns Immich server_url and api_key for a household. Only callable by members.
-- SECURITY DEFINER so we can read vault.decrypted_secrets (run as migration owner).
create or replace function public.get_household_immich_config(p_household_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_url text;
  v_secret_id uuid;
  v_api_key text;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Not a member of this household';
  end if;

  select immich_server_url, immich_vault_secret_id
  into v_url, v_secret_id
  from public.household_settings
  where household_id = p_household_id;

  if v_url is null or v_secret_id is null then
    return jsonb_build_object('server_url', null, 'api_key', null);
  end if;

  select decrypted_secret into v_api_key
  from vault.decrypted_secrets
  where id = v_secret_id;

  return jsonb_build_object('server_url', v_url, 'api_key', v_api_key);
end;
$$;

comment on function public.get_household_immich_config(uuid) is
  'Returns Immich server_url and api_key for household. Call only after user consent.';

-- Saves Immich URL and API key for household. API key is stored in Vault.
create or replace function public.set_household_immich_config(
  p_household_id uuid,
  p_server_url text,
  p_api_key text
)
returns void
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_secret_id uuid;
  v_name text;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Not a member of this household';
  end if;

  v_name := 'immich_apikey_' || p_household_id::text;

  insert into public.household_settings (household_id, immich_server_url, immich_vault_secret_id)
  values (p_household_id, nullif(trim(p_server_url), ''), null)
  on conflict (household_id) do update set
    immich_server_url = nullif(trim(p_server_url), ''),
    updated_at = now();

  if nullif(trim(p_api_key), '') is not null then
    select immich_vault_secret_id into v_secret_id
    from public.household_settings where household_id = p_household_id;

    if v_secret_id is not null then
      perform vault.update_secret(v_secret_id, p_api_key, v_name, 'Immich API key for household');
    else
      v_secret_id := vault.create_secret(p_api_key, v_name, 'Immich API key for household');
      update public.household_settings
      set immich_vault_secret_id = v_secret_id, updated_at = now()
      where household_id = p_household_id;
    end if;
  end if;
end;
$$;

comment on function public.set_household_immich_config(uuid, text, text) is
  'Saves Immich URL and API key for household. API key stored in Vault. Requires member consent.';

grant execute on function public.get_household_immich_config(uuid) to authenticated;
grant execute on function public.set_household_immich_config(uuid, text, text) to authenticated;


-- From 20250208300002_household_invites.sql
-- Household invites: email-based invitations with token and expiration.
create table if not exists public.household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  email text not null,
  invited_by uuid not null references auth.users(id) on delete cascade,
  token uuid not null unique default gen_random_uuid(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now()
);

create index if not exists household_invites_household_id_idx on public.household_invites (household_id);
create index if not exists household_invites_token_idx on public.household_invites (token);
create index if not exists household_invites_email_idx on public.household_invites (email);

alter table public.household_invites enable row level security;

-- Members can read invites for their household (to see pending invites).
create policy "Members can read household_invites"
  on public.household_invites for select
  using (public.is_household_member(household_invites.household_id));

-- Any authenticated user can read invite by token (for accept screen).
create policy "Authenticated can read invite by token"
  on public.household_invites for select to authenticated
  using (true);

-- Members can create invites for their household.
create policy "Members can create household_invites"
  on public.household_invites for insert to authenticated
  with check (
    public.is_household_member(household_invites.household_id)
    and invited_by = auth.uid()
  );

-- Owner can delete invites (cancel invitation).
create policy "Owner can delete household_invites"
  on public.household_invites for delete
  using (public.is_household_owner(household_invites.household_id));

-- RPC: accept invite by token. Checks email match (optional), expiration, adds to household_members, deletes invite.
create or replace function public.accept_household_invite(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
  v_household_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_invite
  from public.household_invites
  where token = p_token and expires_at > now();

  if not found then
    return jsonb_build_object('success', false, 'error', 'Invite not found or expired');
  end if;

  -- Check if user is already a member (using function to avoid RLS recursion)
  if public.is_household_member(v_invite.household_id) then
    return jsonb_build_object('success', false, 'error', 'Already a member');
  end if;

  -- Add user to household_members
  insert into public.household_members (household_id, user_id, role)
  values (v_invite.household_id, v_user_id, 'member')
  on conflict (household_id, user_id) do nothing;

  -- Delete the invite
  delete from public.household_invites where id = v_invite.id;

  return jsonb_build_object('success', true, 'household_id', v_invite.household_id);
end;
$$;

comment on function public.accept_household_invite(uuid) is
  'Accepts a household invite by token. Adds user to household_members and deletes the invite.';

grant execute on function public.accept_household_invite(uuid) to authenticated;


-- From 20250208300003_fix_rls_recursion.sql
-- Fix infinite recursion in RLS policies by using SECURITY DEFINER helper functions.
-- This migration fixes policies that were causing recursion by querying household_members
-- from within policies that protect household_members itself.

-- Helper function to check if user is member of a household (bypasses RLS).
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

-- Drop and recreate policies for households to use helper functions.
drop policy if exists "Members can read household" on public.households;
drop policy if exists "Members can update household" on public.households;
drop policy if exists "Authenticated can insert household" on public.households;

create policy "Members can read household"
  on public.households for select
  using (public.is_household_member(households.id));

create policy "Members can update household"
  on public.households for update
  using (public.is_household_member(households.id))
  with check (true);

-- Allow authenticated users to create households (they become owner).
create policy "Authenticated can insert household"
  on public.households for insert to authenticated
  with check (owner_id = auth.uid());

-- Drop and recreate policies for household_members to use helper functions.
drop policy if exists "Members can read household_members" on public.household_members;
drop policy if exists "Owner or household owner can insert household_members" on public.household_members;
drop policy if exists "Owner or self can delete household_members" on public.household_members;

create policy "Members can read household_members"
  on public.household_members for select
  using (public.is_household_member(household_members.household_id));

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

-- Drop and recreate policies for household_settings to use helper functions.
drop policy if exists "Members can read household_settings" on public.household_settings;
drop policy if exists "Members can insert household_settings" on public.household_settings;
drop policy if exists "Members can update household_settings" on public.household_settings;

create policy "Members can read household_settings"
  on public.household_settings for select
  using (public.is_household_member(household_settings.household_id));

create policy "Members can insert household_settings"
  on public.household_settings for insert to authenticated
  with check (public.is_household_member(household_settings.household_id));

create policy "Members can update household_settings"
  on public.household_settings for update
  using (public.is_household_member(household_settings.household_id))
  with check (true);

-- Drop and recreate policies for household_invites to use helper functions.
drop policy if exists "Members can read household_invites" on public.household_invites;
drop policy if exists "Members can create household_invites" on public.household_invites;
drop policy if exists "Owner can delete household_invites" on public.household_invites;

create policy "Members can read household_invites"
  on public.household_invites for select
  using (public.is_household_member(household_invites.household_id));

create policy "Members can create household_invites"
  on public.household_invites for insert to authenticated
  with check (
    public.is_household_member(household_invites.household_id)
    and invited_by = auth.uid()
  );

create policy "Owner can delete household_invites"
  on public.household_invites for delete
  using (public.is_household_owner(household_invites.household_id));

-- Update RPC functions to use helper functions.
create or replace function public.accept_household_invite(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
  v_household_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_invite
  from public.household_invites
  where token = p_token and expires_at > now();

  if not found then
    return jsonb_build_object('success', false, 'error', 'Invite not found or expired');
  end if;

  -- Check if user is already a member (using function to avoid RLS recursion)
  if public.is_household_member(v_invite.household_id) then
    return jsonb_build_object('success', false, 'error', 'Already a member');
  end if;

  -- Add user to household_members
  insert into public.household_members (household_id, user_id, role)
  values (v_invite.household_id, v_user_id, 'member')
  on conflict (household_id, user_id) do nothing;

  -- Delete the invite
  delete from public.household_invites where id = v_invite.id;

  return jsonb_build_object('success', true, 'household_id', v_invite.household_id);
end;
$$;


-- From 20250208300004_fix_household_insert_policy.sql
-- Fix household INSERT policy - ensure it works correctly.
-- This migration ensures the INSERT policy for households is properly configured.

-- Drop existing INSERT policy if it exists
drop policy if exists "Authenticated can insert household" on public.households;

-- Create a more explicit INSERT policy
-- For INSERT, we only need WITH CHECK (not USING)
create policy "Authenticated can insert household"
  on public.households
  for insert
  to authenticated
  with check (
    owner_id = auth.uid()
  );

-- From 20250208300005_create_household_function.sql
-- Create a SECURITY DEFINER function to create household, bypassing RLS.
-- This ensures household creation always works for authenticated users.

create or replace function public.create_household(p_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_household_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Create household
  insert into public.households (owner_id, name)
  values (v_user_id, p_name)
  returning id into v_household_id;

  -- Add user as owner member
  insert into public.household_members (household_id, user_id, role)
  values (v_household_id, v_user_id, 'owner')
  on conflict (household_id, user_id) do nothing;

  return v_household_id;
end;
$$;

comment on function public.create_household(text) is
  'Creates a new household with current user as owner and first member. Bypasses RLS.';

grant execute on function public.create_household(text) to authenticated;


-- From 20250209300000_get_invite_by_code.sql
-- Policy that allows anyone (including anonymous) to read invite by token.
-- This is needed so users can see invite details before signing up/login.
-- The policy allows reading any invite, but users still need to be authenticated to accept it.
drop policy if exists "Authenticated can read invite by token" on public.household_invites;
drop policy if exists "Anyone can read invite by token" on public.household_invites;
create policy "Anyone can read invite by token"
  on public.household_invites for select
  using (true);

-- RPC: get invite token by 8-char code (first 8 chars of token, for "enter code" flow).
-- Returns the full token as text if exactly one non-expired invite matches the code prefix.
-- Drop existing function first in case it exists with different return type
drop function if exists public.get_invite_token_by_code(text);

create function public.get_invite_token_by_code(p_code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_token uuid;
begin
  if p_code is null or length(trim(p_code)) < 8 then
    return null;
  end if;

  -- Normalize: take first 8 chars, lowercase (token is stored as uuid lowercase).
  v_code := lower(regexp_replace(trim(p_code), '[^a-zA-Z0-9]', '', 'g'));
  v_code := left(v_code, 8);

  if length(v_code) < 8 then
    return null;
  end if;

  -- Find invite where token (as text) starts with the code and is not expired.
  select token into v_token
  from public.household_invites
  where replace(token::text, '-', '') like v_code || '%'
    and expires_at > now()
  order by created_at desc
  limit 1;

  if v_token is null then
    return null;
  end if;

  return v_token::text;
end;
$$;

comment on function public.get_invite_token_by_code(text) is
  'Returns the invite token for a given 8-character code (prefix of token). Used by accept-invite screen.';

grant execute on function public.get_invite_token_by_code(text) to authenticated;


-- From 20250210100000_children_household_share.sql
-- Allow family members to see shared children: add household_id and update RLS.

-- Add household_id to children (nullable for backward compatibility)
alter table public.children
  add column if not exists household_id uuid references public.households(id) on delete set null;

create index if not exists children_household_id_idx on public.children (household_id);

-- Backfill: set household_id from the child owner's first household
update public.children c
set household_id = (
  select hm.household_id
  from public.household_members hm
  where hm.user_id = c.user_id
  limit 1
)
where c.household_id is null;

-- Replace RLS policy so members can read own children OR children in their household
drop policy if exists "Users can manage own children" on public.children;
drop policy if exists "Users can read own or household children" on public.children;
drop policy if exists "Users can insert own children" on public.children;
drop policy if exists "Users can update own children" on public.children;
drop policy if exists "Users can delete own children" on public.children;

create policy "Users can read own or household children"
  on public.children for select
  using (
    auth.uid() = user_id
    or (household_id is not null and public.is_household_member(household_id))
  );

create policy "Users can insert own children"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and (
      household_id is null 
      or (household_id is not null and public.is_household_member(household_id))
    )
  );

create policy "Users can update own children"
  on public.children for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own children"
  on public.children for delete
  using (auth.uid() = user_id);

-- Journal entries: allow reading own entries OR entries for children visible to user (own or household)
drop policy if exists "Users can manage own journal entries" on public.journal_entries;
drop policy if exists "Users can read own or household child journal entries" on public.journal_entries;
drop policy if exists "Users can insert own journal entries" on public.journal_entries;
drop policy if exists "Users can update own journal entries" on public.journal_entries;
drop policy if exists "Users can delete own journal entries" on public.journal_entries;

create policy "Users can read own or household child journal entries"
  on public.journal_entries for select
  using (
    auth.uid() = user_id
    or (
      child_id is not null
      and exists (
        select 1 from public.children c
        where c.id = journal_entries.child_id
          and (c.user_id = auth.uid() or (c.household_id is not null and public.is_household_member(c.household_id)))
      )
    )
  );

create policy "Users can insert own journal entries"
  on public.journal_entries for insert to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own journal entries"
  on public.journal_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own journal entries"
  on public.journal_entries for delete
  using (auth.uid() = user_id);


-- From 20250210100001_fix_accept_invite_logic.sql
-- Fix accept_household_invite: try INSERT first, then check if user was added
-- This avoids race conditions and RLS visibility issues

create or replace function public.accept_household_invite(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
  v_household_id uuid;
  v_user_id uuid;
  v_inserted boolean := false;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Get invite
  select * into v_invite
  from public.household_invites
  where token = p_token and expires_at > now();

  if not found then
    return jsonb_build_object('success', false, 'error', 'Invite not found or expired');
  end if;

  v_household_id := v_invite.household_id;

  -- Try to insert user into household_members
  -- ON CONFLICT will silently do nothing if user is already a member
  insert into public.household_members (household_id, user_id, role)
  values (v_household_id, v_user_id, 'member')
  on conflict (household_id, user_id) do nothing;

  -- Check if user is now a member (either was added just now or was already a member)
  if public.is_household_member(v_household_id) then
    -- User is a member - delete the invite and return success
    delete from public.household_invites where id = v_invite.id;
    return jsonb_build_object('success', true, 'household_id', v_household_id);
  else
    -- This should not happen, but if INSERT failed for some reason, return error
    return jsonb_build_object('success', false, 'error', 'Failed to add user to household');
  end if;
end;
$$;

comment on function public.accept_household_invite(uuid) is
  'Accepts a household invite by token. Adds user to household_members and deletes the invite. Returns success=true if user is now a member (was added or already was a member).';


-- From 20250210100002_fix_children_insert_policy.sql
-- Fix children INSERT policy to ensure users can create children even without household
-- Split into two policies: one for null household_id, one for non-null

drop policy if exists "Users can insert own children" on public.children;

-- Policy 1: Allow inserting children with null household_id (user not in household)
create policy "Users can insert own children without household"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and household_id is null
  );

-- Policy 2: Allow inserting children with household_id if user is a member
create policy "Users can insert own children in household"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and household_id is not null
    and public.is_household_member(household_id)
  );


