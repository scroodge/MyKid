// Edge Function: Create Stripe Checkout Session for subscription trial (7 days).
// Requires: STRIPE_SECRET_KEY, STRIPE_PRICE_BASIC, STRIPE_PRICE_PREMIUM, APP_URL (success/cancel base).

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

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    const priceBasic = Deno.env.get('STRIPE_PRICE_BASIC')
    const pricePremium = Deno.env.get('STRIPE_PRICE_PREMIUM')
    const appUrl = Deno.env.get('APP_URL') || 'https://mykid.app'

    if (!stripeKey || !priceBasic || !pricePremium) {
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!user.email) {
      return new Response(
        JSON.stringify({ error: 'Email required for checkout' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let planId = 'premium'
    if (req.method === 'POST') {
      try {
        const body = await req.json()
        if (body.plan_id === 'basic' || body.plan_id === 'premium') planId = body.plan_id
      } catch {
        // keep default
      }
    }
    const priceId = planId === 'basic' ? priceBasic : pricePremium

    // Support deeplink (APP_URL=mykid://) so Stripe redirect opens the app; else use https base
    const isDeeplink = /^[a-z][a-z0-9+.-]*:\/\//i.test(appUrl) && !appUrl.startsWith('http')
    const base = appUrl.replace(/\/$/, '')
    const successUrl = isDeeplink
      ? `${base}subscription-success?session_id={CHECKOUT_SESSION_ID}`
      : `${base}/subscription-success?session_id={CHECKOUT_SESSION_ID}`
    const cancelUrl = isDeeplink ? `${base}subscription-cancel` : `${base}/subscription-cancel`

    const params = new URLSearchParams({
      mode: 'subscription',
      'line_items[0][price]': priceId,
      'line_items[0][quantity]': '1',
      'subscription_data[trial_period_days]': '7',
      'subscription_data[metadata][user_id]': user.id,
      'subscription_data[metadata][plan_id]': planId,
      success_url: successUrl,
      cancel_url: cancelUrl,
      'customer_email': user.email,
      'metadata[user_id]': user.id,
      'metadata[plan_id]': planId,
    })

    const stripeRes = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    })

    if (!stripeRes.ok) {
      const errText = await stripeRes.text()
      console.error('Stripe error:', errText)
      return new Response(
        JSON.stringify({ error: 'Failed to create checkout session', details: errText }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const session = await stripeRes.json()
    const url = session.url
    if (!url) {
      return new Response(
        JSON.stringify({ error: 'No checkout URL returned' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ url, session_id: session.id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('create-checkout error:', error)
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    )
  }
})
