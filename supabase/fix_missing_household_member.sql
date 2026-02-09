-- Diagnostic and fix script for missing household_members entry
-- Run this as the affected user (or with their user_id)

-- 1. Check if user has any household_members entries
SELECT 
  hm.*,
  h.name as household_name,
  h.owner_id as household_owner_id
FROM public.household_members hm
JOIN public.households h ON h.id = hm.household_id
WHERE hm.user_id = auth.uid();

-- 2. Check if there are any invites for this user's email
-- (Replace 'user@example.com' with the actual email)
SELECT 
  hi.*,
  h.name as household_name
FROM public.household_invites hi
JOIN public.households h ON h.id = hi.household_id
WHERE hi.email = (SELECT email FROM auth.users WHERE id = auth.uid())
  AND hi.expires_at > now();

-- 3. If you have an invite token, you can manually add the user to household:
-- (Replace <invite_token> with actual token from step 2)
-- 
-- First, get household_id from invite:
-- SELECT household_id FROM public.household_invites WHERE token = '<invite_token>'::uuid;
--
-- Then add user manually (replace <household_id> with actual ID):
-- INSERT INTO public.household_members (household_id, user_id, role)
-- VALUES ('<household_id>'::uuid, auth.uid(), 'member')
-- ON CONFLICT (household_id, user_id) DO NOTHING;

-- 4. Alternative: If you know the household_id, add directly:
-- INSERT INTO public.household_members (household_id, user_id, role)
-- VALUES ('<household_id>'::uuid, auth.uid(), 'member')
-- ON CONFLICT (household_id, user_id) DO NOTHING
-- RETURNING *;
