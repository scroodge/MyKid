// Edge Function: Create Stripe Customer Portal session for subscription management (cancel, change plan, payment).
// Requires: STRIPE_SECRET_KEY, APP_URL (return URL after portal).

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

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    let returnUrl = (Deno.env.get('APP_URL') || 'https://mykid.life').trim()
    if (returnUrl && !/^[a-z][a-z0-9+.-]*:\/\//i.test(returnUrl)) {
      returnUrl = returnUrl.startsWith('//') ? `https:${returnUrl}` : `https://${returnUrl}`
    }
    if (returnUrl.endsWith('/')) returnUrl = returnUrl.slice(0, -1)
    // Stripe portal requires https return_url; use web URL for non-https (e.g. mykid://)
    if (!/^https:\/\//i.test(returnUrl)) {
      returnUrl = 'https://mykid.life'
    }
    returnUrl = `${returnUrl}/subscription`

    if (!stripeKey) {
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data: subRow, error: subError } = await supabase
      .from('subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', user.id)
      .maybeSingle()

    if (subError) {
      console.error('subscriptions select error:', subError)
      return new Response(
        JSON.stringify({ error: 'Failed to load subscription' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const customerId = (subRow as { stripe_customer_id?: string } | null)?.stripe_customer_id
    if (!customerId || customerId.trim() === '') {
      return new Response(
        JSON.stringify({ error: 'No subscription to manage' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = new URLSearchParams()
    body.set('customer', customerId)
    body.set('return_url', returnUrl)

    const stripeRes = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.toString(),
    })

    if (!stripeRes.ok) {
      const errText = await stripeRes.text()
      console.error('Stripe portal session error:', stripeRes.status, errText)
      return new Response(
        JSON.stringify({ error: 'Could not open subscription management' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const session = (await stripeRes.json()) as { url?: string }
    const url = session?.url
    console.log('portal session url:', url ?? '(none)')
    if (!url) {
      return new Response(
        JSON.stringify({ error: 'No portal URL returned' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ url }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('create-portal-session error:', error)
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
