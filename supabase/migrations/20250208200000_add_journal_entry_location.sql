-- Optional location (e.g. from photo EXIF: city, country)
alter table public.journal_entries
  add column if not exists location text;
