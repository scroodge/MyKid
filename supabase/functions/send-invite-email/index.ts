// Edge Function to send household invite email
// Uses Resend API (or can be configured to use other email providers)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const APP_URL = Deno.env.get('APP_URL') || 'https://mykid.app' // Change to your app URL or deep link handler

interface InviteEmailRequest {
  email: string
  inviteToken: string
  inviteCode: string
  inviterEmail?: string
  householdName?: string
}

serve(async (req) => {
  try {
    // Verify authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify user is authenticated
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const body: InviteEmailRequest = await req.json()
    const { email, inviteToken, inviteCode, inviterEmail, householdName } = body

    if (!email || !inviteToken) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, inviteToken' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // If Resend API key is configured, send email via Resend
    if (RESEND_API_KEY) {
      const inviteLink = `${APP_URL}/invite/${inviteToken}`
      const inviteUrl = `mykid://invite/${inviteToken}`

      const emailBody = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #2563eb;">You've been invited to join a family!</h2>
          ${householdName ? `<p><strong>Family:</strong> ${householdName}</p>` : ''}
          ${inviterEmail ? `<p><strong>Invited by:</strong> ${inviterEmail}</p>` : ''}
          
          <p>Click the link below to accept the invitation and join the family:</p>
          
          <div style="margin: 30px 0;">
            <a href="${inviteUrl}" style="display: inline-block; background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 600;">
              Accept Invitation
            </a>
          </div>
          
          <p style="font-size: 14px; color: #666;">
            Or use this invite code: <strong style="font-family: monospace; font-size: 16px;">${inviteCode}</strong>
          </p>
          
          <p style="font-size: 14px; color: #666;">
            Or open this link: <a href="${inviteLink}">${inviteLink}</a>
          </p>
          
          <p style="font-size: 12px; color: #999; margin-top: 40px;">
            This invitation expires in 7 days.
          </p>
        </body>
        </html>
      `

      const resendResponse = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${RESEND_API_KEY}`,
        },
        body: JSON.stringify({
          from: 'MyKid <onboarding@resend.dev>', // Use Resend test domain for testing, or change to your verified domain
          to: [email],
          subject: householdName 
            ? `Invitation to join ${householdName} on MyKid`
            : 'Invitation to join MyKid family',
          html: emailBody,
        }),
      })

      if (!resendResponse.ok) {
        const error = await resendResponse.text()
        console.error('Resend API error:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to send email', details: error }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }

      const resendData = await resendResponse.json()
      return new Response(
        JSON.stringify({ success: true, messageId: resendData.id }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      // Fallback: return invite details (email not configured)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Email service not configured. Please share the invite link manually.',
          inviteLink: `mykid://invite/${inviteToken}`,
          inviteCode: inviteCode,
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }
  } catch (error) {
    console.error('Error sending invite email:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
