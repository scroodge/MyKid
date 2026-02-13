// Edge Function: Handle email confirmation redirect
// Detects mobile device and redirects to deep link, or shows instructions for desktop

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
  // Supabase may pass token/type in query params or hash (after #)
  // We'll handle both cases
  const token = url.searchParams.get('token') || url.hash.match(/token=([^&]+)/)?.[1]
  const type = url.searchParams.get('type') || url.hash.match(/type=([^&]+)/)?.[1]
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

  // Desktop: show HTML page with instructions and JavaScript to handle hash params
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Confirmation - MyKid</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #333;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 40px;
      max-width: 500px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      text-align: center;
    }
    h1 {
      margin-top: 0;
      color: #667eea;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 20px;
    }
    .instructions {
      text-align: left;
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }
    .instructions ol {
      margin: 0;
      padding-left: 20px;
    }
    .instructions li {
      margin: 10px 0;
    }
    .deep-link {
      display: inline-block;
      margin-top: 20px;
      padding: 12px 24px;
      background: #667eea;
      color: white;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
    }
    .deep-link:hover {
      background: #5568d3;
    }
    .loading {
      display: none;
      margin-top: 20px;
    }
  </style>
  <script>
    // Parse hash parameters (Supabase may pass token via hash)
    function parseHash() {
      const hash = window.location.hash.substring(1);
      const params = {};
      hash.split('&').forEach(param => {
        const [key, value] = param.split('=');
        if (key && value) {
          params[key] = decodeURIComponent(value);
        }
      });
      return params;
    }
    
    // Build deep link from URL params and hash
    function buildDeepLink() {
      const urlParams = new URLSearchParams(window.location.search);
      const hashParams = parseHash();
      
      let deepLink = 'mykid://auth/confirm';
      const params = [];
      
      // Add token from hash or query
      const token = hashParams.token || urlParams.get('token');
      if (token) params.push('token=' + encodeURIComponent(token));
      
      // Add type from hash or query
      const type = hashParams.type || urlParams.get('type');
      if (type) params.push('type=' + encodeURIComponent(type));
      
      // Add invite_token from query
      const inviteToken = urlParams.get('invite_token');
      if (inviteToken) params.push('invite_token=' + encodeURIComponent(inviteToken));
      
      if (params.length > 0) {
        deepLink += '?' + params.join('&');
      }
      
      return deepLink;
    }
    
    // Check if mobile device
    function isMobile() {
      return /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    }
    
    // Try to open deep link
    function openDeepLink() {
      const deepLink = buildDeepLink();
      document.getElementById('deep-link-btn').href = deepLink;
      
      // If mobile, try to redirect immediately
      if (isMobile()) {
        window.location.href = deepLink;
      }
    }
    
    // Run on page load
    window.addEventListener('load', openDeepLink);
    // Also check hash changes (in case Supabase redirects with hash)
    window.addEventListener('hashchange', openDeepLink);
  </script>
</head>
<body>
  <div class="container">
    <div class="icon">📱</div>
    <h1>Email Confirmed!</h1>
    <p>Your email has been successfully confirmed.</p>
    
    <div class="instructions">
      <p><strong>To complete setup, open this link on your mobile device:</strong></p>
      <ol>
        <li>Open this email on your phone</li>
        <li>Tap the confirmation link</li>
        <li>The MyKid app will open automatically</li>
      </ol>
    </div>
    
    <p>Or click the button below if you're on a mobile device:</p>
    <a href="#" id="deep-link-btn" class="deep-link" onclick="openDeepLink(); return false;">Open MyKid App</a>
    
    <div class="loading" id="loading">
      <p>Opening MyKid app...</p>
    </div>
    
    <p style="margin-top: 30px; font-size: 14px; color: #666;">
      If the app doesn't open, make sure MyKid is installed on your device.
    </p>
  </div>
</body>
</html>`

  return new Response(html, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
    },
  })
})
