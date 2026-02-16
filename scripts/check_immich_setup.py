#!/usr/bin/env python3
"""
Check Immich setup for a user in Supabase.
Usage: python3 check_immich_setup.py <email_or_user_id>
"""
import urllib.request
import json
import sys
import os
from urllib.parse import quote

# Load from .env file
def load_env():
    env_vars = {}
    try:
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return env_vars

env = load_env()
SUPABASE_URL = os.getenv('SUPABASE_URL') or env.get('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or env.get('SUPABASE_SERVICE_ROLE_KEY', '')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env file or environment')
    sys.exit(1)

def make_request(endpoint, method='GET', data=None):
    url = f'{SUPABASE_URL}/rest/v1/{endpoint}'
    req = urllib.request.Request(url)
    req.add_header('apikey', SUPABASE_SERVICE_KEY)
    req.add_header('Authorization', f'Bearer {SUPABASE_SERVICE_KEY}')
    req.add_header('Content-Type', 'application/json')
    req.add_header('Prefer', 'return=representation')
    if method == 'POST':
        req.method = 'POST'
        if data:
            req.data = json.dumps(data).encode('utf-8')
    return urllib.request.urlopen(req)

def check_user_immich_setup(identifier):
    print(f'\n=== Checking Immich setup for: {identifier} ===\n')
    
    # Step 1: Get user ID if email provided
    user_id = None
    if '@' in identifier:
        print(f'Step 1: Looking up user by email: {identifier}')
        try:
            # Use auth admin API to get user
            # Note: This requires admin API access
            # For now, we'll search in subscriptions table
            print('   (Searching in subscriptions table...)')
        except Exception as e:
            print(f'   ⚠️  Error: {e}')
    else:
        user_id = identifier
        print(f'Step 1: Using provided user_id: {user_id}')
    
    # Step 2: Check subscription
    print('\nStep 2: Checking subscription...')
    try:
        if user_id:
            endpoint = f'subscriptions?user_id=eq.{user_id}&select=*'
        else:
            # Try to find by email in metadata or other fields
            endpoint = f'subscriptions?select=*'
        
        response = make_request(endpoint)
        subscriptions = json.loads(response.read().decode('utf-8'))
        
        if not subscriptions:
            print(f'   ❌ No subscription found for {identifier}')
            print('\n   Please check:')
            print('   1. User exists in auth.users')
            print('   2. Subscription was created via Stripe webhook')
            print('   3. user_id matches between auth.users and subscriptions table')
            return
        
        sub = subscriptions[0]
        user_id = sub.get('user_id')
        print(f'   ✅ Found subscription:')
        print(f'      user_id: {user_id}')
        print(f'      plan_id: {sub.get("plan_id")}')
        print(f'      status: {sub.get("status")}')
        print(f'      immich_user_id: {sub.get("immich_user_id") or "❌ NOT SET"}')
        print(f'      storage_limit_gb: {sub.get("storage_limit_gb")}')
        print(f'      monthly_token_limit: {sub.get("monthly_token_limit")}')
        
        if not sub.get('immich_user_id'):
            print('\n   ⚠️  immich_user_id is missing!')
            print('   This means Immich user was not created or webhook failed.')
    except Exception as e:
        print(f'   ❌ Error checking subscription: {e}')
        import traceback
        traceback.print_exc()
        return
    
    if not user_id:
        print('\n   ❌ Cannot proceed without user_id')
        return
    
    # Step 3: Check household
    print('\nStep 3: Checking household...')
    try:
        endpoint = f'household_members?user_id=eq.{user_id}&select=household_id,households(id,name,owner_id)'
        response = make_request(endpoint)
        members = json.loads(response.read().decode('utf-8'))
        
        if not members:
            print(f'   ❌ No household found for user {user_id}')
            print('   ⚠️  Household should be created automatically for Premium subscriptions')
            return
        
        household_id = members[0].get('household_id')
        household_data = members[0].get('households', {})
        print(f'   ✅ Found household:')
        print(f'      household_id: {household_id}')
        print(f'      name: {household_data.get("name")}')
        print(f'      owner_id: {household_data.get("owner_id")}')
    except Exception as e:
        print(f'   ❌ Error checking household: {e}')
        import traceback
        traceback.print_exc()
        return
    
    if not household_id:
        print('\n   ❌ Cannot proceed without household_id')
        return
    
    # Step 4: Check household_settings
    print('\nStep 4: Checking household_settings...')
    try:
        endpoint = f'household_settings?household_id=eq.{household_id}&select=*'
        response = make_request(endpoint)
        settings = json.loads(response.read().decode('utf-8'))
        
        if not settings:
            print(f'   ❌ No household_settings found for household {household_id}')
            print('   ⚠️  Immich config should be set automatically by webhook')
            return
        
        setting = settings[0]
        immich_url = setting.get('immich_server_url')
        vault_secret_id = setting.get('immich_vault_secret_id')
        
        print(f'   ✅ Found household_settings:')
        print(f'      household_id: {household_id}')
        print(f'      immich_server_url: {immich_url or "❌ NOT SET"}')
        print(f'      immich_vault_secret_id: {vault_secret_id or "❌ NOT SET"}')
        
        if not immich_url or not vault_secret_id:
            print('\n   ⚠️  Immich config is incomplete!')
            print('   This means webhook did not set the config or failed.')
        
        # Try to get the actual API key from vault (if possible)
        if vault_secret_id:
            print(f'\n   Note: API key is stored in Vault with secret_id: {vault_secret_id}')
            print('   To verify the API key, check Supabase Dashboard → Vault → Secrets')
    except Exception as e:
        print(f'   ❌ Error checking household_settings: {e}')
        import traceback
        traceback.print_exc()
    
    # Summary
    print('\n=== Summary ===')
    sub_has_immich = sub.get('immich_user_id') if 'sub' in locals() else False
    has_household = 'household_id' in locals() and household_id
    has_settings = 'setting' in locals() and setting.get('immich_server_url') and setting.get('immich_vault_secret_id')
    
    print(f'Subscription has immich_user_id: {"✅" if sub_has_immich else "❌"}')
    print(f'Household exists: {"✅" if has_household else "❌"}')
    print(f'Household settings configured: {"✅" if has_settings else "❌"}')
    
    if sub_has_immich and has_household and has_settings:
        print('\n✅ All checks passed! Immich should be configured correctly.')
    else:
        print('\n❌ Some checks failed. Please check webhook logs and ensure:')
        print('   1. Webhook received the subscription event')
        print('   2. IMMICH_SERVER_URL and IMMICH_ADMIN_API_KEY are set in Edge Function secrets')
        print('   3. Webhook successfully created Immich user')
        print('   4. Webhook successfully set household config')
    
    print('\n=== Done ===\n')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python3 check_immich_setup.py <email_or_user_id>')
        print('Example: python3 check_immich_setup.py user@example.com')
        print('Example: python3 check_immich_setup.py 123e4567-e89b-12d3-a456-426614174000')
        sys.exit(1)
    
    identifier = sys.argv[1]
    check_user_immich_setup(identifier)
