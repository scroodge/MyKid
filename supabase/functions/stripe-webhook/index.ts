// Edge Function: Stripe webhook — update subscriptions, provision/deprovision Immich, delete data on cancel.
// Requires: STRIPE_WEBHOOK_SECRET, STRIPE_SECRET_KEY, IMMICH_SERVER_URL, IMMICH_ADMIN_API_KEY, SUPABASE_SERVICE_ROLE_KEY.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

function getRawBody(req: Request): Promise<string> {
  return req.text()
}

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
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': adminApiKey,
    },
    body: JSON.stringify({
      email,
      name: name || email,
      password,
      quotaSizeInBytes: quotaBytes,
    }),
  })
  if (!createRes.ok) {
    console.error('Immich create user failed:', createRes.status, await createRes.text())
    return null
  }
  const user = await createRes.json() as { id: string }
  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
  if (!loginRes.ok) {
    console.error('Immich login failed:', loginRes.status, await loginRes.text())
    return null
  }
  const login = await loginRes.json() as { accessToken?: string }
  const token = login.accessToken
  if (!token) return null
  const keyRes = await fetch(`${base}/api/api-keys`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ name: 'MyKid managed', permissions: ['all'] }),
  })
  if (!keyRes.ok) {
    console.error('Immich create api key failed:', keyRes.status, await keyRes.text())
    return null
  }
  const keyData = await keyRes.json() as { secret?: string }
  const apiKey = keyData.secret
  if (!apiKey) return null
  return { userId: user.id, apiKey }
}

async function deleteImmichUser(baseUrl: string, adminApiKey: string, immichUserId: string): Promise<void> {
  const base = baseUrl.replace(/\/$/, '')
  await fetch(`${base}/api/admin/users/${immichUserId}`, {
    method: 'DELETE',
    headers: { 'x-api-key': adminApiKey },
  })
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

async function deleteUserData(supabase: ReturnType<typeof createClient>, userId: string): Promise<void> {
  const { data: owned } = await supabase.from('households').select('id').eq('owner_id', userId)
  const householdIds = ((owned as { id: string }[] | null) ?? []).map((r) => r.id)

  await supabase.from('journal_entries').delete().eq('user_id', userId)

  if (householdIds.length > 0) {
    const { data: childRows } = await supabase.from('children').select('id').in('household_id', householdIds)
    const childIds = ((childRows as { id: string }[] | null) ?? []).map((c) => c.id)
    if (childIds.length > 0) {
      await supabase.from('journal_entries').delete().in('child_id', childIds)
    }
    await supabase.from('children').delete().eq('user_id', userId)
    await supabase.from('children').delete().in('household_id', householdIds)
    await supabase.from('household_invites').delete().in('household_id', householdIds)
    await supabase.from('household_settings').delete().in('household_id', householdIds)
    await supabase.from('household_members').delete().in('household_id', householdIds)
    await supabase.from('households').delete().in('id', householdIds)
  } else {
    await supabase.from('children').delete().eq('user_id', userId)
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
  if (!webhookSecret || !stripeKey) {
    return new Response(JSON.stringify({ error: 'Missing secrets' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }

  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response(JSON.stringify({ error: 'Missing stripe-signature' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }

  const rawBody = await getRawBody(req)
  let event: { type: string; data: { object: Record<string, unknown> } }
  try {
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(webhookSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    const parts = signature.split(',')
    const timestamp = parts.find((p) => p.startsWith('t='))?.slice(2)
    const v1 = parts.find((p) => p.startsWith('v1='))?.slice(3)
    if (!timestamp || !v1) throw new Error('Bad signature format')
    const payload = `${timestamp}.${rawBody}`
    const sig = await crypto.subtle.sign(
      'HMAC',
      cryptoKey,
      new TextEncoder().encode(payload)
    )
    const expected = Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('')
    if (v1 !== expected) throw new Error('Signature mismatch')
    event = JSON.parse(rawBody) as { type: string; data: { object: Record<string, unknown> } }
  } catch (e) {
    console.error('Stripe webhook verify error:', e)
    return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const sub = event.data?.object as Record<string, unknown> | undefined
  const meta = (sub?.metadata as Record<string, string> | undefined) ?? {}
  const userId = meta.user_id
  const planId = (meta.plan_id as 'basic' | 'premium') || 'premium'

  if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated') {
    const status = sub?.status as string
    const customer = sub?.customer
    const customerId = typeof customer === 'string' ? customer : (customer as { id?: string } | undefined)?.id ?? ''
    const subId = sub?.id as string
    const trialEnd = sub?.trial_end as number | undefined
    const periodEnd = sub?.current_period_end as number | undefined
    const trialEndAt = trialEnd ? new Date(trialEnd * 1000).toISOString() : null
    const periodEndAt = periodEnd ? new Date(periodEnd * 1000).toISOString() : null
    const storageGb = planId === 'basic' ? 10 : 20

    await supabase.from('subscriptions').upsert(
      {
        user_id: userId,
        stripe_customer_id: customerId,
        stripe_subscription_id: subId,
        status: status === 'trialing' ? 'trialing' : status === 'active' ? 'active' : status === 'past_due' ? 'past_due' : 'canceled',
        trial_ends_at: trialEndAt,
        current_period_end: periodEndAt,
        plan_id: planId,
        storage_limit_gb: storageGb,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' }
    )

    const { data: subRow } = await supabase.from('subscriptions').select('immich_user_id').eq('user_id', userId).single()
    const alreadyHasImmich = (subRow as { immich_user_id?: string } | null)?.immich_user_id

    if (status === 'trialing' || status === 'active') {
      if (planId === 'premium' && userId) {
        await ensureAiGatewayToken(supabase, userId)
      }
      if (!alreadyHasImmich) {
        const immichUrl = Deno.env.get('IMMICH_SERVER_URL')
        const immichAdminKey = Deno.env.get('IMMICH_ADMIN_API_KEY')
        if (immichUrl && immichAdminKey && userId) {
          const { data: u } = await supabase.auth.admin.getUserById(userId)
          const email = (u?.user?.email ?? meta.email) as string
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
              await supabase.from('subscriptions').update({ immich_user_id: result.userId, updated_at: new Date().toISOString() }).eq('user_id', userId)
            }
          }
        }
      }
    }
  }

  if (event.type === 'customer.subscription.deleted' || (event.type === 'customer.subscription.updated' && ((sub?.status as string) === 'canceled' || (sub?.status as string) === 'expired'))) {
    const uid = userId as string
    if (uid) {
      const { data: row } = await supabase.from('subscriptions').select('immich_user_id').eq('user_id', uid).single()
      const immichUserId = (row as { immich_user_id?: string } | null)?.immich_user_id
      await supabase.from('subscriptions').update({ status: 'expired', updated_at: new Date().toISOString() }).eq('user_id', uid)
      await deleteUserData(supabase, uid)
      const baseUrl = Deno.env.get('IMMICH_SERVER_URL')
      const adminKey = Deno.env.get('IMMICH_ADMIN_API_KEY')
      if (baseUrl && adminKey && immichUserId) {
        await deleteImmichUser(baseUrl, adminKey, immichUserId)
      }
    }
  }

  return new Response(JSON.stringify({ received: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
})
