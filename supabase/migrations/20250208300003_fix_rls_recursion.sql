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

create policy "Members can read household"
  on public.households for select
  using (public.is_household_member(households.id));

create policy "Members can update household"
  on public.households for update
  using (public.is_household_member(households.id))
  with check (true);

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
