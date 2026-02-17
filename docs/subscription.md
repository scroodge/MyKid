# Subscription (Managed Immich + AI)

Optional paid plans: **Basic** (10 GB Immich, no AI) and **Premium** (20 GB Immich + AI). Implemented per plan in `~/.cursor/plans/` (do not edit the plan file).

## Plan comparison

| | No subscription (own hosting) | Basic | Premium |
|---|-------------------------------|-------|---------|
| **Immich storage** | Your own | 10 GB managed | 20 GB managed |
| **AI descriptions** | Your keys (AI Providers / AI Gateway) | Your keys (AI Providers) | Built-in via ai-proxy |
| **AI token limit** | Unlimited (your keys) | Unlimited (your keys) | 100,000 tokens/month |
| **Settings shown** | Immich, AI Providers, AI Gateway Token, Change Supabase | AI Providers only | Subscription only |

## Supabase

1. **Migrations**  
   Apply in order: `20250210000000_subscriptions.sql`, `20250211000000_ai_gateway_tokens.sql`, `20250211000001_ai_gateway_vault_plain.sql` (e.g. `supabase db push` or run in SQL Editor).

2. **Edge Function secrets** (Dashboard → Project Settings → Edge Functions → Secrets):
   - `STRIPE_SECRET_KEY` — Stripe secret key (e.g. `sk_test_...` or `sk_live_...`)
   - `STRIPE_WEBHOOK_SECRET` — Signing secret for the webhook endpoint (e.g. `whsec_...`)
   - `STRIPE_PRICE_BASIC` — Stripe Price ID for Basic plan (monthly)
   - `STRIPE_PRICE_PREMIUM` — Stripe Price ID for Premium plan (monthly)
   - `IMMICH_SERVER_URL` — Managed Immich base URL (e.g. `https://immich.example.com`)
   - `IMMICH_ADMIN_API_KEY` — Immich admin API key (for creating/deleting users)
   - **Gateway:** `GATEWAY_URL` and `GATEWAY_TOKEN` — `ai-proxy` forwards to your AI Gateway. Use **one shared token** (same as in Gateway .env) and/or **per-user tokens**: if a Premium user has a token in `ai_gateway_tokens` (created automatically by stripe-webhook when Premium is activated), ai-proxy sends that user’s token so the gateway can track usage per customer. Gateway must accept either the shared `GATEWAY_TOKEN` or validate per-user tokens (e.g. hash token and check `ai_gateway_tokens.token_hash` via an API).
   - **Or direct OpenAI:** `OPENAI_API_KEY` — `ai-proxy` calls OpenAI directly (no gateway).
   - `APP_URL` — Stripe Checkout redirect. Use **`mykid://`** (deeplink) so success/cancel open the app; or `https://mykid.life` for a web page.
   - **Google Play (Android):** `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (full JSON key), `GOOGLE_PLAY_PACKAGE_NAME` (app package name). See [Google Play Billing (Android)](#google-play-billing-android).

3. **Deploy functions**  
   Deploy all with **`--no-verify-jwt`** (project uses Publishable/Secret keys):
   `supabase functions deploy --no-verify-jwt`
   Or per function: `supabase functions deploy create-checkout --no-verify-jwt`, etc.

## Stripe

1. Create two Products with recurring Prices (e.g. Basic $6/mo, Premium $13/mo).
2. Webhook endpoint: `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`  
   Events: `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`
3. Copy the webhook signing secret into Supabase secret `STRIPE_WEBHOOK_SECRET`.

## Google Play Billing (Android)

For publishing on Google Play, subscriptions are sold via Google Play Billing. The app uses the same `subscriptions` table; activation is done by the Edge Function `verify-google-play-purchase` after the app sends the purchase token.

### Play Console setup

1. **Subscription products**  
   In [Google Play Console](https://play.google.com/console) → your app → **Monetize** → **Subscriptions**, create two subscriptions:
   - **Product ID:** `mykid_basic` (Basic plan, 10 GB). Add a base plan (e.g. monthly) and optionally a free trial.
   - **Product ID:** `mykid_premium` (Premium plan, 20 GB + AI). Same.

2. **Service account for server-side verification**  
   - In [Google Cloud Console](https://console.cloud.google.com/) (project linked to Play Console), create a **Service account** (IAM → Service accounts).
   - Create a JSON key and download it.
   - In **Google Play Console** → **Users and permissions** → invite the service account email with role **View app information** and **View financial data** (or **Admin** for testing).
   - In Supabase Edge Functions → Secrets, add:
     - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — paste the **entire** contents of the JSON key file (single line or multiline).
     - `GOOGLE_PLAY_PACKAGE_NAME` — your app’s package name (e.g. `life.mykid.app`).

3. **Deploy**  
   `supabase functions deploy verify-google-play-purchase --no-verify-jwt`

4. **License (RSA public key, optional)**  
   If Play Console shows **License** and asks to “include this Base64-encoded RSA public key in your app’s executable” (e.g. under Monetize → Monetization setup):
   - **Do not put it in `.env`** — Google requires the key inside the built app (APK).
   - In the project, set it in code: `lib/data/google_play_subscription_service.dart` → constant **`kGooglePlayLicensePublicKeyBase64`**.
   - Copy the key from Play Console, **remove all spaces**, and assign:  
     `const String kGooglePlayLicensePublicKeyBase64 = 'MIIBIjAN...';`
   - For subscriptions-only (no app license check) you can leave it as `''`.

### Testing (Android)

**Важно:** Google Play Billing работает только если приложение загружено в Play Console (хотя бы в **Internal testing**). Если вы просто собрали APK локально и установили на устройство, Google Play Billing будет недоступен, и приложение будет использовать Stripe Checkout.

**Шаги для тестирования Google Play Billing:**

1. **Загрузите приложение в Play Console:**
   - Соберите App Bundle: `flutter build appbundle`
   - В Play Console → **Release** → **Testing** → **Internal testing** → **Create new release**
   - Загрузите `build/app/outputs/bundle/release/app-release.aab`
   - Добавьте тестовых пользователей (или сделайте трек открытым)

2. **Создайте подписки:**
   - Play Console → ваше приложение → **Monetize** → **Subscriptions**
   - Создайте `mykid_basic` и `mykid_premium` (если ещё не созданы)
   - Убедитесь, что они **активны** (статус "Active")

3. **Настройте License testing:**
   - Play Console → **Setup** → **License testing**
   - Добавьте Gmail-адреса тестировщиков

4. **Установите приложение из Play Console:**
   - На устройстве войдите под тестовым Google-аккаунтом
   - Откройте ссылку на Internal testing трек или найдите приложение в Play Store (если трек открытый)
   - Установите приложение **через Play Store** (не через `adb install`)

5. **Проверьте в приложении:**
   - Откройте **Settings → Subscription**
   - Если Google Play Billing доступен, при нажатии "7 дней бесплатно" откроется нативный диалог Google Play (не браузер со Stripe)
   - В логах (`adb logcat | grep GooglePlay`) должно быть: `[GooglePlay] Initialized successfully with 2 products`

**Если видите только Stripe (диагностика):**

1. **Проверьте логи на устройстве:**
   ```bash
   adb logcat | grep -E "GooglePlay|SubscriptionScreen"
   ```
   Должны увидеть либо:
   - `[GooglePlay] Initialized successfully with 2 products: mykid_basic, mykid_premium` ✅
   - `[GooglePlay] ❌ Products NOT FOUND in Play Console: mykid_basic, mykid_premium` ❌
   - `[GooglePlay] Billing not available (isAvailable=false)` ❌

2. **Проверьте в Play Console:**
   - **Monetize → Subscriptions** → должны быть созданы подписки:
     - Product ID: **`mykid_basic`** (статус: **Active**, не Draft)
     - Product ID: **`mykid_premium`** (статус: **Active**, не Draft)
   - Если подписки в статусе **Draft** → нажмите "Activate" на каждой
   - Если подписок нет → создайте их с **точными** Product ID: `mykid_basic` и `mykid_premium`

3. **Проверьте package name:**
   - В Play Console → **Setup → App integrity** → должно быть: `com.mykidapp.mykid_app`
   - В коде (`android/app/build.gradle`): `applicationId = "com.mykidapp.mykid_app"` (должны совпадать)

4. **Проверьте, что приложение загружено:**
   - Play Console → **Release → Testing** → должен быть хотя бы один релиз (Internal testing)
   - Приложение должно быть установлено **из Play Store**, а не через `adb install`

5. **Проверьте License testing:**
   - Play Console → **Setup → License testing** → добавлен ли ваш Gmail-аккаунт
   - На устройстве должен быть войден **тот же** Google-аккаунт

6. **Если продукты не найдены:**
   - Подождите 2-3 часа после создания/активации подписок (Google может кэшировать)
   - Или попробуйте переустановить приложение из Play Store

### Manage subscription on Android (cancel, pause, resubscribe)

On Android, when the user has an active subscription and Google Play Billing is available, the **Manage** button opens the Google Play subscription management page for the current plan. There the user can cancel, **pause**, resubscribe, or update payment methods. The app uses the [recommended deep link](https://developer.android.com/google/play/billing/subscriptions#pause):  
`https://play.google.com/store/account/subscriptions?sku=<product_id>&package=<applicationId>`  
with `product_id` = `mykid_basic` or `mykid_premium` and `applicationId` from `android/app/build.gradle` (e.g. `com.mykidapp.mykid_app`).

