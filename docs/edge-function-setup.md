# Edge Function Setup: Send Invite Email

## Overview

The `send-invite-email` Edge Function automatically sends email invitations when a household invite is created in the app.

## Prerequisites

1. **Supabase CLI** installed:

   **On macOS (Homebrew)**:
   ```bash
   brew install supabase/tap/supabase
   ```

   **On Linux**:
   ```bash
   # Download binary
   curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
   sudo mv supabase /usr/local/bin/
   ```

   **On Windows**:
   ```powershell
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

   Or download from: https://github.com/supabase/cli/releases

2. **Supabase project linked**:
   ```bash
   supabase link --project-ref your-project-ref
   ```
   Or get your project ref from Supabase Dashboard → Settings → General → Reference ID

## Setup Steps

### Option 1: Using Resend (Recommended)

1. **Sign up for Resend**:
   - Go to [resend.com](https://resend.com)
   - Create an account (free tier: 3,000 emails/month)
   - Verify your domain or use Resend's test domain

2. **Get API Key**:
   - In Resend Dashboard → API Keys → Create API Key
   - Copy the API key

3. **Set Secret in Supabase**:
   ```bash
   supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx
   ```

4. **Update Email From Address**:
   - Edit `supabase/functions/send-invite-email/index.ts`
   - Change `'MyKid <invites@mykid.app>'` to your verified domain
   - Or use Resend's test domain: `'onboarding@resend.dev'` (for testing)

5. **Deploy Function**:
   ```bash
   supabase functions deploy send-invite-email
   ```

### Option 2: Using Supabase SMTP

If you have SMTP configured in Supabase Dashboard → Settings → Auth → SMTP Settings:

1. Modify the Edge Function to use Supabase's email service
2. Or use a different email provider API (SendGrid, Mailgun, etc.)

### Option 3: Skip Email (Manual Sharing)

If you don't configure email, the function will return a message indicating email is not configured, but the invite will still be created and can be shared manually via link/code.

## Testing

After deployment, test the function:

```bash
supabase functions invoke send-invite-email \
  --body '{"email":"test@example.com","inviteToken":"test-token","inviteCode":"TESTCODE"}'
```

Or test from the app: create an invite and check if email is sent.

## Environment Variables

- `RESEND_API_KEY` - Required if using Resend
- `APP_URL` - Optional, for web invite links (defaults to `https://mykid.app`)
- `SUPABASE_URL` - Automatically set by Supabase
- `SUPABASE_ANON_KEY` - Automatically set by Supabase

## Email Template

The function sends an HTML email with:
- Invitation link (deep link: `mykid://invite/<token>`)
- Invite code (8 characters)
- Family name (if set)
- Inviter email (if available)
- Expiration notice (7 days)

## Troubleshooting

- **Email not sending**: Check Resend API key is set correctly
- **Function not found**: Ensure function is deployed (`supabase functions list`)
- **401 Unauthorized**: Check user is authenticated when calling function
- **Email in spam**: Verify domain in Resend, use proper SPF/DKIM records
