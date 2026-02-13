# Auth Confirm Edge Function

Handles email confirmation redirect from Supabase. Detects mobile devices and redirects to deep link (`mykid://auth/confirm`), or shows instructions for desktop users.

## Features

- **Mobile detection**: Automatically redirects mobile users to the app via deep link
- **Desktop instructions**: Shows clear instructions for desktop users to open the link on their phone
- **Hash parameter support**: Handles Supabase token parameters passed via URL hash (`#token=...`)
- **Query parameter support**: Also handles parameters passed via query string (`?token=...`)

## Deployment

Deploy this function to Supabase:

```bash
supabase functions deploy auth-confirm
```

## Usage

The function is automatically called when users click the email confirmation link. The redirect URL is set in:

- `lib/features/auth/signup_screen.dart`
- `lib/features/onboarding/onboarding_screen.dart`

Both use: `{supabaseUrl}/functions/v1/auth-confirm`

## How it works

1. User clicks email confirmation link from Supabase
2. Supabase processes the token and redirects to this Edge Function
3. Function detects device type:
   - **Mobile**: Redirects to `mykid://auth/confirm?token=...&type=signup`
   - **Desktop**: Shows HTML page with instructions and a button to open the app

## URL Parameters

- `token` - Supabase auth token (may be in hash `#token=...` or query `?token=...`)
- `type` - Auth type (usually `signup`)
- `invite_token` - Optional invite token for family invites
