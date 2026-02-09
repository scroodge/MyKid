# delete-account

Self-service account deletion. The authenticated user can delete their own account and all related data.

## Flow

1. App calls this function with user's JWT (Authorization header).
2. Function verifies the user, then calls `auth.admin.deleteUser()` with service role.
3. Database cascades delete: children, journal_entries, household_members, households (if owner), household_invites, etc.
4. App receives success → signs out and navigates to login.

## Deploy

```bash
supabase functions deploy delete-account
```

## No secrets required

Uses `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (automatically set by Supabase).
