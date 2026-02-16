# Debug Managed AI (ai-proxy → Gateway)

Когда запросы не доходят или возвращают ошибку, проверьте по шагам: с Mac и логи.

## 1. Проверка с Mac (ручной вызов ai-proxy)

Из корня проекта:

```bash
source .env 2>/dev/null
./scripts/test-ai-proxy.sh --email "YOUR_LOGIN_EMAIL" --password "YOUR_PASSWORD"
```

Или если уже есть JWT (access_token из сессии Supabase):

```bash
./scripts/test-ai-proxy.sh --jwt "YOUR_ACCESS_TOKEN"
```

Скрипт:
1. При необходимости логинится в Supabase Auth и получает JWT.
2. Отправляет текстовый запрос в Edge Function `ai-proxy` (как приложение).
3. Показывает HTTP-код и тело ответа.

Интерпретация:
- **200** — цепочка работает (Supabase → ai-proxy → gateway или OpenAI).
- **401** — неверный или просроченный JWT.
- **403** — нет Premium (подписка не active/trialing или не в household).
- **503** — в Edge Function не заданы `GATEWAY_URL` + `GATEWAY_TOKEN` или `OPENAI_API_KEY` (Supabase → Project Settings → Edge Functions → Secrets).
- **500** или HTML вместо JSON — смотреть логи ai-proxy (см. ниже).

## 2. Где смотреть логи

### Supabase (Edge Function ai-proxy)

1. [Supabase Dashboard](https://supabase.com/dashboard) → ваш проект.
2. **Edge Functions** → выберите **ai-proxy** → вкладка **Logs**.
3. Там видны ошибки (`ai-proxy error: ...`), статусы ответов от шлюза и т.д.

Здесь видно:
- доходит ли запрос до ai-proxy;
- прошла ли проверка пользователя и подписки;
- какой ответ вернул gateway (или OpenAI) и что вернулось клиенту.

### Contabo (AI Gateway на ai.mykid.life)

Шлюз (AI_Gateway) крутится на сервере как systemd-сервис `ai-gateway`. Логи:

```bash
ssh root@YOUR_CONTABO_IP   # или ваш пользователь
journalctl -u ai-gateway -f
```

Или без follow (последние строки):

```bash
journalctl -u ai-gateway -n 100 --no-pager
```

Полезно:
- убедиться, что запросы доходят до шлюза (логи входящих запросов);
- увидеть ошибки при обращении к OpenAI (например, 401/429/5xx).

Проверка здоровья шлюза с Mac:

```bash
curl -s https://ai.mykid.life/health
# ожидается: {"status":"ok"} или аналог
```

Проверка чата с токеном (как ai-proxy дергает шлюз):

```bash
curl -s -X POST https://ai.mykid.life/v1/chat/completions \
  -H "X-Gateway-Token: YOUR_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hi"}],"max_tokens":10}'
```

`YOUR_GATEWAY_TOKEN` должен совпадать с тем, что задан в Supabase Edge Function Secrets как `GATEWAY_TOKEN` (и в `.env` на Contabo в AI_Gateway).

## 3. Типичные причины «запросы не идут»

| Симптом | Где смотреть | Что проверить |
|--------|----------------|---------------|
| В приложении ошибка «Managed AI: FormatException… HTML» | Логи ai-proxy | ai-proxy возвращает HTML (часто 502/504 от шлюза или неверный URL). Проверить `GATEWAY_URL` (без пробелов, с `https://`), доступность ai.mykid.life. |
| 503 от ai-proxy | Edge Function Secrets | Задать `GATEWAY_URL` и `GATEWAY_TOKEN` (или `OPENAI_API_KEY` для прямого OpenAI). |
| 403 Premium required | БД / Stripe | У пользователя (или household) подписка premium, status active/trialing. |
| 401 Unauthorized | Токен | В приложении пользователь залогинен, сессия не истекла. Для теста с Mac — свежий JWT. |
| На Contabo в логах нет запросов | Сеть / nginx / DNS | С Mac: `curl https://ai.mykid.life/health`. С Supabase Edge Function запросы идут с их IP; firewall/nginx не должны блокировать. |

После изменений в Secrets перезапуск Edge Function не обязателен (секреты подхватываются при вызове). После изменений на Contabo: `sudo systemctl restart ai-gateway`.
