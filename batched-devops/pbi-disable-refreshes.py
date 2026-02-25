import requests
import json
import sys

# Configuration
tenant_id = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'
client_secret = ''
client_id = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'

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
        sys.exit(1)

def main():
    print("Authenticating...")
    token = get_access_token()
    headers = {
        'Authorization': f'Bearer {token}', 
        'Content-Type': 'application/json'
    }
    print("Authenticated successfully.")
    
    try:
        # Get all groups (workspaces)
        groups_url = 'https://api.powerbi.com/v1.0/myorg/groups' 
        groups_res = requests.get(groups_url, headers=headers)
        groups_res.raise_for_status()
        groups = groups_res.json().get('value', [])
        
        # Sort groups by name for easier reading
        groups.sort(key=lambda x: x['name'])
        
        print(f"\nFound {len(groups)} workspaces:")
        print("="*50)
        for i, group in enumerate(groups):
            print(f"{i+1}. {group['name']}")
        print("="*50)
        
        # Ask for input
        print("\nEnter the names of the workspaces to disable refreshes for (comma separated).")
        print("Example: Workspace A, Workspace B")
        selection_input = input("Workspaces > ").strip()
        
        if not selection_input:
            print("No workspaces selected. Exiting.")
            return

        selected_names = [s.strip() for s in selection_input.split(',')]
        
        # Resolve names to IDs
        target_groups = []
        for name in selected_names:
            match = next((g for g in groups if g['name'].lower() == name.lower()), None)
            if match:
                target_groups.append(match)
            else:
                print(f"Warning: Workspace '{name}' not found.")
        
        if not target_groups:
            print("No valid workspaces found matching your input. Exiting.")
            return
            
        print(f"\nProcessing {len(target_groups)} workspaces...")
        
        for group in target_groups:
            group_name = group['name']
            group_id = group['id']
            print(f"\n[Workspace: {group_name}]")
            
            # Get datasets
            datasets_url = f'https://api.powerbi.com/v1.0/myorg/groups/{group_id}/datasets'
            datasets_res = requests.get(datasets_url, headers=headers)
            
            if datasets_res.status_code != 200:
                print(f"  Error fetching datasets: {datasets_res.text}")
                continue
                
            datasets = datasets_res.json().get('value', [])
            if not datasets:
                print("  No datasets found.")
                continue
                
            for dataset in datasets:
                dataset_name = dataset['name']
                dataset_id = dataset['id']
                
                # Check if configured
                if dataset.get('isRefreshable', False) == False:
                     # Skip if not refreshable at all (e.g. push dataset)
                     continue

                # Disable Schedule
                # PATCH https://api.powerbi.com/v1.0/myorg/groups/{groupId}/datasets/{datasetId}/refreshSchedule
                # Body: { "value": { "enabled": false } }
                
                schedule_url = f'https://api.powerbi.com/v1.0/myorg/groups/{group_id}/datasets/{dataset_id}/refreshSchedule'
                payload = {
                    "value": {
                        "enabled": False
                    }
                }
                
                # We try to update. If it fails (e.g. no schedule exists), the API might 404 or bad request.
                # However, usually we can just set enabled=False even if not configured.
                
                patch_res = requests.patch(schedule_url, headers=headers, json=payload)
                
                if patch_res.status_code == 200:
                    print(f"  [OK] Disabled refresh for: {dataset_name}")
                elif patch_res.status_code == 404:
                     # Usually means dataset doesn't support refresh or no schedule
                     print(f"  [Skip] No schedule found/supported for: {dataset_name}")
                else:
                    print(f"  [Failed] Could not disable for {dataset_name}: {patch_res.status_code} - {patch_res.text}")

    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main()
