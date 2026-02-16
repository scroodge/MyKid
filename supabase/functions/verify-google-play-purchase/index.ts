// Edge Function: Verify Google Play subscription purchase and activate subscription (same as stripe-webhook flow).
// Requires: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON, GOOGLE_PLAY_PACKAGE_NAME, IMMICH_SERVER_URL, IMMICH_ADMIN_API_KEY, GATEWAY_* for Premium.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { importPKCS8, SignJWT } from 'https://esm.sh/jose@5.2.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function mapProductIdToPlanId(productId: string): 'basic' | 'premium' {
  if (productId === 'mykid_premium') return 'premium'
  return 'basic'
}

async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson) as { client_email: string; private_key: string }
  const key = await importPKCS8(sa.private_key, 'RS256')
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .setClaim('scope', 'https://www.googleapis.com/auth/androidpublisher')
    .sign(key)

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!tokenRes.ok) {
    const text = await tokenRes.text()
    throw new Error(`Google token error: ${tokenRes.status} ${text}`)
  }
  const tokenData = (await tokenRes.json()) as { access_token?: string }
  if (!tokenData.access_token) throw new Error('No access_token in Google response')
  return tokenData.access_token
}

async function getSubscriptionPurchase(
  accessToken: string,
  packageName: string,
  subscriptionId: string,
  purchaseToken: string
): Promise<{ expiryTimeMillis?: string; paymentState?: number }> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(subscriptionId)}/tokens/${encodeURIComponent(purchaseToken)}`
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Google Play API error: ${res.status} ${text}`)
  }
  return (await res.json()) as { expiryTimeMillis?: string; paymentState?: number }
}

// --- Reuse same helpers as stripe-webhook (inlined to avoid shared module dependency). ---
async function ensureHousehold(supabase: ReturnType<typeof createClient>, userId: string): Promise<string | null> {
  const { data: members } = await supabase
    .from('household_members')
    .select('household_id')
    .eq('user_id', userId)
    .limit(1)
  const first = (members as { household_id: string }[] | null)?.[0]
  if (first?.household_id) return first.household_id
  const { data: ins } = await supabase.from('households').insert({ owner_id: userId, name: 'My Family' }).select('id').single()
  const id = (ins as { id: string } | null)?.id
  if (id) {
    await supabase.from('household_members').insert({ household_id: id, user_id: userId, role: 'owner' })
    return id
  }
  return null
}

async function createImmichUserAndKey(
  baseUrl: string,
  adminApiKey: string,
  email: string,
  name: string,
  password: string,
  quotaBytes: number
): Promise<{ userId: string; apiKey: string } | null> {
  const base = baseUrl.replace(/\/$/, '')
  const createRes = await fetch(`${base}/api/admin/users`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-api-key': adminApiKey },
    body: JSON.stringify({ email, name: name || email, password, quotaSizeInBytes: quotaBytes }),
  })
  if (!createRes.ok) {
    console.error('Immich create user failed:', createRes.status, await createRes.text())
    return null
  }
  const user = (await createRes.json()) as { id: string }
  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
  if (!loginRes.ok) {
    console.error('Immich login failed:', loginRes.status, await loginRes.text())
    return null
  }
  const login = (await loginRes.json()) as { accessToken?: string }
  const token = login.accessToken
  if (!token) return null
  const keyRes = await fetch(`${base}/api/api-keys`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ name: 'MyKid managed', permissions: ['all'] }),
  })
  if (!keyRes.ok) {
    console.error('Immich create api key failed:', keyRes.status, await keyRes.text())
    return null
  }
  const keyData = (await keyRes.json()) as { secret?: string }
  const apiKey = keyData.secret
  if (!apiKey) return null
  return { userId: user.id, apiKey }
}

