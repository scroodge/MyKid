-- Clear all invites from database
-- WARNING: This will delete ALL invites!

DELETE FROM public.household_invites;

-- Verify deletion
SELECT COUNT(*) as remaining_invites FROM public.household_invites;
