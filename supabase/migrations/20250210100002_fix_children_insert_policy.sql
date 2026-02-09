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
