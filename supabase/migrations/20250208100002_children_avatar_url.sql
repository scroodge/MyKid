-- Child profile avatar URL (Supabase Storage public URL)
alter table public.children
  add column if not exists avatar_url text;

-- RLS: allow upload to path children/{user_id}/{child_id}/avatar.jpg (child avatars in same bucket)
create policy "Users can upload child avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = 'children'
  and (storage.foldername(name))[2] = (select auth.jwt()->>'sub')
);