async function updateImmichUserQuota(
  baseUrl: string,
  adminApiKey: string,
  immichUserId: string,
  quotaBytes: number
): Promise<boolean> {
  const base = baseUrl.replace(/\/$/, '')
  const res = await fetch(`${base}/api/admin/users/${immichUserId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'x-api-key': adminApiKey },
    body: JSON.stringify({ quotaSizeInBytes: quotaBytes }),
  })
  if (!res.ok) {
    console.error('Immich update quota failed:', res.status, await res.text())
    return false
  }
  return true
}

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(text)
  const hash = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function generateToken(): string {
  const arr = new Uint8Array(32)
  crypto.getRandomValues(arr)
  return Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('')
}

async function ensureAiGatewayToken(supabase: ReturnType<typeof createClient>, userId: string): Promise<void> {
  const { data: existing } = await supabase
    .from('ai_gateway_tokens')
    .select('id')
    .eq('user_id', userId)
    .eq('name', 'default')
    .maybeSingle()
  if (existing) return

  const plainToken = generateToken()
  const tokenHash = await sha256Hex(plainToken)
  const { error: insertErr } = await supabase
    .from('ai_gateway_tokens')
    .insert({ user_id: userId, token_hash: tokenHash, name: 'default' })
  if (insertErr) {
    console.error('ai_gateway_tokens insert error:', insertErr)
    return
  }
  const { error: vaultErr } = await supabase.rpc('set_ai_gateway_plain_token_for_user', {
    p_user_id: userId,
    p_plain_token: plainToken,
  })
  if (vaultErr) console.error('set_ai_gateway_plain_token_for_user error:', vaultErr)
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabaseAuth = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } }
  )
  const { data: { user }, error: userError } = await supabaseAuth.auth.getUser()
  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const userId = user.id

  let body: { purchase_token?: string; product_id?: string }
  try {
    body = (await req.json()) as { purchase_token?: string; product_id?: string }
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const purchaseToken = body.purchase_token?.trim()
  const productId = body.product_id?.trim()
  if (!purchaseToken || !productId) {
    return new Response(JSON.stringify({ error: 'Missing purchase_token or product_id' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const planId = mapProductIdToPlanId(productId)
  const packageName = Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME')
  const saJson = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON')
  if (!packageName || !saJson) {
    return new Response(JSON.stringify({ error: 'Server misconfiguration: Google Play secrets missing' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let purchase: { expiryTimeMillis?: string; paymentState?: number }
  try {
    const accessToken = await getGoogleAccessToken(saJson)
    purchase = await getSubscriptionPurchase(accessToken, packageName, productId, purchaseToken)
  } catch (e) {
    console.error('Google Play verification failed:', e)
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : 'Verification failed' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const expiryMs = purchase.expiryTimeMillis ? Number(purchase.expiryTimeMillis) : 0
  if (expiryMs <= Date.now()) {
    return new Response(JSON.stringify({ error: 'Subscription expired or invalid' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const storageGb = planId === 'basic' ? 10 : 20
  const monthlyTokenLimit = planId === 'premium' ? 100000 : 0
  const trialEndsAt = new Date(expiryMs).toISOString()
  const currentPeriodEnd = trialEndsAt

  await supabase.from('subscriptions').upsert(
    {
      user_id: userId,
      stripe_customer_id: null,
      stripe_subscription_id: null,
      status: 'active',
      trial_ends_at: trialEndsAt,
      current_period_end: currentPeriodEnd,
      plan_id: planId,
      storage_limit_gb: storageGb,
      monthly_token_limit: monthlyTokenLimit,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'user_id' }
  )

  if (planId === 'premium') {
    await ensureAiGatewayToken(supabase, userId)
  }

  const { data: subRow } = await supabase.from('subscriptions').select('immich_user_id').eq('user_id', userId).single()
  const alreadyHasImmich = (subRow as { immich_user_id?: string } | null)?.immich_user_id
  const immichUrl = Deno.env.get('IMMICH_SERVER_URL')
  const immichAdminKey = Deno.env.get('IMMICH_ADMIN_API_KEY')

  if (alreadyHasImmich && immichUrl && immichAdminKey) {
    const quotaBytes = storageGb * 1024 * 1024 * 1024
    await updateImmichUserQuota(immichUrl, immichAdminKey, alreadyHasImmich, quotaBytes)
  } else if (immichUrl && immichAdminKey) {
    const { data: u } = await supabase.auth.admin.getUserById(userId)
    const email = (u?.user?.email ?? '') as string
    const name = (u?.user?.user_metadata?.full_name ?? u?.user?.email ?? 'User') as string
    const password = crypto.randomUUID().replace(/-/g, '') + 'A1!'
    const quotaBytes = storageGb * 1024 * 1024 * 1024
    const result = await createImmichUserAndKey(immichUrl, immichAdminKey, email, name, password, quotaBytes)
    if (result) {
      const householdId = await ensureHousehold(supabase, userId)
      if (householdId) {
        await supabase.rpc('set_household_immich_config_for_managed', {
          p_household_id: householdId,
          p_server_url: immichUrl,
          p_api_key: result.apiKey,
        })
        await supabase
          .from('subscriptions')
          .update({ immich_user_id: result.userId, updated_at: new Date().toISOString() })
          .eq('user_id', userId)
      }
    }
  }

  return new Response(JSON.stringify({ ok: true, plan_id: planId }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
