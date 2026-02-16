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
  "monthly_limit": 100000,
  "period_used_tokens": 1820,
  "period_start": "2025-02-01T00:00:00Z",
  "period_end": "2025-03-01T00:00:00Z",
  "by_day": {
    "2025-02-11": { "input_tokens": 500, "output_tokens": 100, "request_count": 4 }
  }
}
```

**Fields:**
- `monthly_limit`: Token limit for Premium plan (100K/month) or `null` if no limit
- `period_used_tokens`: Tokens used in current billing period (from `period_start` to `period_end`)
- `period_start`: Start of current billing period (ISO 8601)
- `period_end`: End of current billing period (ISO 8601), when limit resets
