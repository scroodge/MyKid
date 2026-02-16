-- Detailed check for user way@offtech.by
-- Run this in Supabase SQL Editor

-- 1. Check if user exists
SELECT 
  'User Info' as check_type,
  id as user_id,
  email,
  created_at,
  email_confirmed_at
FROM auth.users
WHERE email = 'way@offtech.by';

-- 2. Check subscription
SELECT 
  'Subscription' as check_type,
  user_id,
  plan_id,
  status,
  immich_user_id,
  storage_limit_gb,
  monthly_token_limit,
  stripe_customer_id,
  stripe_subscription_id,
  created_at,
  updated_at
FROM subscriptions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by');

-- 3. Check household membership
SELECT 
  'Household Membership' as check_type,
  hm.household_id,
  hm.user_id,
  hm.role,
  h.name as household_name,
  h.owner_id,
  h.created_at as household_created_at
FROM household_members hm
LEFT JOIN households h ON h.id = hm.household_id
WHERE hm.user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by');

-- 4. Check household settings (Immich config)
SELECT 
  'Household Settings' as check_type,
  hs.household_id,
  hs.immich_server_url,
  hs.immich_vault_secret_id,
  hs.created_at,
  hs.updated_at,
  -- Check if secret exists in vault
  CASE WHEN vs.id IS NOT NULL THEN '✅ Secret exists' ELSE '❌ Secret not found' END as vault_secret_status
FROM household_settings hs
LEFT JOIN vault.secrets vs ON vs.id = hs.immich_vault_secret_id
WHERE hs.household_id IN (
  SELECT household_id 
  FROM household_members 
  WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')
);

-- 5. Summary check (all in one)
SELECT 
  'SUMMARY' as check_type,
  (SELECT COUNT(*) FROM auth.users WHERE email = 'way@offtech.by') as user_exists,
  (SELECT COUNT(*) FROM subscriptions WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')) as has_subscription,
  (SELECT COUNT(*) FROM household_members WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')) as has_household_membership,
  (SELECT COUNT(*) FROM household_settings WHERE household_id IN (
    SELECT household_id FROM household_members WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')
  )) as has_household_settings,
  (SELECT immich_user_id FROM subscriptions WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')) as immich_user_id,
  (SELECT immich_server_url FROM household_settings WHERE household_id IN (
    SELECT household_id FROM household_members WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')
  ) LIMIT 1) as immich_server_url,
  (SELECT immich_vault_secret_id FROM household_settings WHERE household_id IN (
    SELECT household_id FROM household_members WHERE user_id = (SELECT id FROM auth.users WHERE email = 'way@offtech.by')
  ) LIMIT 1) as immich_vault_secret_id;
