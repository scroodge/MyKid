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
