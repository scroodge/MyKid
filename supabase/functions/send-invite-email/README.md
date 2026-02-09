# Send Invite Email Edge Function

This Edge Function sends email invitations when a household invite is created.

## Setup

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Link to your Supabase project**:
   ```bash
   supabase link --project-ref your-project-ref
   ```

3. **Configure environment variables**:
   
   Option A: Using Resend (recommended)
   - Sign up at [resend.com](https://resend.com)
   - Get your API key
   - Set secret in Supabase:
     ```bash
     supabase secrets set RESEND_API_KEY=your-resend-api-key
     ```
   
   Option B: Using Supabase SMTP (if configured)
   - Configure SMTP in Supabase Dashboard → Settings → Auth → SMTP Settings
   - Update the function to use Supabase SMTP instead of Resend

4. **Set APP_URL** (optional, for web invite links):
   ```bash
   supabase secrets set APP_URL=https://your-app-domain.com
   ```

5. **Deploy the function**:
   ```bash
   supabase functions deploy send-invite-email
   ```

## Usage

The function is called automatically by the Flutter app after creating an invite. It expects:

```json
{
  "email": "user@example.com",
  "inviteToken": "uuid-token",
  "inviteCode": "8CHARCODE",
  "inviterEmail": "inviter@example.com", // optional
  "householdName": "Smith Family" // optional
}
```

## Email Provider Options

### Resend (Current Implementation)
- Free tier: 3,000 emails/month
- Easy setup, good deliverability
- Requires API key

### Alternative: Supabase SMTP
If you configure SMTP in Supabase Dashboard, you can modify the function to use Supabase's email service instead.

### Alternative: SendGrid, Mailgun, etc.
Modify the function to use any email API provider.
