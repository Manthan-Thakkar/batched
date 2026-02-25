import requests

# 1. Configuration
tenant_id = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'
client_secret = ''
client_id = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'

# 2. Get the Access Token from Microsoft (Azure AD)
auth_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'
auth_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://analysis.windows.net/powerbi/api/.default'
}

auth_response = requests.post(auth_url, data=auth_data)
access_token = auth_response.json().get('access_token')
# print("Access Token:", access_token)

# 3. Use the Token to call Power BI API
# Example: Get all Datasets in a specific Group (Workspace)
api_url = f'https://api.powerbi.com/v1.0/myorg/gateways'

headers = {
    'Authorization': f'Bearer {access_token}'
}

response = requests.get(api_url, headers=headers)

print(response.json())