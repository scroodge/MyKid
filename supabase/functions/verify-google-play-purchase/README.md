# verify-google-play-purchase

Verifies a Google Play subscription purchase (purchase token + product id) and activates the subscription in the same way as the Stripe webhook: upserts `subscriptions`, provisions Immich user (or updates quota), and creates AI Gateway token for Premium.

## Secrets (Supabase Edge Functions → Secrets)

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — Full JSON key for a service account that has access to the Google Play Android Developer API (e.g. **View financial data** and **View app information**). Create in Google Cloud Console → IAM → Service accounts, then grant the role **Google Play Android Developer** (or enable Android Publisher API and use a key with that scope).
- `GOOGLE_PLAY_PACKAGE_NAME` — Android application id (e.g. `life.mykid.app`).
- Same as stripe-webhook: `IMMICH_SERVER_URL`, `IMMICH_ADMIN_API_KEY`; for Premium, Gateway secrets if using ai-proxy.

## Request

- **Method:** POST
- **Headers:** `Authorization: Bearer <user JWT>`, `Content-Type: application/json`
- **Body:** `{ "purchase_token": "<from Play Billing>", "product_id": "mykid_basic" | "mykid_premium" }`

## Deploy

```bash
supabase functions deploy verify-google-play-purchase --no-verify-jwt
```

## Product IDs

Must match subscriptions created in Google Play Console: `mykid_basic`, `mykid_premium`. Map to plans: basic (10 GB), premium (20 GB + AI).
