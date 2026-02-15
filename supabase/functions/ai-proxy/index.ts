// Edge Function: AI proxy for Premium subscribers. Verifies JWT and plan_id=premium (own or household), then forwards to your AI Gateway.
// Requires: PUBLISHABLE_KEY (user verification), SUPABASE_SERVICE_ROLE_KEY (subscription/DB), and either GATEWAY_URL+GATEWAY_TOKEN or OPENAI_API_KEY.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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

    const publishableKey = Deno.env.get('PUBLISHABLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      publishableKey,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

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
    let allowed = planId === 'premium' && (status === 'trialing' || status === 'active')
    let tokenUserId = user.id // user whose token to use (self or premium household member)

    if (!allowed) {
      // Check if any household member has premium (family sharing)
      const { data: members } = await supabaseAdmin
        .from('household_members')
        .select('household_id')
        .eq('user_id', user.id)
        .limit(1)
      const householdId = (members as { household_id: string }[] | null)?.[0]?.household_id
      if (householdId) {
        const { data: householdMemberIds } = await supabaseAdmin
          .from('household_members')
          .select('user_id')
          .eq('household_id', householdId)
        const userIds = ((householdMemberIds as { user_id: string }[] | null) ?? []).map((r) => r.user_id)
        if (userIds.length > 0) {
          const { data: householdSubs } = await supabaseAdmin
            .from('subscriptions')
            .select('user_id')
            .in('user_id', userIds)
            .eq('plan_id', 'premium')
            .in('status', ['trialing', 'active'])
            .limit(1)
          const premiumMember = (householdSubs as { user_id: string }[] | null)?.[0]
          if (premiumMember) {
            allowed = true
            tokenUserId = premiumMember.user_id
          }
        }
      }
    }

    if (!allowed) {
      return new Response(
        JSON.stringify({ error: 'Premium subscription required for AI features' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let gatewayUrl = (Deno.env.get('GATEWAY_URL') ?? '').trim()
    if (gatewayUrl && !/^https?:\/\//i.test(gatewayUrl)) {
      gatewayUrl = `https://${gatewayUrl.replace(/^\/*/, '')}`
    }
    const sharedGatewayToken = Deno.env.get('GATEWAY_TOKEN')
    const openaiKey = Deno.env.get('OPENAI_API_KEY')

    let gatewayToken = sharedGatewayToken
    if (gatewayUrl) {
      const { data: perUserToken } = await supabaseAdmin.rpc('get_ai_gateway_plain_token_for_user', { p_user_id: tokenUserId })
      if (perUserToken && typeof perUserToken === 'string' && perUserToken.trim().length > 0) {
        gatewayToken = perUserToken.trim()
      }
    }

    const useGateway = gatewayUrl && gatewayToken
    const useDirectOpenAI = openaiKey && !useGateway

    if (!useGateway && !useDirectOpenAI) {
      return new Response(
        JSON.stringify({ error: 'AI service not configured (set GATEWAY_URL+GATEWAY_TOKEN or OPENAI_API_KEY)' }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let body: Record<string, unknown>
    try {
      body = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const url = useGateway
      ? `${gatewayUrl.replace(/\/$/, '').trim()}/v1/chat/completions`
      : 'https://api.openai.com/v1/chat/completions'
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    }
    if (useGateway) {
      headers['X-Gateway-Token'] = gatewayToken
    } else {
      headers['Authorization'] = `Bearer ${openaiKey}`
    }

    const res = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    })

    const text = await res.text()
    return new Response(text, {
      status: res.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('ai-proxy error:', error)
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    )
  }
})
