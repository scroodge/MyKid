# Backend: Supabase schema and API

## Overview

Journal entries (date, text, and references to Immich assets) are stored in Supabase. Media files stay in the user's Immich; we only store asset IDs.

## Table: `children`

| Column            | Type         | Description |
|-------------------|--------------|-------------|
| `id`              | `uuid`       | Primary key |
| `user_id`         | `uuid`       | References `auth.users(id)` |
| `name`            | `text`       | Child's name |
| `date_of_birth`   | `date`       | Optional |
| `immich_album_id` | `uuid`       | Optional; Immich album for this child (created by app) |
| `created_at`      | `timestamptz`| |
| `updated_at`      | `timestamptz`| |

RLS: users can manage only their own rows. See migration `20250208100000_add_children_and_child_id.sql`.

## Table: `journal_entries`

| Column       | Type      | Description |
|-------------|-----------|-------------|
| `id`        | `uuid`    | Primary key, default `gen_random_uuid()` |
| `user_id`   | `uuid`    | References `auth.users(id)` |
| `date`      | `date`    | Day of the entry (for grouping) |
| `text`      | `text`    | Free-form description |
| `assets`    | `jsonb`   | Array of `{ "immichAssetId": "uuid", "caption": "optional" }` |
| `child_id`  | `uuid`    | Optional; references `children(id)` |
| `location`  | `text`    | Optional; place (e.g. from photo EXIF) |
| `created_at`| `timestamptz` | Set on insert |
| `updated_at`| `timestamptz` | Set on insert/update, used for sync conflict resolution |

### RLS (Row Level Security)

- Enable RLS on `journal_entries`.
- Policy: users can `SELECT`, `INSERT`, `UPDATE`, `DELETE` only rows where `user_id = auth.uid()`.

### Indexes

- `journal_entries_user_id_idx` on `(user_id)`
- `journal_entries_user_id_date_idx` on `(user_id, date DESC)` for listing by user and date

## API (Supabase client)

The app uses the Supabase Flutter client; no custom HTTP endpoints are required. All access goes through PostgREST with JWT from Supabase Auth.

- **List entries**: `supabase.from('journal_entries').select().eq('user_id', userId).order('date', ascending: false).range(from, to)`
- **Get one**: `supabase.from('journal_entries').select().eq('id', id).single()`
- **Insert**: `supabase.from('journal_entries').insert({ user_id, date, text, assets })`
- **Update**: `supabase.from('journal_entries').update({ date, text, assets, updated_at }).eq('id', id).eq('user_id', userId)`
- **Delete**: `supabase.from('journal_entries').delete().eq('id', id).eq('user_id', userId)`

Conflict resolution: when syncing, compare `updated_at` (last write wins) or merge strategy as needed.

## Auth

Use Supabase Auth (e.g. email/password or OAuth). After sign-in, `Supabase.instance.client.auth.currentUser?.id` is the `user_id` for all journal_entries operations.
