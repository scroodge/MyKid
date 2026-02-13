# create-gateway-token

Creates an AI Gateway token for the authenticated user. Tokens are stored in `ai_gateway_tokens` (hashed). Usage is logged to `ai_gateway_usage` by the AI Gateway.

## Usage

```bash
curl -X POST https://your-project.supabase.co/functions/v1/create-gateway-token \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "token": "a1b2c3...",
  "message": "Save this token securely. It will not be shown again."
}
```

## Env

- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` – set by Supabase
- `REQUIRE_PREMIUM` (optional) – if `true`, only premium subscribers can create tokens
