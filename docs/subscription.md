# Subscription (Managed Immich + AI)

Optional paid plans: **Basic** (10 GB Immich, no AI) and **Premium** (20 GB Immich + AI). Implemented per plan in `~/.cursor/plans/` (do not edit the plan file).

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
   - `APP_URL` — Stripe Checkout redirect. Use **`mykid://`** (deeplink) so success/cancel open the app; or `https://mykid.app` for a web page.

3. **Deploy functions**  
   `supabase functions deploy create-checkout`  
   `supabase functions deploy stripe-webhook`  
   `supabase functions deploy ai-proxy`

## Stripe

1. Create two Products with recurring Prices (e.g. Basic $6/mo, Premium $13/mo).
2. Webhook endpoint: `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`  
   Events: `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`
3. Copy the webhook signing secret into Supabase secret `STRIPE_WEBHOOK_SECRET`.

## Flow

- User taps “Subscription” in Settings → chooses Basic or Premium → “7 days free” → Stripe Checkout (trial 7 days).
- After checkout, Stripe sends webhooks; `stripe-webhook` upserts `subscriptions`, provisions an Immich user (quota 10/20 GB), then writes Immich URL + API key into `household_settings` via `set_household_immich_config_for_managed`. For Premium plan, it also creates an AI Gateway token (`ai_gateway_tokens` + Vault) so ai-proxy can forward per-user token to the gateway.
- On cancel/expire, webhook sets `subscriptions.status = 'expired'`, deletes user data (journal, children, household), and deletes the Immich user via Admin API.
- “Generate description” in the journal uses own AI keys if configured; otherwise, if the user has an active Premium subscription, it calls the `ai-proxy` Edge Function (which checks subscription and forwards to OpenAI).

---

## Пошаговое тестирование

### Подготовка (один раз)

1. **Supabase**
   - Применить все три миграции (`supabase db push` или SQL Editor).
   - В Edge Functions → Secrets задать: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_BASIC`, `STRIPE_PRICE_PREMIUM`, `IMMICH_SERVER_URL`, `IMMICH_ADMIN_API_KEY`, `GATEWAY_URL`, `GATEWAY_TOKEN`, `APP_URL` (для деплинка — `mykid://`).
   - Задеплоить: `create-checkout`, `stripe-webhook`, `ai-proxy`.

2. **Stripe (Test mode)**
   - Два продукта с ежемесячными ценами (Basic, Premium).
   - Webhook: URL `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`, события `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`.
   - Скопировать signing secret в секрет `STRIPE_WEBHOOK_SECRET`.

3. **Immich**
   - Убедиться, что доступен по `IMMICH_SERVER_URL` (у тебя https://mykid.ddns.net).
   - Создать первого админа, в настройках создать API key и прописать его в `IMMICH_ADMIN_API_KEY`.

4. **AI Gateway**
   - Запустить (локально или на сервере). В .env: `OPENAI_API_KEY`, `GATEWAY_TOKEN`; при использовании per-user токенов — `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
   - Убедиться, что доступен по `GATEWAY_URL` (тот же URL задать в Supabase).

5. **Приложение**
   - Собрать/запуск с нужным Supabase (.env): `flutter run --dart-define-from-file=.env`.

---

### Шаг 1 — Оформление триала

1. В приложении войти под тестовым пользователем.
2. Настройки → **Подписка**.
3. Выбрать план (Basic или Premium) → нажать **«7 дней бесплатно»**.
4. Должен открыться Stripe Checkout в браузере.
5. Заполнить тестовую карту: `4242 4242 4242 4242`, любую будущую дату, любой CVC.
6. Подтвердить. После редиректа должен открыться экран «Триал активирован» (деплинк `mykid://subscription-success`).

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