## Тестовые платежи

### Stripe (iOS, веб, Android без Google Play)

1. **Режим Test**  
   В [Stripe Dashboard](https://dashboard.stripe.com/) переключитесь на **Test mode** (переключатель вверху). Все ключи должны быть тестовыми: `sk_test_...`, `pk_test_...`.

2. **Секреты в Supabase**  
   В Edge Functions → Secrets укажите:
   - `STRIPE_SECRET_KEY` = `sk_test_...` (из Stripe → Developers → API keys).
   - `STRIPE_WEBHOOK_SECRET` = signing secret от **тестового** webhook (Developers → Webhooks → добавить endpoint с URL вашего `stripe-webhook`, события `customer.subscription.*` → скопировать **Signing secret**).

3. **Тестовая карта**  
   При оплате в Checkout используйте:
   - Номер: **`4242 4242 4242 4242`**
   - Срок: любая будущая дата (например 12/34)
   - CVC: любые 3 цифры  
   Деньги с карты не списываются. [Другие тестовые карты](https://docs.stripe.com/testing#cards) (отказ, 3D Secure и т.д.) — в документации Stripe.

### Google Play (Android)

1. **License testing**  
   В [Play Console](https://play.google.com/console) → ваше приложение → **Setup** → **License testing** (или **Monetize** → **Monetization setup** → тестовые аккаунты):
   - Добавьте Gmail-адреса тестировщиков в список **License testers**.
   - Эти аккаунты смогут делать тестовые покупки подписок **без списания реальных денег**; подписка будет активна короткий период (например 5 минут для быстрых тестов) или по настройкам базового плана.

2. **Как тестировать**  
   На устройстве должен быть войден тот же Google-аккаунт, что добавлен в License testing. Откройте приложение → Настройки → Подписка → выберите план → «7 дней бесплатно». Откроется нативный диалог Google Play; завершите тестовую покупку. Приложение отправит purchase token в `verify-google-play-purchase`, подписка появится в Supabase.

3. **Внутреннее тестирование**  
   Если приложение ещё не в продакшене, загрузите сборку в **Internal testing** (Release → Testing → Internal testing). Тестовые покупки работают и там при добавленных License testers.

Полный пошаговый сценарий — в разделе [Пошаговое тестирование](#пошаговое-тестирование).

## Flow

- User taps “Subscription” in Settings → chooses Basic or Premium → “7 days free” → Stripe Checkout (trial 7 days).
- After checkout, Stripe sends webhooks; `stripe-webhook` upserts `subscriptions`, provisions an Immich user (quota 10/20 GB), then writes Immich URL + API key into `household_settings` via `set_household_immich_config_for_managed`. On upgrade (Basic→Premium), it updates the existing Immich user's quota from 10 to 20 GB. For Premium plan, it also creates an AI Gateway token (`ai_gateway_tokens` + Vault) so ai-proxy can forward per-user token to the gateway.
- On cancel/expire, webhook sets `subscriptions.status = 'expired'`, deletes user data (journal, children, household), and deletes the Immich user via Admin API.
- “Generate description” in the journal uses own AI keys if configured; otherwise, if the user has an active Premium subscription, it calls the `ai-proxy` Edge Function. `ai-proxy` allows access if the user has an active Premium subscription **or** any household member has Premium (family sharing). **Token limits:** Premium plan includes 100,000 tokens/month (resets at `current_period_end`). When the limit is exceeded, `ai-proxy` returns 429 Too Many Requests with `Retry-After` header. Users can view usage and progress in **Settings → AI Gateway Token** (shows monthly limit, used tokens, progress bar, and daily breakdown).
- **Manage (cancel / change plan):** On **Android** with Google Play Billing, the “Manage” button opens the Google Play subscription management page (cancel, pause, resubscribe). On **iOS / web** or when Stripe was used, it calls the `create-portal-session` Edge Function and opens the Stripe Customer Portal in the browser. Configure the portal in [Stripe Dashboard → Billing → Customer portal](https://dashboard.stripe.com/settings/billing/portal).

**Portal return to app:** Stripe Customer Portal requires an **https** `return_url`. If `APP_URL` is a deeplink (`mykid://`), the function uses `https://mykid.life/subscription` as return URL. So after upgrade/cancel in the portal the user lands on that page in the browser. To send them back to the app, host a page at `https://mykid.life/subscription` that redirects to the app, e.g.:

```html
<!DOCTYPE html>
<html><head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0;url=mykid://subscription-success">
  <title>Return to MyKid</title>
</head><body>
  <p>Opening the app…</p>
  <script>window.location.href = 'mykid://subscription-success';</script>
  <p><a href="mykid://subscription-success">Tap here if the app did not open</a>.</p>
</body></html>
```

Alternatively, set up [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app) for `mykid.life` so that opening `https://mykid.life/subscription` opens the app.

---

## Организация тестирования (ветка стала основной)

Когда подписка (managed Immich + Stripe) — часть основной ветки:

1. **Регрессия перед релизом**  
   Прогонять [пошаговое тестирование](#пошаговое-тестирование) (чекаут → Immich → AI → отмена) на тестовом проекте Supabase + Stripe Test перед каждым релизом или перед мержем в `main`.

2. **Автотесты**  
   - `flutter test` — юнит/виджет-тесты без Stripe (например, `SubscriptionRepository` с моком Supabase, экран подписки с моком).  
   - В CI не нужны реальные Stripe/Immich: достаточно прогона `flutter test` и сборки.

3. **Ручной чеклист**  
   Держать чеклист в [Пошаговое тестирование](#пошаговое-тестирование) и при необходимости копировать в issue/PR (например: «Проверено: чекаут, Immich, AI, портал, отмена»).

4. **Тестовые аккаунты**  
   Иметь 1–2 тестовых пользователя Supabase (и при необходимости тестовые Stripe customers) для стабильного ручного прогона.

---

## Пошаговое тестирование

### Подготовка (один раз)

1. **Supabase**
   - Применить все три миграции (`supabase db push` или SQL Editor).
   - В Edge Functions → Secrets задать: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_BASIC`, `STRIPE_PRICE_PREMIUM`, `IMMICH_SERVER_URL`, `IMMICH_ADMIN_API_KEY`, `GATEWAY_URL`, `GATEWAY_TOKEN`, `APP_URL` (для деплинка — `mykid://`).
   - Задеплоить с `--no-verify-jwt`: `supabase functions deploy --no-verify-jwt` (или по одной функции).

2. **Stripe (Test mode)**
   - Два продукта с ежемесячными ценами (Basic, Premium).
   - Webhook: URL `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`, события `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`.
   - Скопировать signing secret в секрет `STRIPE_WEBHOOK_SECRET`.

3. **Immich**
   - Убедиться, что доступен по `IMMICH_SERVER_URL` (e.g. `https://immich.mykid.life`).
   - Создать первого админа, в настройках создать API key и прописать его в `IMMICH_ADMIN_API_KEY`.

4. **AI Gateway**
   - Запустить (локально или на сервере). В .env: `OPENAI_API_KEY`, `GATEWAY_TOKEN`; при использовании per-user токенов — `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
   - Убедиться, что доступен по `GATEWAY_URL` (тот же URL задать в Supabase).

5. **Приложение**
   - Собрать/запуск с нужным Supabase (.env): `flutter run --dart-define-from-file=.env`.

6. **Google Play (только для Android)**  
   - В Play Console созданы подписки с product id `mykid_basic` и `mykid_premium`.  
   - В Supabase заданы секреты `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` и `GOOGLE_PLAY_PACKAGE_NAME`, задеплоена функция `verify-google-play-purchase --no-verify-jwt`.  
   - Тестовый аккаунт добавлен в License testing.

---

### Шаг 1 — Оформление триала

1. В приложении войти под тестовым пользователем.
2. Настройки → **Подписка**.
3. Выбрать план (Basic или Premium) → нажать **«7 дней бесплатно»**.
4. Должен открыться Stripe Checkout в браузере.
5. Заполнить тестовую карту: `4242 4242 4242 4242`, любую будущую дату, любой CVC.
6. Подтвердить. После редиректа должен открыться экран «Триал активирован» (деплинк `mykid://subscription-success`).

**На Android (Google Play):** На устройстве с добавленным в License testing аккаунтом: Настройки → Подписка → выбрать план → «7 дней бесплатно» → откроется нативный диалог Google Play. Оформить тестовую подписку; после успешной оплаты приложение отправит покупку на бэкенд, экран обновится и покажет активный план.

---

### Шаг 2 — Проверка после чекаута

1. **Supabase**
   - Таблица `subscriptions`: одна запись с `user_id`, `status = trialing`, `plan_id` (basic/premium).
   - Таблица `household_settings`: для household пользователя — заполнены `immich_server_url` и (через Vault) API key Immich.

2. **Immich**
   - В админке (или через API) — новый пользователь с квотой 10 GB (Basic) или 20 GB (Premium).

3. **Приложение**
   - В разделе подписки отображается активный план и «Trial until …».

---

### Шаг 3 — Фото и Immich

1. Создать запись в дневнике, приложить фото.
2. Убедиться, что фото загружается в Immich (используется managed Immich из `household_settings`).

---

### Шаг 4 — AI (только Premium)

1. Под пользователем с подпиской **Premium** (триал или active).
2. В записи дневника с фото нажать **«Сгенерировать описание»**.
3. Не настраивая своих AI-ключей, описание должно сгенерироваться через ai-proxy → Gateway → OpenAI.
4. При ошибке 403 — проверить, что у пользователя в `subscriptions` план `premium` и статус `trialing` или `active`.

---

### Шаг 5 — Отмена (по желанию)

1. В Stripe Dashboard (Test) найти подписку пользователя и отменить её.
2. Дождаться вебхука (или повторно отправить событие).
3. В Supabase: в `subscriptions` статус должен стать `expired`.
4. Данные пользователя (journal_entries, children, household) и пользователь в Immich должны быть удалены.

---

## Stripe vs Google Play / Apple IAP

Текущая реализация — **только Stripe** (Checkout в браузере → webhook → Supabase/Immich/токены). Это нормальный вариант для MVP и тестирования, но для публикации в сторах есть нюансы.

| | Только Stripe (как сейчас) | Google Play Billing / Apple IAP |
|--|----------------------------|----------------------------------|
| **Политики стора** | Google и Apple требуют использовать их биллинг для **внутриприложенных** покупок цифровых товаров/подписок. Только Stripe может привести к отказу или требованию добавить IAP. | Соответствует правилам Google Play и App Store. |
| **Где удобно** | Внутреннее тестирование, TestFlight, возможно веб-версия или «подписка на сайте». | Продажа подписки прямо в мобильном приложении на Android/iOS. |
| **Комиссия** | ~3% (Stripe). | ~15–30% (Google/Apple). |
| **UX** | Открытие браузера, редирект обратно в приложение. | Нативный диалог оплаты в приложении. |

**Рекомендация:**  
- Оставлять Stripe для текущего флоу (быстрый старт, один бэкенд для всех платформ) — ок для беты и внутреннего использования.  
- Для релиза в Google Play и App Store **добавить** Google Play Billing и Apple In-App Purchase и на бэкенде считать подписку активной, если есть валидная подписка либо в Stripe, либо в Google/Apple (по purchase token / receipt). Тогда не «вместо», а **в дополнение** к Stripe: один и тот же план Premium можно продавать через Stripe (например, с сайта) или через IAP в приложении.  
- Пилить «сразу только Google подписку» имело бы смысл, если бы приложение было только под Android и только через стор; раз есть и iOS, и managed-сервис с Immich, текущий путь (сначала Stripe, при необходимости потом IAP) — разумный.

**Публикация сначала в Google Play:**  
Если первая публикация — в Google Play, **нужно добавить Google Play Billing** до выкладки в сторе. Stripe можно оставить для веба или как запасной канал; в приложении на Android подписку лучше продавать через Play Billing, и бэкенд (Supabase + webhook или Cloud Function) должен верифицировать покупку через Google Play Developer API и писать/обновлять запись в `subscriptions` так же, как это делает stripe-webhook (plan_id, status, provision Immich, AI token и т.д.).
