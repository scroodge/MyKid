# MyKid

<p align="center">
  <img src="assets/brand/logo/mykid_logo_text_only.png" alt="MyKid" height="64">
</p>

<p align="center">
  <strong>Дзённік жыцця вашага дзіцяці</strong>
</p>

<p align="center">
  Фота, відэа, моманты — захоўваюцца ў <em>вашым</em> <a href="https://immich.app">Immich</a>. Дзённік сінхранізуецца праз <a href="https://supabase.com">Supabase</a>.
</p>

<p align="center">
  <a href="https://scroodge.github.io/MyKid/">English</a> •
  <a href="https://scroodge.github.io/MyKid/ru.html">Русский</a> •
  <a href="https://scroodge.github.io/MyKid/be.html">Беларуская</a>
</p>

<p align="center">
  <a href="#скрыншоты">Скрыншоты</a> •
  <a href="#магчымасці">Магчымасці</a> •
  <a href="#хуткі-старт">Хуткі старт</a> •
  <a href="#налада">Налада</a> •
  <a href="#ліцэнзія">Ліцэнзія</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white" alt="Платформа">
  <img src="https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="Ліцэнзія">
</p>

---

## Скрыншоты

<p align="center">
  <img src="assets/screenshots/01-select-child.png" alt="Выбар дзіцяці" width="200">
  <img src="assets/screenshots/03-timeline-empty.png" alt="Стужка пустая" width="200">
  <img src="assets/screenshots/04-timeline-with-entry.png" alt="Стужка з запісам" width="200">
</p>
<p align="center">
  <img src="assets/screenshots/02-suggestions-empty.png" alt="Рэкамендацыі" width="200">
  <img src="assets/screenshots/05-add-entry-modal.png" alt="Дадаць запіс" width="200">
  <img src="assets/screenshots/06-entry-view.png" alt="Прагляд запісу" width="200">
  <img src="assets/screenshots/07-new-entry-form.png" alt="Форма новага запісу" width="200">
</p>

---

## Магчымасці

- **Уласны хостинг** — фота ў вашым Immich, даныя ў вашым Supabase
- **Сямейны доступ** — запрашайце членаў сям'і, дзяліцеся дзецьмі і запісамі
- **Магія EXIF** — дата і месца аўтаматычна падстаўляюцца з метаданых фота
- **AI-апісанні** — генерацыя тэксту дзённіка з фота (OpenAI, Gemini, Claude або DeepSeek з лакальным распазнаваннем); гл. [docs/ai-providers.md](docs/ai-providers.md)
- **Афлайн-рэжым** — кэшаваны спіс запісаў пры адсутнасці сеткі
- **Масавы імпорт** — даданне мноства фота за раз

## Хуткі старт

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

