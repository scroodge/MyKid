-- Fix household INSERT policy - ensure it works correctly.
-- This migration ensures the INSERT policy for households is properly configured.

-- Drop existing INSERT policy if it exists
drop policy if exists "Authenticated can insert household" on public.households;

-- Create a more explicit INSERT policy
-- For INSERT, we only need WITH CHECK (not USING)
create policy "Authenticated can insert household"
  on public.households
  for insert
  to authenticated
  with check (
    owner_id = auth.uid()
  );

-- Verify the policy exists
-- This query should return the policy name if it was created successfully
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
WHERE tablename = 'households' 
AND policyname = 'Authenticated can insert household';
