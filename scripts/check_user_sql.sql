-- Check Immich setup for user way@offtech.by
-- This query checks subscription, household, and household_settings

WITH user_info AS (
  SELECT 
    id as user_id,
    email
  FROM auth.users
  WHERE email = 'way@offtech.by'
)
SELECT 
  -- User info
  ui.email,
  ui.user_id,
  
  -- Subscription info
  s.plan_id,
  s.status as subscription_status,
  s.immich_user_id,
  s.storage_limit_gb,
  s.monthly_token_limit,
  s.created_at as subscription_created_at,
  s.updated_at as subscription_updated_at,
  
  -- Household info
  h.id as household_id,
  h.name as household_name,
  h.owner_id as household_owner_id,
  
  -- Household settings info
  hs.immich_server_url,
  hs.immich_vault_secret_id,
  hs.updated_at as settings_updated_at,
  
  -- Summary flags
  CASE WHEN s.immich_user_id IS NOT NULL THEN '✅' ELSE '❌' END as has_immich_user_id,
  CASE WHEN h.id IS NOT NULL THEN '✅' ELSE '❌' END as has_household,
  CASE WHEN hs.immich_server_url IS NOT NULL AND hs.immich_vault_secret_id IS NOT NULL THEN '✅' ELSE '❌' END as has_immich_config

FROM user_info ui
LEFT JOIN subscriptions s ON s.user_id = ui.user_id
LEFT JOIN household_members hm ON hm.user_id = ui.user_id
LEFT JOIN households h ON h.id = hm.household_id
LEFT JOIN household_settings hs ON hs.household_id = h.id;
