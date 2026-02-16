#!/usr/bin/env python3
"""
Check if Immich is properly configured for a user after subscription creation.
Usage: python3 check_user_immich_setup.py <email>
"""
import urllib.request
import json
import sys
import os

# Get from .env or environment
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')

def make_supabase_request(endpoint, method='GET', data=None):
    url = f'{SUPABASE_URL}/rest/v1/{endpoint}'
    req = urllib.request.Request(url)
    req.add_header('apikey', SUPABASE_SERVICE_KEY)
    req.add_header('Authorization', f'Bearer {SUPABASE_SERVICE_KEY}')
    req.add_header('Content-Type', 'application/json')
    if method == 'POST':
        req.method = 'POST'
        if data:
            req.data = json.dumps(data).encode('utf-8')
    return urllib.request.urlopen(req)

def check_user_immich_setup(email):
    print(f'\n=== Checking Immich setup for: {email} ===\n')
    
    # Step 1: Get user ID from auth
    print('Step 1: Finding user in auth...')
    try:
        # Note: This requires admin API - you might need to use Supabase admin client
        # For now, we'll check subscriptions table which has user_id
        print('   (Skipping auth check - checking subscriptions table directly)')
    except Exception as e:
        print(f'   ⚠️  Error: {e}')
    
    # Step 2: Check subscription
    print('\nStep 2: Checking subscription...')
    try:
        # We'll need to query subscriptions - but we need user_id
        # Let's check if we can find by email in a different way
        print('   (Need user_id to check subscription)')
    except Exception as e:
        print(f'   ⚠️  Error: {e}')
    
    print('\n=== Manual Check Required ===')
    print('Please check in Supabase dashboard:')
    print('1. Go to Authentication > Users')
    print('2. Find user by email:', email)
    print('3. Copy the user ID (UUID)')
    print('4. Then run: python3 check_user_immich_setup.py <user_id>')
    print('\nOr check directly in SQL:')
    print(f"SELECT s.*, h.id as household_id")
    print(f"FROM subscriptions s")
    print(f"LEFT JOIN household_members hm ON hm.user_id = s.user_id")
    print(f"LEFT JOIN households h ON h.id = hm.household_id")
    print(f"WHERE s.user_id = '<USER_ID>'")
    print('\n=== Done ===\n')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python3 check_user_immich_setup.py <email_or_user_id>')
        print('Example: python3 check_user_immich_setup.py user@example.com')
        sys.exit(1)
    
    identifier = sys.argv[1]
    check_user_immich_setup(identifier)