Гл. [Налада](#налада) для канфігурацыі Supabase і Immich.

---

## Апісанне праекта (для AI / LLM)

> Гэты раздзел дае тэхнічны і функцыянальны агляд для AI-асістэнтаў, якія працуюць з кодам.

### Што робіць дадатак

**MyKid** — мабільны дадатак на Flutter (Dart) для бацькоў, якія вядуць дзённік жыцця дзіцяці. Кожны запіс можа змяшчаць: дату, тэкставае апісанне, месца, фота/відэа (захоўваюцца як спасылкі на Immich), і опцыянальную прывязку да профілю дзіцяці.

- **Backend:** Supabase (auth, Postgres) — запісы дзённіка і профілі дзяцей.
- **Медыя:** Immich — усе фота/відэа загружаюцца ў ваш асобнік Immich; у Supabase захоўваюцца толькі ID.
- **Афлайн:** Hive-кэш для спісу запісаў афлайн; pull-to-refresh для сінхранізацыі пры падключэнні.

### Тэхналогіі

- **Flutter** (Dart)
- **Supabase** (auth, PostgREST)
- **Immich** (self-hosted фотасервер; REST API)
- **Hive** (лакальны кэш)
- **image_picker**, **file_picker**, **exif**, **geocoding**, **cached_network_image**, **share_plus**, **path_provider**
- **AI (опцыянальна):** API-ключы карыстальніка для OpenAI, Gemini, Claude, DeepSeek; **http** для API; **google_mlkit_image_labeling** для DeepSeek (лакальныя меткі → тэкставы промпт)

### Мадэль даных

**Дзеці** (табліца `children`): `id`, `user_id`, `name`, `date_of_birth`, `immich_album_id` (опцыянальна).

**Запісы дзённіка** (табліца `journal_entries`): `id`, `user_id`, `date`, `text`, `assets` (JSONB масіў `{immichAssetId, caption?}`), `child_id`, `location`, `created_at`, `updated_at`.

RLS: карыстальнікі бачаць толькі свае даныя.

### Маршруты

- `/` — спіс запісаў (абаронены)
- `/login` — уваход
- `/signup` — рэгістрацыя
- `/settings` — налады
- `/settings-ai-providers` — AI-правайдеры
- `/children` — спіс дзяцей
- `/import` — масавы імпорт

---

## Налада

### Патрабаванні

- Flutter SDK (stable)
- Android Studio / Xcode
- Праект Supabase
- Уласны Immich або публічны сервер

### Пераменныя асяроддзя

Стварыце `.env` або выкарыстоўвайце `--dart-define`. **Не каміцьце рэальныя ключы.**

- `SUPABASE_URL` — URL вашага праекта Supabase
- `SUPABASE_ANON_KEY` — ананімны ключ Supabase

Прыклад `.env.example`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Backend (Supabase)

1. Стварыце праект на [supabase.com](https://supabase.com).
2. Прымяніце схему: Supabase Dashboard → SQL Editor → [docs/full_schema.sql](docs/full_schema.sql).
3. У Authentication уключыце Email.

### Immich

У дадатку: **Налады → Immich**: пакажыце URL сервера і API-ключ. Усе загрузкі і мініяцюры выкарыстоўваюць гэта падключэнне.

### AI-апісанні (опцыянальна)

Каб выкарыстоўваць «Згенераваць апісанне» у запісах: **Налады → AI-правайдеры** — дадайце API-ключы (OpenAI, Gemini, Claude, DeepSeek) і выберыце правайдера па змаўчанні. Падрабязней у [docs/ai-providers.md](docs/ai-providers.md).

### Запуск

Скапіруйце `.env.example` у `.env`, запоўніце Supabase URL і ключ:

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

### Афлайн

Пры адсутнасці сувязі з Supabase спіс запісаў загружаецца з кэша (Hive). Пры аднаўленні сеткі — pull-to-refresh для сінхранізацыі.

## Структура праекта

- `lib/` — Flutter-дадатак
  - `main.dart` — кропка ўваходу, ініцыялізацыя Supabase і Hive
  - `core/` — канфіг, Immich-кліент, сховішча, AI
  - `data/` — мадэлі, рэпазіторыі, кэш
  - `features/` — auth, журнал, налады, імпорт
- `docs/` — [full_schema.sql](docs/full_schema.sql), [backend.md](docs/backend.md), [ai-providers.md](docs/ai-providers.md), [immich-api.md](docs/immich-api.md), [edge-function-setup.md](docs/edge-function-setup.md)

### Юрыдычныя URL (App Store / Google Play)

Наладзіце ў `.env`:

```
PRIVACY_POLICY_URL=https://scroodge.github.io/MyKid/privacy.html
TERMS_OF_SERVICE_URL=https://scroodge.github.io/MyKid/terms.html
SUPPORT_URL=mailto:scroodgemac@gmail.com
...
```

### Выдаленне акаўнта

Дадатак выклікае Edge Function `delete-account`. Дэплой:

```bash
supabase functions deploy delete-account
```

### Ліцэнзіі Open Source

Пасля змены залежнасцей у `pubspec.yaml`:

```bash
dart run dart_pubspec_licenses:generate
```

## Удзельнікі

Дзякуй усім, хто ўносіць уклад у MyKid. Гл. [CONTRIBUTING.md](CONTRIBUTING.md).

## Падтрымка развіцця

- [GitHub Sponsors](https://github.com/sponsors/scroodge)
- Або падзяліцеся і пастаўце зорку [рэпазіторыю](https://github.com/scroodge/MyKid)

## Ліцэнзія

[MIT License](LICENSE)
