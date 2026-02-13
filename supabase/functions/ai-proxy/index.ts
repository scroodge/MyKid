// Edge Function: AI proxy for Premium subscribers. Verifies JWT and plan_id=premium, then forwards to your AI Gateway.
// Requires: GATEWAY_URL, GATEWAY_TOKEN (or legacy OPENAI_API_KEY for direct OpenAI), SUPABASE_SERVICE_ROLE_KEY.

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
        JSON.stringify({ error: 'Premium subscription required for AI features' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const gatewayUrl = Deno.env.get('GATEWAY_URL')
    const sharedGatewayToken = Deno.env.get('GATEWAY_TOKEN')
    const openaiKey = Deno.env.get('OPENAI_API_KEY')

    let gatewayToken = sharedGatewayToken
    if (gatewayUrl) {
      const { data: perUserToken } = await supabaseAdmin.rpc('get_ai_gateway_plain_token_for_user', { p_user_id: user.id })
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
      ? `${gatewayUrl.replace(/\/$/, '')}/v1/chat/completions`
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
