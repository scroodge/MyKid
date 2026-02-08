# MyKid — Journal for your child

A cross-platform (Android / iOS) app to keep a journal of your child's life: entries with photos/videos and text. Media is stored in **your** [Immich](https://immich.app) instance; journal entries sync via **Supabase**.

## Setup

### Prerequisites

- Flutter SDK (stable)
- Android Studio / Xcode for running on device or simulator
- Supabase project (free tier is enough)
- (Optional) Your own Immich instance or public Immich server

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
