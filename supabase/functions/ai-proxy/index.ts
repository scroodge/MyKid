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
      .select('plan_id, status, monthly_token_limit, current_period_end, created_at')
      .eq('user_id', user.id)
      .maybeSingle()

    const planId = (sub as { plan_id?: string } | null)?.plan_id
    const status = (sub as { status?: string } | null)?.status
    let allowed = planId === 'premium' && (status === 'trialing' || status === 'active')
    let tokenUserId = user.id // user whose token to use (self or premium household member)
    let subscriptionPeriodEnd = (sub as { current_period_end?: string } | null)?.current_period_end
    let subscriptionCreatedAt = (sub as { created_at?: string } | null)?.created_at

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
            // Get subscription period for the premium member
            const { data: premiumSub } = await supabaseAdmin
              .from('subscriptions')
              .select('current_period_end, created_at')
              .eq('user_id', premiumMember.user_id)
              .maybeSingle()
            subscriptionPeriodEnd = (premiumSub as { current_period_end?: string } | null)?.current_period_end
            subscriptionCreatedAt = (premiumSub as { created_at?: string } | null)?.created_at
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

    // Check token limit for the user whose token we're using
    const { data: tokenUserSub } = await supabaseAdmin
      .from('subscriptions')
      .select('monthly_token_limit, current_period_end, created_at')
      .eq('user_id', tokenUserId)
      .maybeSingle()

    const monthlyLimit = (tokenUserSub as { monthly_token_limit?: number } | null)?.monthly_token_limit ?? 0
    if (monthlyLimit > 0) {
      const periodEnd = (tokenUserSub as { current_period_end?: string } | null)?.current_period_end
      const periodStart = periodEnd
        ? new Date(periodEnd).getTime() - 30 * 24 * 60 * 60 * 1000 // 30 days before period_end
        : (tokenUserSub as { created_at?: string } | null)?.created_at
        ? new Date((tokenUserSub as { created_at?: string }).created_at!).getTime()
        : Date.now() - 30 * 24 * 60 * 60 * 1000

      const periodEndTime = periodEnd ? new Date(periodEnd).getTime() : Date.now() + 30 * 24 * 60 * 60 * 1000
      const now = Date.now()

      // Count tokens used in current period
      const { data: usageRows } = await supabaseAdmin
        .from('ai_gateway_usage')
        .select('input_tokens, output_tokens, created_at')
        .eq('user_id', tokenUserId)
        .gte('created_at', new Date(Math.max(periodStart, now - 90 * 24 * 60 * 60 * 1000)).toISOString()) // Last 90 days max

      let usedTokens = 0
      if (usageRows) {
        for (const row of usageRows) {
          const usageTime = new Date(row.created_at).getTime()
          if (usageTime >= periodStart && usageTime <= periodEndTime) {
            usedTokens += (row.input_tokens ?? 0) + (row.output_tokens ?? 0)
          }
        }
      }

      if (usedTokens >= monthlyLimit) {
        const resetDate = periodEnd ? new Date(periodEnd).toISOString() : null
        return new Response(
          JSON.stringify({
            error: 'Monthly token limit exceeded',
            limit: monthlyLimit,
            used: usedTokens,
            reset_at: resetDate,
          }),
          {
            status: 429,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
              'Retry-After': resetDate ? Math.ceil((new Date(resetDate).getTime() - now) / 1000).toString() : '3600',
            },
          }
        )
      }
    }

    let gatewayUrl = (Deno.env.get('GATEWAY_URL') ?? '').replace(/\s/g, '').trim()
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

    const base = gatewayUrl.replace(/\/$/, '').trim()
    const url = useGateway
      ? `${base}/v1/chat/completions`
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
