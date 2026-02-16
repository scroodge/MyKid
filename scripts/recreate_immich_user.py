#!/usr/bin/env python3
"""
Utility script to recreate an Immich user with the same email.
This script:
1. Finds and restores the deleted user (if exists)
2. Changes their email to a temporary one
3. Deletes them
4. Creates a new user with the original email
"""
import urllib.request
import json
import sys
import uuid
from datetime import datetime

IMMICH_SERVER_URL = 'https://immich.mykid.life'
IMMICH_ADMIN_API_KEY = 'lkBMoHUGJvfoEeY12dARkf55ZrTKBQU5Hd5H1kk3I'

def make_request(url, method='GET', data=None):
    req = urllib.request.Request(url)
    req.add_header('x-api-key', IMMICH_ADMIN_API_KEY)
    req.add_header('Content-Type', 'application/json')
    if method == 'POST':
        req.method = 'POST'
        if data:
            req.data = json.dumps(data).encode('utf-8')
    elif method == 'PUT':
        req.method = 'PUT'
        if data:
            req.data = json.dumps(data).encode('utf-8')
    elif method == 'DELETE':
        req.method = 'DELETE'
    return urllib.request.urlopen(req)

def find_user_by_email(email, include_deleted=True):
    """Find user by email, optionally including deleted users."""
    try:
        url = f'{IMMICH_SERVER_URL}/api/admin/users'
        if include_deleted:
            url += '?withDeleted=true'
        response = make_request(url)
        users_data = json.loads(response.read().decode('utf-8'))
        users = users_data if isinstance(users_data, list) else users_data.get('users', [])
        return next((u for u in users if u.get('email') == email), None)
    except Exception as e:
        print(f'   ❌ Error finding user: {e}')
        return None

def restore_user(user_id):
    """Restore a deleted user."""
    try:
        restore_url = f'{IMMICH_SERVER_URL}/api/admin/users/{user_id}/restore'
        restore_req = urllib.request.Request(restore_url, method='POST')
        restore_req.add_header('x-api-key', IMMICH_ADMIN_API_KEY)
        restore_req.add_header('Content-Type', 'application/json')
        restore_response = urllib.request.urlopen(restore_req)
        return restore_response.status in [200, 201, 204]
    except Exception as e:
        print(f'   ⚠️  Restore error: {e}')
        return False

def update_user_email(user_id, new_email):
    """Update user's email."""
    try:
        update_data = {'email': new_email}
        update_req = urllib.request.Request(f'{IMMICH_SERVER_URL}/api/admin/users/{user_id}', method='PUT')
        update_req.add_header('x-api-key', IMMICH_ADMIN_API_KEY)
        update_req.add_header('Content-Type', 'application/json')
        update_req.data = json.dumps(update_data).encode('utf-8')
        update_response = urllib.request.urlopen(update_req)
        return json.loads(update_response.read().decode('utf-8'))
    except Exception as e:
        print(f'   ❌ Error updating email: {e}')
        return None

def delete_user(user_id):
    """Delete a user (soft delete)."""
    try:
        delete_req = urllib.request.Request(f'{IMMICH_SERVER_URL}/api/admin/users/{user_id}', method='DELETE')
        delete_req.add_header('x-api-key', IMMICH_ADMIN_API_KEY)
        delete_response = urllib.request.urlopen(delete_req)
        return delete_response.status in [200, 204]
    except urllib.error.HTTPError as e:
        if e.code == 400:
            # User already deleted or not found
            return True
        return False
    except Exception as e:
        print(f'   ⚠️  Delete error: {e}')
        return False

def create_user(email, name=None, quota_gb=10):
    """Create a new user."""
    try:
        if not name:
            name = email.split('@')[0]
        password = str(uuid.uuid4()).replace('-', '') + 'A1!'
        
        create_data = {
            'email': email,
            'name': name,
            'password': password,
            'quotaSizeInBytes': quota_gb * 1024 * 1024 * 1024
        }
        
        create_req = urllib.request.Request(f'{IMMICH_SERVER_URL}/api/admin/users', method='POST')
        create_req.add_header('x-api-key', IMMICH_ADMIN_API_KEY)
        create_req.add_header('Content-Type', 'application/json')
        create_req.data = json.dumps(create_data).encode('utf-8')
        
        create_response = urllib.request.urlopen(create_req)
        return json.loads(create_response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        response_text = e.read().decode('utf-8')
        try:
            error_data = json.loads(response_text)
            error_message = error_data.get('message', response_text)
        except:
            error_message = response_text
        print(f'   ❌ Cannot create user: {e.code} - {error_message}')
        return None
    except Exception as e:
        print(f'   ❌ Error creating user: {e}')
        return None

def recreate_user(email, name=None, quota_gb=10):
    """Recreate a user with the same email."""
    print(f'\n=== Recreating Immich user: {email} ===\n')
    
    # Step 1: Find existing user (including deleted)
    print('Step 1: Finding existing user...')
    existing_user = find_user_by_email(email, include_deleted=True)
    
    if existing_user:
        user_id = existing_user.get('id')
        is_deleted = bool(existing_user.get('deletedAt'))
        print(f'   Found user: ID={user_id}, Deleted={is_deleted}')
        
        # Step 2: Restore if deleted
        if is_deleted:
            print('\nStep 2: Restoring deleted user...')
            if restore_user(user_id):
                print('   ✅ User restored')
            else:
                print('   ❌ Failed to restore user')
                return None
        
        # Step 3: Change email to temporary one
        print('\nStep 3: Changing email to temporary one...')
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        temp_email = f'deleted_{timestamp}_{user_id[:8]}@temp.immich'
        updated_user = update_user_email(user_id, temp_email)
        if updated_user:
            print(f'   ✅ Email changed to: {temp_email}')
        else:
            print('   ❌ Failed to change email')
            return None
        
        # Step 4: Delete the user
        print('\nStep 4: Deleting user with temporary email...')
        if delete_user(user_id):
            print('   ✅ User deleted')
        else:
            print('   ⚠️  Delete may have failed, but continuing...')
    
    # Step 5: Create new user with original email
    print(f'\nStep 5: Creating new user with email: {email}...')
    new_user = create_user(email, name, quota_gb)
    if new_user:
        print(f'   ✅ User created successfully!')
        print(f'   ID: {new_user.get("id")}')
        print(f'   Email: {new_user.get("email")}')
        print(f'   Name: {new_user.get("name")}')
        return new_user
    else:
        print('   ❌ Failed to create new user')
        return None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python3 recreate_immich_user.py <email> [name] [quota_gb]')
        print('Example: python3 recreate_immich_user.py wa@offtech.by "Test User" 10')
        sys.exit(1)
    
    email = sys.argv[1]
    name = sys.argv[2] if len(sys.argv) > 2 else None
    quota_gb = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    
    result = recreate_user(email, name, quota_gb)
    
    if result:
        print('\n=== Success ===')
        sys.exit(0)
    else:
        print('\n=== Failed ===')
        sys.exit(1)
