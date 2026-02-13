// Edge Function: Create AI Gateway token for authenticated user.
// Requires: SUPABASE_SERVICE_ROLE_KEY.
// Optional: require Premium (set REQUIRE_PREMIUM=true) – if set, only premium users can create tokens.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function generateToken(): string {
  const arr = new Uint8Array(32)
  crypto.getRandomValues(arr)
  return Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('')
}

async function sha256Hex(text: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(text)
  const hash = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const requirePremium = Deno.env.get('REQUIRE_PREMIUM') === 'true'
    if (requirePremium) {
      const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )
      const { data: sub } = await supabaseAdmin
        .from('subscriptions')
        .select('plan_id, status')
        .eq('user_id', user.id)
        .maybeSingle()

      const planId = (sub as { plan_id?: string } | null)?.plan_id
      const status = (sub as { status?: string } | null)?.status
      const allowed = planId === 'premium' && (status === 'trialing' || status === 'active')

      if (!allowed) {
        return new Response(
          JSON.stringify({ error: 'Premium subscription required to create AI Gateway token' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    const plainToken = generateToken()
    const tokenHash = await sha256Hex(plainToken)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: existing } = await supabaseAdmin
      .from('ai_gateway_tokens')
      .select('id')
      .eq('user_id', user.id)
      .eq('name', 'default')
      .maybeSingle()

    let result
    if (existing) {
      result = await supabaseAdmin
        .from('ai_gateway_tokens')
        .update({ token_hash: tokenHash })
        .eq('user_id', user.id)
        .eq('name', 'default')
        .select('id')
        .single()
    } else {
      result = await supabaseAdmin
        .from('ai_gateway_tokens')
        .insert({
          user_id: user.id,
          token_hash: tokenHash,
          name: 'default',
        })
        .select('id')
        .single()
    }

    if (result.error) {
      console.error('create-gateway-token error:', result.error)
      return new Response(
        JSON.stringify({ error: 'Failed to create token' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { error: vaultErr } = await supabaseAdmin.rpc('set_ai_gateway_plain_token_for_user', {
      p_user_id: user.id,
      p_plain_token: plainToken,
    })
    if (vaultErr) {
      console.error('set_ai_gateway_plain_token_for_user error:', vaultErr)
    }

    return new Response(
      JSON.stringify({
        token: plainToken,
        message: 'Save this token securely. It will not be shown again.',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('create-gateway-token error:', error)
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
