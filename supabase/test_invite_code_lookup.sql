-- Test script for invite code lookup
-- Run this in Supabase SQL Editor to debug the issue

-- 1. Check if there are any invites in the database
SELECT 
  id,
  household_id,
  email,
  token,
  token::text as token_text,
  replace(token::text, '-', '') as token_no_dashes,
  left(replace(token::text, '-', ''), 8) as code_from_token,
  expires_at,
  created_at,
  expires_at > now() as is_valid
FROM public.household_invites
ORDER BY created_at DESC
LIMIT 10;

-- 2. Test the function with a sample code (replace '6CED6040' with actual code from above)
-- First, let's see what code we should use:
SELECT 
  token,
  upper(left(replace(token::text, '-', ''), 8)) as invite_code,
  expires_at > now() as is_valid
FROM public.household_invites
WHERE expires_at > now()
ORDER BY created_at DESC
LIMIT 5;

-- 3. Test the function with actual code (replace 'YOURCODE' with code from step 2)
-- Example: SELECT public.get_invite_token_by_code('6CED6040');
SELECT public.get_invite_token_by_code('6CED6040') as found_token;

-- 4. Test with lowercase
SELECT public.get_invite_token_by_code('6ced6040') as found_token_lowercase;

-- 5. Test with code that has spaces or special chars
SELECT public.get_invite_token_by_code('6CED 6040') as found_token_with_spaces;

-- 6. Check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'household_invites';

-- 7. Test direct query (simulating what the function does)
-- Replace '6ced6040' with actual first 8 chars of a token
SELECT 
  token,
  token::text as token_text,
  replace(token::text, '-', '') as token_no_dashes,
  expires_at,
  expires_at > now() as is_valid
FROM public.household_invites
WHERE replace(token::text, '-', '') LIKE '6ced6040%'
  AND expires_at > now()
LIMIT 1;

-- 8. Check if function exists and has correct permissions
SELECT 
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as is_security_definer,
  pg_get_userbyid(p.proowner) as owner
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'get_invite_token_by_code';
