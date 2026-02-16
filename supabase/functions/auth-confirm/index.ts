// Edge Function: Handle email confirmation redirect
// Detects mobile device and redirects to deep link (mykid://auth/confirm),
// or redirects desktop users to https://mykid.life/email-confirm

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const url = new URL(req.url)
  // Supabase passes token/type in query params after processing
  // Hash params are handled client-side on the redirect page
  const token = url.searchParams.get('token')
  const type = url.searchParams.get('type')
  const inviteToken = url.searchParams.get('invite_token')
  
  // Get user agent to detect mobile device
  const userAgent = req.headers.get('user-agent') || ''
  const isMobile = /iPhone|iPad|iPod|Android/i.test(userAgent)
  
  // Build deep link URL
  let deepLink = 'mykid://auth/confirm'
  const params: string[] = []
  if (token) params.push(`token=${encodeURIComponent(token)}`)
  if (type) params.push(`type=${encodeURIComponent(type)}`)
  if (inviteToken) params.push(`invite_token=${encodeURIComponent(inviteToken)}`)
  if (params.length > 0) {
    deepLink += '?' + params.join('&')
  }

  // If mobile device, redirect to deep link
  if (isMobile) {
    return new Response(null, {
      status: 302,
      headers: {
        ...corsHeaders,
        'Location': deepLink,
      },
    })
  }

  // Desktop: redirect to mykid.life email confirmation page
  // Build URL with all parameters
  let confirmUrl = 'https://mykid.life/email-confirm'
  const urlParams: string[] = []
  if (token) urlParams.push(`token=${encodeURIComponent(token)}`)
  if (type) urlParams.push(`type=${encodeURIComponent(type)}`)
  if (inviteToken) urlParams.push(`invite_token=${encodeURIComponent(inviteToken)}`)
  if (urlParams.length > 0) {
    confirmUrl += '?' + urlParams.join('&')
  }
  
  return new Response(null, {
    status: 302,
    headers: {
      ...corsHeaders,
      'Location': confirmUrl,
    },
  })
})
