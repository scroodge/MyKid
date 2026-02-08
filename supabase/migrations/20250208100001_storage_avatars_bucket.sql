-- Avatars bucket for profile photos. Public so getPublicUrl() works without signed URLs.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

-- RLS: authenticated users can upload only to their own folder (path = auth.uid()/...)
create policy "Users can upload own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.jwt()->>'sub')
);

-- RLS: users can update/overwrite their own file (upsert). owner_id in storage.objects is text.
create policy "Users can update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
)
with check (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
);

-- RLS: users can select (read) their own objects; public bucket also allows anon read
create policy "Users can read own avatar"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (owner_id = auth.uid()::text or owner_id is null)
);

-- Allow public read for avatars bucket (so profile photos load without auth in URLs)
create policy "Public read avatars"
on storage.objects
for select
to public
using (bucket_id = 'avatars');
