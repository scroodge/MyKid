-- Add immich_person_id to children for linking to Immich face recognition people
alter table public.children add column if not exists immich_person_id uuid;
