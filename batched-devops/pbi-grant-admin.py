import requests
import json
import sys

# --- CONFIGURATION ---
tenant_id = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'
client_secret = ''
client_id = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'
target_user_email = 'mthakar@batched.onmicrosoft.com'
# ---------------------

# Auth URL
auth_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'
auth_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://analysis.windows.net/powerbi/api/.default'
}

def get_access_token():
    try:
        response = requests.post(auth_url, data=auth_data)
        response.raise_for_status()
        return response.json().get('access_token')
    except Exception as e:
        print(f"Error authenticating: {e}")
        # Print actual error body if available
        if 'response' in locals():
            print(response.text)
        sys.exit(1)

def main():
    print(f"Preparing to grant ADMIN access to: {target_user_email}")
    print("Authenticating...")
    
    token = get_access_token()
    headers = {
        'Authorization': f'Bearer {token}', 
        'Content-Type': 'application/json'
    }
    print("Authenticated successfully.")
    
    try:
        # 1. Get all groups (workspaces) using ADMIN API
        # Added $top=5000 to maximize results (default is usually 2000)
        groups_url = 'https://api.powerbi.com/v1.0/myorg/admin/groups' 
        
        print("Fetching workspace list...")
        groups_res = requests.get(groups_url, headers=headers)
        groups_res.raise_for_status()
        
        all_groups = groups_res.json().get('value', [])
        
        # 2. FILTER: Exclude "PersonalGroup" (My Workspace)
        # We only want 'Workspace' (Shared Workspaces)
        target_groups = [g for g in all_groups if g.get('type') == 'Workspace']
        
        count = len(target_groups)
        ignored = len(all_groups) - count
        
        print(f"\nFound {len(all_groups)} total entries.")
        print(f"Ignored {ignored} 'Personal' workspaces.")
        print(f"Targeting {count} Shared Workspaces.")
        
        if count == 0:
            print("No shared workspaces found to update.")
            return

        # Confirmation
        print(f"WARNING: You are about to add '{target_user_email}' as an ADMIN to ALL {count} workspaces.")
        confirm = input("Are you sure you want to proceed? (yes/no): ").lower().strip()
        
        if confirm != 'yes':
            print("Operation cancelled.")
            return

        success_count = 0
        fail_count = 0

        for index, group in enumerate(target_groups):
            group_name = group.get('name', 'Unknown')
            group_id = group['id']
            
            # API: Admin endpoint for adding user
            url = f'https://api.powerbi.com/v1.0/myorg/admin/groups/{group_id}/users'
            
            # Admin API requires 'identifier'
            payload = {
                "identifier": target_user_email,
                "groupUserAccessRight": "Admin",
                "principalType": "User"
            }

            print(f"[{index+1}/{count}] Adding Admin to '{group_name}'...", end=" ")
            
            res = requests.post(url, headers=headers, json=payload)
            
            if res.status_code == 200:
                print("OK")
                success_count += 1
            elif res.status_code == 400 and "UserAlreadyExists" in res.text:
                 # It's not really a failure if they are already there
                 print("EXISTING (Skipped)")
                 # Optional: count as success or separate category
                 success_count += 1
            else:
                print(f"FAILED ({res.status_code})")
                # print(res.text) # Uncomment for debug
                fail_count += 1
                
        print("\n" + "="*50)
        print("SUMMARY")
        print("="*50)
        print(f"Total Targeted: {count}")
        print(f"Successfully Added/Verified: {success_count}")
        print(f"Failed: {fail_count}")

    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main()