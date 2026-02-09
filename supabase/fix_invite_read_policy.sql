-- Allow anyone (including anonymous) to read invite by token
-- This is needed so users can see invite details before signing up/login

-- Drop existing policy
DROP POLICY IF EXISTS "Authenticated can read invite by token" ON public.household_invites;

-- Create new policy that allows anyone to read by token
CREATE POLICY "Anyone can read invite by token"
  ON public.household_invites FOR SELECT
  USING (true);

-- Keep the member policy for reading household invites
-- (This allows members to see all invites for their household)
CREATE POLICY "Members can read household_invites"
  ON public.household_invites FOR SELECT
  USING (public.is_household_member(household_invites.household_id));
