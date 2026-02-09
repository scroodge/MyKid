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
