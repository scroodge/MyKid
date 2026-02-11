# MyKid

<p align="center">
  <img src="assets/brand/logo/mykid_logo_text_only.png" alt="MyKid" height="64">
</p>

<p align="center">
  <strong>Дневник жизни вашего ребёнка</strong>
</p>

<p align="center">
  Фото, видео, моменты — хранятся в <em>вашем</em> <a href="https://immich.app">Immich</a>. Дневник синхронизируется через <a href="https://supabase.com">Supabase</a>.
</p>

<p align="center">
  <a href="https://scroodge.github.io/MyKid/">English</a> •
  <a href="https://scroodge.github.io/MyKid/ru.html">Русский</a> •
  <a href="https://scroodge.github.io/MyKid/be.html">Беларуская</a>
</p>

<p align="center">
  <a href="#скриншоты">Скриншоты</a> •
  <a href="#возможности">Возможности</a> •
  <a href="#быстрый-старт">Быстрый старт</a> •
  <a href="#настройка">Настройка</a> •
  <a href="#лицензия">Лицензия</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white" alt="Платформа">
  <img src="https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="Лицензия">
</p>

---

## Скриншоты

<p align="center">
  <img src="assets/screenshots/01-select-child.png" alt="Выбор ребёнка" width="200">
  <img src="assets/screenshots/03-timeline-empty.png" alt="Лента пуста" width="200">
  <img src="assets/screenshots/04-timeline-with-entry.png" alt="Лента с записью" width="200">
</p>
<p align="center">
  <img src="assets/screenshots/02-suggestions-empty.png" alt="Рекомендации" width="200">
  <img src="assets/screenshots/05-add-entry-modal.png" alt="Добавить запись" width="200">
  <img src="assets/screenshots/06-entry-view.png" alt="Просмотр записи" width="200">
  <img src="assets/screenshots/07-new-entry-form.png" alt="Форма новой записи" width="200">
</p>

---

## Возможности

- **Собственный хостинг** — фото в вашем Immich, данные в вашем Supabase
- **Семейный доступ** — приглашайте членов семьи, делитесь детьми и записями
- **Магия EXIF** — дата и место автоматически подставляются из метаданных фото
- **AI-описания** — генерация текста дневника из фото (OpenAI, Gemini, Claude или DeepSeek с локальной распознаванием); см. [docs/ai-providers.md](docs/ai-providers.md)
- **Офлайн-режим** — кэшированный список записей при отсутствии сети
- **Массовый импорт** — добавление множества фото за раз

## Быстрый старт

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

См. [Настройка](#настройка) для конфигурации Supabase и Immich.

---

## Описание проекта (для AI / LLM)

> Этот раздел даёт технический и функциональный обзор для AI-ассистентов, работающих с кодом.

### Что делает приложение

**MyKid** — мобильное приложение на Flutter (Dart) для родителей, ведущих дневник жизни ребёнка. Каждая запись может содержать: дату, текстовое описание, место, фото/видео (хранятся как ссылки на Immich), и опциональную привязку к профилю ребёнка.

- **Backend:** Supabase (auth, Postgres) — записи дневника и профили детей.
- **Медиа:** Immich — все фото/видео загружаются в ваш экземпляр Immich; в Supabase хранятся только ID.
- **Офлайн:** Hive-кэш для списка записей офлайн; pull-to-refresh для синхронизации при подключении.

### Технологии

- **Flutter** (Dart)
- **Supabase** (auth, PostgREST)
- **Immich** (self-hosted фотосервер; REST API)
- **Hive** (локальный кэш)
- **image_picker**, **file_picker**, **exif**, **geocoding**, **cached_network_image**, **share_plus**, **path_provider**
- **AI (опционально):** API-ключи пользователя для OpenAI, Gemini, Claude, DeepSeek; **http** для API; **google_mlkit_image_labeling** для DeepSeek (локальные метки → текстовый промпт)

### Модель данных

**Дети** (таблица `children`): `id`, `user_id`, `name`, `date_of_birth`, `immich_album_id` (опционально).

**Записи дневника** (таблица `journal_entries`): `id`, `user_id`, `date`, `text`, `assets` (JSONB массив `{immichAssetId, caption?}`), `child_id`, `location`, `created_at`, `updated_at`.

RLS: пользователи видят только свои данные.

### Маршруты

- `/` — список записей (защищён)
- `/login` — вход
- `/signup` — регистрация
- `/settings` — настройки
- `/settings-ai-providers` — AI-провайдеры
- `/children` — список детей
- `/import` — массовый импорт

---

## Настройка

### Требования

- Flutter SDK (stable)
- Android Studio / Xcode
- Проект Supabase
- Собственный Immich или публичный сервер

### Переменные окружения

Создайте `.env` или используйте `--dart-define`. **Не коммитьте реальные ключи.**

- `SUPABASE_URL` — URL вашего проекта Supabase
- `SUPABASE_ANON_KEY` — анонимный ключ Supabase

Пример `.env.example`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Backend (Supabase)

1. Создайте проект на [supabase.com](https://supabase.com).
2. Примените схему: Supabase Dashboard → SQL Editor → [docs/full_schema.sql](docs/full_schema.sql).
3. В Authentication включите Email.

### Immich

В приложении: **Настройки → Immich**: укажите URL сервера и API-ключ. Все загрузки и миниатюры используют это подключение.

### AI-описания (опционально)

Чтобы использовать «Сгенерировать описание» в записях: **Настройки → AI-провайдеры** — добавьте API-ключи (OpenAI, Gemini, Claude, DeepSeek) и выберите провайдера по умолчанию. Подробнее в [docs/ai-providers.md](docs/ai-providers.md).

### Запуск

Скопируйте `.env.example` в `.env`, заполните Supabase URL и ключ:

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

### Офлайн

При отсутствии связи с Supabase список записей загружается из кэша (Hive). При восстановлении сети — pull-to-refresh для синхронизации.

## Структура проекта

- `lib/` — Flutter-приложение
  - `main.dart` — точка входа, инициализация Supabase и Hive
  - `core/` — конфиг, Immich-клиент, хранилище, AI
  - `data/` — модели, репозитории, кэш
  - `features/` — auth, журнал, настройки, импорт
- `docs/` — [full_schema.sql](docs/full_schema.sql), [backend.md](docs/backend.md), [ai-providers.md](docs/ai-providers.md), [immich-api.md](docs/immich-api.md), [edge-function-setup.md](docs/edge-function-setup.md)

### Юридические URL (App Store / Google Play)

Настройте в `.env`:

```
PRIVACY_POLICY_URL=https://scroodge.github.io/MyKid/privacy.html
TERMS_OF_SERVICE_URL=https://scroodge.github.io/MyKid/terms.html
SUPPORT_URL=mailto:scroodgemac@gmail.com
...
```

### Удаление аккаунта

Приложение вызывает Edge Function `delete-account`. Деплой:

```bash
supabase functions deploy delete-account
```

### Лицензии Open Source

После изменения зависимостей в `pubspec.yaml`:

```bash
dart run dart_pubspec_licenses:generate
```

## Участники

Спасибо всем, кто вносит вклад в MyKid. См. [CONTRIBUTING.md](CONTRIBUTING.md).

## Поддержка развития

- [GitHub Sponsors](https://github.com/sponsors/scroodge)
- Или поделитесь и поставьте звезду [репозиторию](https://github.com/scroodge/MyKid)

## Лицензия

[MIT License](LICENSE)
