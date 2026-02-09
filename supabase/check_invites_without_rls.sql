-- Check invites bypassing RLS (as postgres superuser)
-- This will show if there are any invites at all, regardless of RLS

-- 1. Check total count (bypassing RLS)
SELECT COUNT(*) as total_invites FROM public.household_invites;

-- 2. Check invites with details (bypassing RLS)
SELECT 
  id,
  household_id,
  email,
  token,
  token::text as token_text,
  replace(token::text, '-', '') as token_no_dashes,
  upper(left(replace(token::text, '-', ''), 8)) as invite_code,
  expires_at,
  created_at,
  expires_at > now() as is_valid,
  expires_at < now() as is_expired
FROM public.household_invites
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check RLS is enabled
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'household_invites';

-- 4. Check all RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual::text as using_expression,
  with_check::text as with_check_expression
FROM pg_policies
WHERE tablename = 'household_invites'
ORDER BY policyname;

-- 5. Test query as authenticated user (simulate what app does)
-- This will respect RLS
SET ROLE authenticated;
SELECT COUNT(*) as visible_invites FROM public.household_invites;
RESET ROLE;

-- 6. Test the function as authenticated user
SET ROLE authenticated;
SELECT public.get_invite_token_by_code('6CED6040') as result;
RESET ROLE;
