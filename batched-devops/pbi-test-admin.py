import requests
import base64
import json

# --- PASTE YOUR CREDENTIALS HERE ---
tenant_id = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'
client_secret = ''
client_id = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'
# -----------------------------------

auth_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'
auth_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://analysis.windows.net/powerbi/api/.default'
}

print("1. requesting Token...")
try:
    response = requests.post(auth_url, data=auth_data)
    response.raise_for_status()
    token = response.json().get('access_token')
    print("   Token received successfully.")
    
    # Decode the token (JWT is 3 parts separated by dots, we need the middle part)
    token_parts = token.split('.')
    padding = '=' * (4 - len(token_parts[1]) % 4)
    decoded_body = base64.urlsafe_b64decode(token_parts[1] + padding).decode('utf-8')
    claims = json.loads(decoded_body)
    
    print("\n2. INSPECTING PERMISSIONS (ROLES):")
    roles = claims.get('roles', [])
    
    if not roles:
        print("   [CRITICAL FAIL] The 'roles' list is EMPTY or MISSING.")
        print("   CAUSE: You added permissions in Azure but did NOT click 'Grant Admin Consent'.")
    else:
        print(f"   [SUCCESS] Roles found: {roles}")
        if 'Tenant.Read.All' in roles or 'Tenant.ReadWrite.All' in roles:
            print("   STATUS: Azure is configured CORRECTLY.")
            print("   NEXT STEP: The issue is definitely inside Power BI Settings or Propagation Delay.")
        else:
            print("   [FAIL] The specific role 'Tenant.Read.All' is missing.")

except Exception as e:
    print(f"Error: {e}")