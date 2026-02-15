# create-portal-session

Creates a Stripe Customer Portal session so the user can manage their subscription (cancel, change plan, update payment) in the app.

**Auth:** Bearer JWT (user must be signed in).

**Secrets:**
- `STRIPE_SECRET_KEY` — Stripe secret key
- `APP_URL` (optional) — Base URL for `return_url`; must be `https://` for portal (Stripe requirement). If not set or non-https (e.g. `mykid://`), uses `https://mykid.life`.

**Response:** `{ "url": "https://billing.stripe.com/..." }` — open in browser.

Configure the Customer Portal in [Stripe Dashboard → Billing → Customer portal](https://dashboard.stripe.com/settings/billing/portal) (cancel, plan change, payment methods).
