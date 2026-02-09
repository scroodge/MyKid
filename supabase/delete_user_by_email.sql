-- Delete user wa@offtech.by and all related data (cascade).
-- Run in Supabase Dashboard → SQL Editor.

delete from auth.users
where email = 'wa@offtech.by';
