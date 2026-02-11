# MyKid

<p align="center">
  <img src="assets/brand/logo/mykid_logo_text_only.png" alt="MyKid" height="64">
</p>

<p align="center">
  <strong>Journal for your child's life</strong>
</p>

<p align="center">
  Photos, videos, moments — stored in <em>your</em> <a href="https://immich.app">Immich</a>. Journal syncs via <a href="https://supabase.com">Supabase</a>.
</p>

<p align="center">
  <a href="https://scroodge.github.io/MyKid/">English</a> •
  <a href="https://scroodge.github.io/MyKid/ru.html">Русский</a> •
  <a href="https://scroodge.github.io/MyKid/be.html">Беларуская</a>
</p>

<p align="center">
  <a href="#screenshots">Screenshots</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#setup">Setup</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

---

## Screenshots

<p align="center">
  <img src="assets/screenshots/01-select-child.png" alt="Select child" width="200">
  <img src="assets/screenshots/03-timeline-empty.png" alt="Timeline empty" width="200">
  <img src="assets/screenshots/04-timeline-with-entry.png" alt="Timeline with entry" width="200">
</p>
<p align="center">
  <img src="assets/screenshots/02-suggestions-empty.png" alt="Suggestions" width="200">
  <img src="assets/screenshots/05-add-entry-modal.png" alt="Add entry modal" width="200">
  <img src="assets/screenshots/06-entry-view.png" alt="Entry view" width="200">
  <img src="assets/screenshots/07-new-entry-form.png" alt="New entry form" width="200">
</p>

---

## Features

- **Self-hosted** — photos in your Immich, data in your Supabase
- **Family sharing** — invite household members, share children and entries
- **EXIF magic** — date and location auto-filled from photo metadata
- **AI descriptions** — generate journal text from photos (OpenAI, Gemini, Claude, or DeepSeek with on-device labels); see [docs/ai-providers.md](docs/ai-providers.md)
- **Offline-ready** — cached journal list when offline
- **Batch import** — add many photos at once

## Quick Start

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

See [Setup](#setup) for Supabase and Immich configuration.

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
- **AI (optional):** user API keys for OpenAI, Gemini, Claude, DeepSeek; **http** for API calls; **google_mlkit_image_labeling** for DeepSeek path (on-device labels → text prompt)

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
   - **Generate description:** button sends first photo to selected AI provider (OpenAI/Gemini/Claude vision, or DeepSeek via on-device ML Kit labels + text API) and fills description field. Configure in Settings → AI providers.
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
   - **AI providers** (route `/settings-ai-providers`): API keys for OpenAI, Gemini, Claude, DeepSeek; select default provider for "Generate description" in journal entries.
   - Immich: server URL and API key; Test connection (saves on success).
   - Link to Manage children, Family invites.
   - Legal: Privacy Policy, Terms of Use, Support, Open Source Licenses (App Store / Google Play compliance).
   - Account: Export my data (GDPR), Delete account, Sign out.

### Key modules

- `lib/core/`: config (Supabase URL/key), ImmichClient/ImmichService/ImmichStorage, photo_metadata (EXIF date/GPS→place), ai_provider_storage (API keys + selected provider), ai_vision_service (Vision / DeepSeek text), on_device_image_labels (ML Kit labels for DeepSeek on Android/iOS).
- `lib/data/`: Child, JournalEntry, JournalEntryAsset; JournalRepository (Supabase CRUD), ChildrenRepository; JournalCache (Hive).
- `lib/features/auth/`: AuthGuard, LoginScreen, SignUpScreen.
- `lib/features/journal/`: JournalListScreen, JournalEntryScreen.
- `lib/features/children/`: ChildrenListScreen, ChildEditScreen.
- `lib/features/import/`: BatchImportScreen.
- `lib/features/settings/`: SettingsScreen, AiProviderSettingsScreen.

### Routes

- `/` — journal list (guarded)
- `/login` — login
- `/signup` — signup
- `/settings` — settings
- `/settings-ai-providers` — AI provider API keys and default provider
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
2. Apply the schema: in Supabase Dashboard → SQL Editor run [docs/full_schema.sql](docs/full_schema.sql).
3. In Supabase Dashboard → Authentication → enable Email (or other providers you want).

Table `journal_entries` and API are described in [docs/backend.md](docs/backend.md).

### Immich

In the app: **Settings → Immich**: set your Immich server URL and API key (create the key in your Immich instance). All photo/video uploads and thumbnails use this connection.

### AI descriptions (optional)

To use "Generate description" in journal entries, go to **Settings → AI providers**: add one or more API keys (OpenAI, Gemini, Claude, DeepSeek) and select the default provider. Keys are stored only on device. See [docs/ai-providers.md](docs/ai-providers.md) for details and how DeepSeek uses on-device labels.

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
  - `core/` — config, Immich client, secure storage, AI provider storage & vision service, on-device image labels (ML Kit)
  - `data/` — models, Supabase repository, local cache (Hive)
  - `features/` — auth, journal list/detail, settings, AI provider settings, batch import
- `docs/` — [full_schema.sql](docs/full_schema.sql) (apply once in SQL Editor), [backend.md](docs/backend.md) (schema, API), [ai-providers.md](docs/ai-providers.md), [immich-api.md](docs/immich-api.md), [edge-function-setup.md](docs/edge-function-setup.md)

### Legal URLs (App Store / Google Play)

For store compliance, the app includes links to Privacy Policy, Terms of Use, Support, Account Deletion, and Data Export. Configure in `.env`:

```
PRIVACY_POLICY_URL=https://scroodge.github.io/MyKid/privacy.html
TERMS_OF_SERVICE_URL=https://scroodge.github.io/MyKid/terms.html
SUPPORT_URL=mailto:scroodgemac@gmail.com
ACCOUNT_DELETION_URL=mailto:scroodgemac@gmail.com?subject=Account%20Deletion%20Request
DATA_EXPORT_URL=mailto:scroodgemac@gmail.com?subject=Data%20Export%20Request
SOURCE_CODE_URL=https://github.com/scroodge/MyKid
SPONSOR_URL=https://github.com/sponsors/scroodge
```

Or use `--dart-define=PRIVACY_POLICY_URL=...` etc. when building.

### Self-service account deletion

The app calls the `delete-account` Edge Function, which removes the user and cascades to children, journal entries, household data. Deploy:

```bash
supabase functions deploy delete-account
```

### Open Source Licenses

Regenerate `lib/oss_licenses.dart` after changing `pubspec.yaml` dependencies:

```bash
dart run dart_pubspec_licenses:generate
```

## Contributors

Thanks to everyone who contributes to MyKid. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get involved.

## Support development

If you find MyKid useful, consider supporting its development:

- [GitHub Sponsors](https://github.com/sponsors/scroodge)
- Or spread the word and star the [repo](https://github.com/scroodge/MyKid)

## License

[MIT License](LICENSE)
