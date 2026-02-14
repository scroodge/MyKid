# Edge Functions deploy (MyKidApp)

## Always use `--no-verify-jwt`

This project uses **Publishable** and **Secret** API keys. Deploy every Edge Function with:

```bash
supabase functions deploy --no-verify-jwt
```

Or per function:

```bash
supabase functions deploy ai-gateway-usage --no-verify-jwt
supabase functions deploy ai-proxy --no-verify-jwt
supabase functions deploy auth-confirm --no-verify-jwt
supabase functions deploy create-checkout --no-verify-jwt
supabase functions deploy create-gateway-token --no-verify-jwt
supabase functions deploy delete-account --no-verify-jwt
supabase functions deploy send-invite-email --no-verify-jwt
supabase functions deploy stripe-webhook --no-verify-jwt
```

Without `--no-verify-jwt`, the Supabase gateway returns **401 Invalid JWT** and the request never reaches the function. User verification is done inside each function via `supabase.auth.getUser()`.

See [Supabase: API keys](https://supabase.com/docs/guides/api/api-keys) and [docs/edge-function-setup.md](edge-function-setup.md).
