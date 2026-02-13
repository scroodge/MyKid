# ai-gateway-usage

Returns AI Gateway usage statistics for the authenticated user.

## Usage

```bash
# Total only
curl "https://your-project.supabase.co/functions/v1/ai-gateway-usage" \
  -H "Authorization: Bearer <user_jwt>"

# With daily breakdown
curl "https://your-project.supabase.co/functions/v1/ai-gateway-usage?breakdown=daily" \
  -H "Authorization: Bearer <user_jwt>"
```

Response:
```json
{
  "input_tokens": 1500,
  "output_tokens": 320,
  "total_tokens": 1820,
  "request_count": 12,
  "by_day": {
    "2025-02-11": { "input_tokens": 500, "output_tokens": 100, "request_count": 4 }
  }
}
```
