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
