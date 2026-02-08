# MyKid — Journal for your child

A cross-platform (Android / iOS) app to keep a journal of your child's life: entries with photos/videos and text. Media is stored in **your** [Immich](https://immich.app) instance; journal entries sync via **Supabase**.

For logo and branding (splash, login, README, presentations), see `assets/brand/logo/mykid_logo_text_only.png` and [docs/Brand.md](docs/Brand.md).

---

## Project Description (for AI / LLM context)

> This section provides a full technical and functional overview for AI assistants working with the codebase.

### What the app does

**MyKid** is a Flutter (Dart) mobile app for parents to keep a journal of their child's life. Each journal entry can contain: date, text description, place (location), photos/videos (stored as references to Immich assets), and an optional link to a child profile.

- **Backend:** Supabase (auth, Postgres) — journal entries and children profiles.
- **Media:** Immich — all photos/videos are uploaded to the user's own Immich instance; only asset IDs are stored in Supabase.
- **Offline:** Hive cache for journal list when offline; pull-to-refresh to sync when back online.

### Tech stack

- **Flutter** (Dart)
- **Supabase** (auth, PostgREST)
- **Immich** (self-hosted photo server; REST API)
- **Hive** (local cache)
- **image_picker**, **file_picker**, **exif**, **geocoding**, **cached_network_image**, **share_plus**, **path_provider**

### Data model

**Children** (`children` table): `id`, `user_id`, `name`, `date_of_birth`, `immich_album_id` (optional; album created in Immich for this child).

**Journal entries** (`journal_entries` table): `id`, `user_id`, `date`, `text`, `assets` (JSONB array of `{immichAssetId, caption?}`), `child_id` (optional FK to children), `location` (optional text), `created_at`, `updated_at`.

RLS: users can access only their own rows.

### Features (current)

1. **Auth**
   - Supabase Auth (email/password). AuthGuard redirects to LoginScreen if not authenticated.
   - Login, signup, sign out. Session persists.

2. **Journal list** (`JournalListScreen`, route `/`)
   - Lists all entries (from Supabase), ordered by date descending.
   - Pull-to-refresh; on network error falls back to Hive cache.
   - FAB: create entry via modal: From camera | From gallery | Empty entry.
   - **From camera:** take photo → upload to Immich → open new entry with today's date, no location.
   - **From gallery:** pick one photo → read EXIF (date, GPS → reverse geocode for place) → upload to Immich → open new entry with inferred date/location.
   - **Empty entry:** open new entry with today, no assets.
   - AppBar: batch import button, settings button.
   - Tap entry → open `JournalEntryScreen`.

3. **Journal entry** (`JournalEntryScreen`)
   - **View mode** (default for existing entries): large photo preview, swipe between photos, tap photo → fullscreen with Share/Back. Edit button to switch to edit mode.
   - **Edit mode:** date picker, child selector (ChoiceChips), place field, description text, photo grid. Add photos (camera/gallery) → upload to Immich → add to entry; optionally add to selected child's Immich album.
   - When child is selected and photos are added, app creates Immich album "MyKid: {name}" for the child (if needed) and adds assets to it.
   - Save creates/updates entry in Supabase. Delete: optionally remove photos from child's Immich album.
   - New entries open in edit mode; existing ones open in view mode.

4. **Children** (Settings → Manage children, route `/children`)
   - List, add, edit, delete child profiles (name, date of birth).
   - Children used in journal entries to link entries to a child and to organize photos in Immich albums per child.
   - Age displayed as "X лет Y мес Z дн" (Russian) or similar.

5. **Batch import** (route `/import`)
   - Pick multiple photos/videos (FilePicker) → upload all to Immich → create one journal entry with all assets.
   - Opens `JournalEntryScreen` in create mode.

6. **Settings** (route `/settings`)
   - Immich: server URL and API key; Test connection (saves on success).
   - Link to Manage children.
   - Sign out.

### Key modules

- `lib/core/`: config (Supabase URL/key), ImmichClient/ImmichService/ImmichStorage, photo_metadata (EXIF date/GPS→place), selected_child_storage (unused for now).
- `lib/data/`: Child, JournalEntry, JournalEntryAsset; JournalRepository (Supabase CRUD), ChildrenRepository; JournalCache (Hive).
- `lib/features/auth/`: AuthGuard, LoginScreen, SignUpScreen.
- `lib/features/journal/`: JournalListScreen, JournalEntryScreen.
- `lib/features/children/`: ChildrenListScreen, ChildEditScreen.
- `lib/features/import/`: BatchImportScreen.
- `lib/features/settings/`: SettingsScreen.

### Routes

- `/` — journal list (guarded)
- `/login` — login
- `/signup` — signup
- `/settings` — settings
- `/children` — children list
- `/import` — batch import

### Environment

- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — from `.env` or `--dart-define-from-file=.env`.

---

## Setup

### Prerequisites

- Flutter SDK (stable)
- Android Studio / Xcode for running on device or simulator
- Supabase project (free tier is enough)
- Your own Immich instance or public Immich server

### Environment

Create a `.env` or use `--dart-define` so the app can reach Supabase. **Do not commit real keys.**

- `SUPABASE_URL` — your Supabase project URL (e.g. `https://xxxx.supabase.co`)
- `SUPABASE_ANON_KEY` — Supabase anonymous (public) key

Example `.env.example`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

The app also supports loading these from a config file or build-time defines; see `lib/core/config.dart`.

### Backend (Supabase)

1. Create a project at [supabase.com](https://supabase.com).
2. Run the migration in `supabase/migrations/` to create the `journal_entries` table and RLS.
3. In Supabase Dashboard → Authentication → enable Email (or other providers you want).
4. (Optional) Profile photos: run the storage migration so the `avatars` bucket and RLS policies exist (`supabase db push` or run `supabase/migrations/20250208100001_storage_avatars_bucket.sql` in the SQL editor). Without it, avatar upload fails with "row-level security policy".

Table `journal_entries` and API are described in [docs/backend.md](docs/backend.md).

### Immich

In the app: **Settings → Immich**: set your Immich server URL and API key (create the key in your Immich instance). All photo/video uploads and thumbnails use this connection.

### Run

Copy `.env.example` to `.env`, fill in your Supabase URL and anon key, then:

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

Or pass defines explicitly:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

(Use an Android device/emulator first; iOS requires a Mac and proper signing. If the `ios/` folder is incomplete, run `flutter create .` to regenerate platform files; camera/photo usage descriptions are already in `ios/Runner/Info.plist`.)

### Offline

When the app cannot reach Supabase, the journal list falls back to the last cached entries (Hive). After going back online, pull-to-refresh to sync again.

## Project structure

- `lib/` — Flutter app
  - `main.dart` — entry, Supabase init, Hive cache init
  - `core/` — config, Immich client, secure storage
  - `data/` — models, Supabase repository, local cache (Hive)
  - `features/` — auth, journal list/detail, settings, batch import
- `supabase/migrations/` — SQL for `journal_entries` and RLS
- `docs/backend.md` — schema and API description

## License

Private / unlicensed unless you add one.
