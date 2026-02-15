# create-portal-session

Creates a Stripe Customer Portal session so the user can manage their subscription (cancel, change plan, update payment) in the app.

**Auth:** Bearer JWT (user must be signed in).

**Secrets:**
- `STRIPE_SECRET_KEY` — Stripe secret key
- `APP_URL` (optional) — Base URL for `return_url`; must be `https://` for portal (Stripe requirement). If not set or non-https (e.g. `mykid://`), uses `https://mykid.life`. After the user finishes in the portal they are sent to `{return_url}/subscription`. To return to the app, host a redirect page there (see [docs/subscription.md](../../../docs/subscription.md) (section «Portal return to app») and `docs/subscription-redirect-page.html`).

**Response:** `{ "url": "https://billing.stripe.com/..." }` — open in browser.

Configure the Customer Portal in [Stripe Dashboard → Billing → Customer portal](https://dashboard.stripe.com/settings/billing/portal) (cancel, plan change, payment methods).

## If the portal always opens the login page (/p/login/...)

The Dashboard does not expose the option to turn off the login step. Disable it once via API (replace `sk_test_...` with your Stripe secret key):

```bash
# 1) Get the default configuration ID (use -G so -d becomes query params)
curl -s -G "https://api.stripe.com/v1/billing_portal/configurations" \
  -u "sk_test_YOUR_KEY:" \
  -d "is_default=true" | jq -r '.data[0].id'
# → e.g. bpc_1ABC...

# 2) Disable the login page for that configuration
curl "https://api.stripe.com/v1/billing_portal/configurations/bpc_XXXX" \
  -u "sk_test_YOUR_KEY:" \
  -d "login_page[enabled]=false"
```
Replace `bpc_XXXX` with the id from step 1.

Use the same key mode (test vs live) as your app. After that, session URLs should open the portal directly without the email login step.
