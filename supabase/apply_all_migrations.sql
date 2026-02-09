-- Apply all migrations manually via Supabase Dashboard SQL Editor
-- Copy and paste this entire file into SQL Editor and run

-- ============================================
-- Migration 1: Add household_id to children and update RLS
-- ============================================

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
drop policy if exists "Users can insert own children without household" on public.children;
drop policy if exists "Users can insert own children in household" on public.children;
drop policy if exists "Users can update own children" on public.children;
drop policy if exists "Users can delete own children" on public.children;

create policy "Users can read own or household children"
  on public.children for select
  using (
    auth.uid() = user_id
    or (household_id is not null and public.is_household_member(household_id))
  );

-- Split INSERT policy into two: one for null household_id, one for non-null
create policy "Users can insert own children without household"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and household_id is null
  );

create policy "Users can insert own children in household"
  on public.children for insert to authenticated
  with check (
    auth.uid() = user_id
    and household_id is not null
    and public.is_household_member(household_id)
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

-- ============================================
-- Migration 2: Fix accept_household_invite RPC
-- ============================================

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
