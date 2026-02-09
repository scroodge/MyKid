-- Test if current user can insert a child
-- Run this as the authenticated user (in Supabase SQL Editor, you're authenticated as postgres, so this won't work)
-- This is just for reference - the app will test this automatically

-- Check if household_id column exists
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'children' AND column_name = 'household_id';

-- Check current user's household membership
SELECT 
  hm.*,
  h.name as household_name
FROM public.household_members hm
JOIN public.households h ON h.id = hm.household_id
WHERE hm.user_id = auth.uid();

-- Try to insert a test child (this will fail in SQL Editor because you're postgres, not the app user)
-- But you can see what the policy expects:
-- INSERT INTO public.children (user_id, name, household_id)
-- VALUES (auth.uid(), 'Test Child', NULL);
