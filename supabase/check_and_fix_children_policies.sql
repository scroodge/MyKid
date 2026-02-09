-- Check current policies and fix if needed
-- Run this in Supabase SQL Editor

-- 1. Check current INSERT policies for children
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
WHERE tablename = 'children' AND cmd = 'INSERT';

-- 2. Drop all existing INSERT policies
DROP POLICY IF EXISTS "Users can manage own children" ON public.children;
DROP POLICY IF EXISTS "Users can insert own children" ON public.children;
DROP POLICY IF EXISTS "Users can insert own children without household" ON public.children;
DROP POLICY IF EXISTS "Users can insert own children in household" ON public.children;

-- 3. Create the two separate policies
-- Policy 1: Allow inserting children with null household_id (user not in household)
CREATE POLICY "Users can insert own children without household"
  ON public.children FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND household_id IS NULL
  );

-- Policy 2: Allow inserting children with household_id if user is a member
CREATE POLICY "Users can insert own children in household"
  ON public.children FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND household_id IS NOT NULL
    AND public.is_household_member(household_id)
  );

-- 4. Verify policies were created
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd,
  with_check
FROM pg_policies 
WHERE tablename = 'children' AND cmd = 'INSERT'
ORDER BY policyname;
