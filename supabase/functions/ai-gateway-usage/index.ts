// Edge Function: Get AI Gateway usage stats for the authenticated user.
// Returns total input_tokens, output_tokens, total_tokens, and optionally per-day breakdown.

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
    if (!authHeader?.startsWith('Bearer ')) {
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

    const url = new URL(req.url)
    let breakdown = url.searchParams.get('breakdown') === 'daily'
    if (!breakdown) {
      try {
        const body = await req.json().catch(() => ({}))
        breakdown = (body as { breakdown?: boolean })?.breakdown === true
      } catch {
        // ignore
      }
    }

    // Get subscription info for limit
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    const { data: sub } = await supabaseAdmin
      .from('subscriptions')
      .select('monthly_token_limit, current_period_end, created_at')
      .eq('user_id', user.id)
      .maybeSingle()

    const monthlyLimit = (sub as { monthly_token_limit?: number } | null)?.monthly_token_limit ?? 0
    const periodEnd = (sub as { current_period_end?: string } | null)?.current_period_end
    const periodStart = periodEnd
      ? new Date(new Date(periodEnd).getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()
      : (sub as { created_at?: string } | null)?.created_at ?? new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

    const { data: rows, error } = await supabase
      .from('ai_gateway_usage')
      .select('input_tokens, output_tokens, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('ai-gateway-usage error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch usage' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const total = (rows ?? []).reduce(
      (acc, r) => ({
        input_tokens: acc.input_tokens + (r.input_tokens ?? 0),
        output_tokens: acc.output_tokens + (r.output_tokens ?? 0),
      }),
      { input_tokens: 0, output_tokens: 0 }
    )

    // Count tokens used in current period
    let periodUsedTokens = 0
    if (rows && periodEnd) {
      const periodStartTime = new Date(periodStart).getTime()
      const periodEndTime = new Date(periodEnd).getTime()
      for (const row of rows) {
        const usageTime = new Date(row.created_at).getTime()
        if (usageTime >= periodStartTime && usageTime <= periodEndTime) {
          periodUsedTokens += (row.input_tokens ?? 0) + (row.output_tokens ?? 0)
        }
      }
    } else {
      periodUsedTokens = total.input_tokens + total.output_tokens
    }

    const response: Record<string, unknown> = {
      input_tokens: total.input_tokens,
      output_tokens: total.output_tokens,
      total_tokens: total.input_tokens + total.output_tokens,
      request_count: rows?.length ?? 0,
      monthly_limit: monthlyLimit,
      period_used_tokens: periodUsedTokens,
      period_start: periodStart,
      period_end: periodEnd,
    }

    if (breakdown && rows?.length) {
      const byDay: Record<string, { input_tokens: number; output_tokens: number; request_count: number }> = {}
      for (const r of rows) {
        const date = new Date(r.created_at).toISOString().slice(0, 10)
        if (!byDay[date]) {
          byDay[date] = { input_tokens: 0, output_tokens: 0, request_count: 0 }
        }
        byDay[date].input_tokens += r.input_tokens ?? 0
        byDay[date].output_tokens += r.output_tokens ?? 0
        byDay[date].request_count += 1
      }
      response.by_day = byDay
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('ai-gateway-usage error:', error)
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
