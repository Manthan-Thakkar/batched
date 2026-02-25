import requests
import json
import base64

try:
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives import hashes
    CRYPTO_AVAILABLE = True
except ImportError:
    # cryptography not installed; RSA-OAEP encryption will not work
    CRYPTO_AVAILABLE = False

# --- CONFIGURATION ---
CLIENT_ID = '30a67f99-d5fc-45c5-93fe-80f6769c5eb0'
CLIENT_SECRET = 'testsecret'
TENANT_ID = '52e3b736-bb3a-4585-ba4a-1f43e46bbee3'

# Standard Power BI API Scope
SCOPE = 'https://analysis.windows.net/powerbi/api/.default'

# ====== UPDATE CONFIGURATION ======
# Set your new Basic Auth credentials here
NEW_USERNAME = 'pbi_readonly_user'
NEW_PASSWORD = 'q5xw65350qje'

# Set which batch to update (1 = first 10, 2 = next 10, etc.)
BATCH_NUMBER = 10

# Batch size (number of datasources to update per batch)
BATCH_SIZE = 10
# ==================================

def get_access_token():
    """Authenticates with Azure AD to get the Bearer Token"""
    url = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
    
    payload = {
        'grant_type': 'client_credentials',
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'scope': SCOPE
    }
    
    response = requests.post(url, data=payload)
    response.raise_for_status() # Raise error if auth fails
    return response.json().get('access_token')

def check_datasource_connectivity(gateway_id, datasource_id, headers):
    """Tests the connectivity of a specific datasource using the status endpoint"""
    # Use the proper connectivity test endpoint
    test_url = f"https://api.powerbi.com/v1.0/myorg/gateways/{gateway_id}/datasources/{datasource_id}/status"
    try:
        response = requests.get(test_url, headers=headers)
        if response.status_code == 200:
            # Handle empty response (means success)
            if not response.text or response.text.strip() == '':
                return "✓ Connected (Empty response = Success)"
            try:
                status_data = response.json()
                # Check if there's an error in the response
                if status_data.get('error'):
                    return f"✗ Failed: {status_data['error'].get('message', 'Unknown error')}"
                return "✓ Connected"
            except json.JSONDecodeError:
                # Empty or non-JSON response with 200 status means success
                return "✓ Connected"
        elif response.status_code == 404:
            # Status endpoint might not exist, datasource exists but status endpoint not available
            return "⚠ Datasource exists (Status endpoint not available)"
        elif response.status_code == 401 or response.status_code == 403:
            return f"✗ Access Denied ({response.status_code}) - Service Principal may not be gateway admin"
        else:
            return f"✗ Error ({response.status_code}): {response.text[:100]}"
    except requests.exceptions.RequestException as e:
        return f"✗ Network Error: {str(e)[:50]}"
    except Exception as e:
        return f"✗ Failed: {str(e)[:50]}"



def update_datasource_credentials(gateway_id, datasource_id, headers, username, password):
    """
    Updates the credentials for a datasource using Basic authentication
    Based on: https://learn.microsoft.com/en-us/rest/api/power-bi/gateways/update-datasource
    
    For on-premises gateways, credentials must be encrypted with RSA-OAEP using gateway public key
    """
    update_url = f"https://api.powerbi.com/v1.0/myorg/gateways/{gateway_id}/datasources/{datasource_id}"

    if not CRYPTO_AVAILABLE:
        return False, "✗ cryptography package not installed"

    # Step 1: Get gateway public key
    gateway_resp = requests.get(f"https://api.powerbi.com/v1.0/myorg/gateways/{gateway_id}", headers=headers)
    if gateway_resp.status_code != 200:
        return False, f"✗ Gateway fetch failed ({gateway_resp.status_code}): {gateway_resp.text}"
    
    pk = gateway_resp.json().get("publicKey") or {}
    modulus_b64 = pk.get("modulus")
    exponent_b64 = pk.get("exponent")
    if not modulus_b64 or not exponent_b64:
        return False, "✗ Gateway public key missing modulus/exponent"

    # Step 2: Decode gateway public key components
    modulus_bytes = base64.b64decode(modulus_b64)
    exponent_bytes = base64.b64decode(exponent_b64)
    modulus_int = int.from_bytes(modulus_bytes, "big")
    exponent_int = int.from_bytes(exponent_bytes, "big")
    public_key = rsa.RSAPublicNumbers(exponent_int, modulus_int).public_key()

    # Step 3: Create credentials JSON (for Basic auth, use credentialData array)
    credentials_json = json.dumps({
        "credentialData": [
            {"name": "username", "value": username},
            {"name": "password", "value": password}
        ]
    })
    
    print(f"[DEBUG] Encrypting credentials for on-premises gateway")
    print(f"[DEBUG] Plain credentials: {len(credentials_json)} bytes")
    print(f"[DEBUG] Modulus size: {len(modulus_bytes)} bytes")
    print(f"[DEBUG] Gateway key size: {public_key.key_size} bits")

    # Step 4: Use hybrid encryption for 2048-bit keys (like Microsoft's AsymmetricHigherKeyEncryptionHelper)
    try:
        import os
        from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
        from cryptography.hazmat.primitives import hmac as crypto_hmac
        from cryptography.hazmat.primitives.padding import PKCS7
        
        # Generate ephemeral AES and HMAC keys
        key_enc = os.urandom(32)  # 256-bit AES key
        key_mac = os.urandom(64)  # 512-bit HMAC key
        
        # Encrypt credentials with AES-CBC
        iv = os.urandom(16)
        padder = PKCS7(128).padder()
        padded_data = padder.update(credentials_json.encode("utf-8")) + padder.finalize()
        cipher = Cipher(algorithms.AES(key_enc), modes.CBC(iv))
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(padded_data) + encryptor.finalize()
        
        # Create algorithm choices prefix (AES256-CBC-PKCS7, HMAC-SHA256)
        algorithm_choices = bytes([0, 0])  # Both algorithms = 0
        
        # Create HMAC over algorithm_choices + IV + ciphertext
        h = crypto_hmac.HMAC(key_mac, hashes.SHA256())
        h.update(algorithm_choices + iv + ciphertext)
        mac = h.finalize()
        
        # Combine: algorithm_choices + MAC + IV + ciphertext (authenticated encryption output)
        encrypted_data = algorithm_choices + mac + iv + ciphertext
        
        # Prepare keys with length prefixes (0 = 32 bytes, 1 = 64 bytes)
        keys_to_encrypt = bytes([0, 1]) + key_enc + key_mac
        
        # Encrypt the keys with RSA-OAEP SHA-256
        encrypted_keys = public_key.encrypt(
            keys_to_encrypt,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        
        # Final encrypted credentials: base64(encrypted_keys) + base64(iv + auth_tag + ciphertext)
        encrypted_credentials = (
            base64.b64encode(encrypted_keys).decode("utf-8") +
            base64.b64encode(encrypted_data).decode("utf-8")
        )
        
        print(f"[DEBUG] Using hybrid encryption (AES + RSA) for 2048-bit key")
        print(f"[DEBUG] Encrypted output: {len(encrypted_credentials)} chars")
    except Exception as e:
        return False, f"✗ Encryption failed: {e}"
    
    # Step 5: Build payload - for on-premises with RSA-OAEP, credentials is the encrypted base64 string
    payload = {
        "credentialDetails": {
            "credentialType": "Basic",
            "credentials": encrypted_credentials,
            "encryptedConnection": "Encrypted",
            "encryptionAlgorithm": "RSA-OAEP",
            "privacyLevel": "Organizational"
        }
    }
    
    print(f"[DEBUG] PATCH {update_url}")
    print(f"[DEBUG] Using RSA-OAEP encryption for on-premises gateway")
    
    try:
        response = requests.patch(update_url, headers=headers, json=payload)
        if response.status_code in [200, 204]:
            return True, "✓ Credentials updated successfully"
        else:
            return False, f"✗ Update failed ({response.status_code}): {response.text}"
    except Exception as e:
        return False, f"✗ Update error: {str(e)}"

def batch_update_from_list(headers, update_list):
    """
    Batch update credentials from a configurable list
    
    Args:
        headers: API headers with authorization
        update_list: List of dicts with format:
            {
                'gateway_id': 'xxx',
                'datasource_id': 'yyy',
                'username': 'user',
                'password': 'pass',
                'datasource_name': 'optional name for logging'
            }
    
    Returns:
        Dictionary with success and failed updates
    """
    results = {
        'success': [],
        'failed': []
    }
    
    total = len(update_list)
    print("\n" + "="*100)
    print(f"BATCH CREDENTIAL UPDATE FROM LIST")
    print("="*100)
    print(f"\nTotal datasources to update: {total}\n")
    
    for idx, item in enumerate(update_list, 1):
        gateway_id = item.get('gateway_id')
        datasource_id = item.get('datasource_id')
        username = item.get('username')
        password = item.get('password')
        datasource_name = item.get('datasource_name', f'Datasource {idx}')
        database = item.get('database', 'N/A')
        server = item.get('server', 'N/A')
        
        print(f"[{idx}/{total}] {datasource_name}")
        print(f"  Database: {database}")
        print(f"  Server: {server}")
        
        # Check connectivity before
        status_before = check_datasource_connectivity(gateway_id, datasource_id, headers)
        print(f"  BEFORE: {status_before}")
        
        # Update credentials
        success, message = update_datasource_credentials(
            gateway_id, datasource_id, headers, username, password
        )
        
        if success:
            # Wait for changes to propagate
            import time
            time.sleep(2)
            
            # Check connectivity after
            status_after = check_datasource_connectivity(gateway_id, datasource_id, headers)
            print(f"  AFTER: {status_after}")
            
            # Check if connectivity failed after update
            if "✗" in status_after:
                results['failed'].append({
                    'name': datasource_name,
                    'database': database,
                    'server': server,
                    'error': f"Connectivity check failed after update: {status_after}"
                })
                print(f"  ❌ CONNECTIVITY FAILED AFTER UPDATE\n")
                print(f"🛑 STOPPING BATCH UPDATE - Connectivity failed for '{datasource_name}'")
                print(f"   This likely means incorrect credentials were provided.")
                print(f"   Please verify username and password before continuing.\n")
                break
            
            results['success'].append({
                'name': datasource_name,
                'database': database,
                'server': server,
                'status_before': status_before,
                'status_after': status_after
            })
            print("  ✅ SUCCESS\n")
        else:
            results['failed'].append({
                'name': datasource_name,
                'database': database,
                'server': server,
                'error': message
            })
            print(f"  ❌ FAILED: {message}\n")
            print(f"🛑 STOPPING BATCH UPDATE - Update API call failed for '{datasource_name}'\n")
            break
    
    # Print summary
    print("\n" + "="*100)
    print("BATCH UPDATE SUMMARY")
    print("="*100)
    
    success_count = len(results['success'])
    failed_count = len(results['failed'])
    
    print(f"\n✅ Successfully Updated: {success_count}/{total}")
    for ds in results['success']:
        print(f"   • {ds['name']}")
        print(f"     Database: {ds['database']} | Server: {ds['server']}")
        print(f"     Before: {ds['status_before']} → After: {ds['status_after']}")
    
    if failed_count > 0:
        print(f"\n❌ Failed: {failed_count}/{total}")
        for ds in results['failed']:
            print(f"   • {ds['name']}")
            print(f"     Database: {ds['database']} | Server: {ds['server']}")
            print(f"     Error: {ds['error']}")
    
    print("\n" + "="*100)
    return results



def get_all_datasources_sorted(headers):
    """Fetch all datasources from all gateways and sort by name"""
    all_datasources = []
    
    gateways_url = "https://api.powerbi.com/v1.0/myorg/gateways"
    gateway_response = requests.get(gateways_url, headers=headers)
    
    if gateway_response.status_code != 200:
        print(f"Error fetching gateways: {gateway_response.text}")
        return []
    
    gateways = gateway_response.json().get('value', [])
    
    for gateway in gateways:
        gateway_id = gateway['id']
        gateway_name = gateway.get('name', 'N/A')
        
        ds_url = f"https://api.powerbi.com/v1.0/myorg/gateways/{gateway_id}/datasources"
        ds_response = requests.get(ds_url, headers=headers)
        
        if ds_response.status_code == 200:
            datasources = ds_response.json().get('value', [])
            
            for ds in datasources:
                # Only include Basic auth datasources
                if ds.get('credentialType') == 'Basic':
                    conn_details = ds.get('connectionDetails', '')
                    database = 'N/A'
                    server = 'N/A'
                    
                    if isinstance(conn_details, str):
                        try:
                            conn_json = json.loads(conn_details)
                            database = conn_json.get('database', 'N/A')
                            server = conn_json.get('server', 'N/A')
                        except:
                            pass
                    elif isinstance(conn_details, dict):
                        database = conn_details.get('database', 'N/A')
                        server = conn_details.get('server', 'N/A')
                    
                    all_datasources.append({
                        'gateway_id': gateway_id,
                        'gateway_name': gateway_name,
                        'datasource_id': ds.get('id'),
                        'datasource_name': ds.get('datasourceName', 'N/A'),
                        'database': database,
                        'server': server
                    })
    
    # Sort by datasource name
    all_datasources.sort(key=lambda x: x['datasource_name'].lower())
    
    return all_datasources

def update_batch_automatically(headers, batch_number, batch_size, username, password):
    """Automatically fetch, sort, and update a specific batch of datasources"""
    
    print("\n" + "="*100)
    print("AUTOMATIC BATCH UPDATE")
    print("="*100)
    print(f"\nFetching all datasources...")
    
    all_datasources = get_all_datasources_sorted(headers)
    
    if not all_datasources:
        print("❌ No Basic Auth datasources found.")
        return
    
    total_datasources = len(all_datasources)
    print(f"✓ Found {total_datasources} Basic Auth datasource(s)")
    
    # Calculate batch range
    start_idx = (batch_number - 1) * batch_size
    end_idx = start_idx + batch_size
    
    if start_idx >= total_datasources:
        print(f"\n❌ Batch {batch_number} is out of range. Total datasources: {total_datasources}")
        print(f"   Maximum batch number: {(total_datasources - 1) // batch_size + 1}")
        return
    
    batch_datasources = all_datasources[start_idx:end_idx]
    actual_batch_size = len(batch_datasources)
    
    print(f"\n📦 Batch {batch_number}: Datasources {start_idx + 1} to {start_idx + actual_batch_size}")
    print(f"   Username: {username}")
    print(f"   Password: ********")
    
    print(f"\nDatasources in this batch:")
    for idx, ds in enumerate(batch_datasources, start_idx + 1):
        print(f"  {idx}. {ds['datasource_name']}")
        print(f"      Database: {ds['database']}")
    
    confirm = input(f"\nProceed with updating {actual_batch_size} datasource(s)? (yes/no): ").strip().lower()
    if confirm != 'yes':
        print("❌ Operation cancelled.")
        return
    
    # Prepare update list
    update_list = []
    for ds in batch_datasources:
        update_list.append({
            'gateway_id': ds['gateway_id'],
            'datasource_id': ds['datasource_id'],
            'username': username,
            'password': password,
            'datasource_name': ds['datasource_name'],
            'database': ds['database'],
            'server': ds['server']
        })
    
    # Perform batch update
    batch_update_from_list(headers, update_list)

def main():
    try:
        # 1. Get Token
        token = get_access_token()
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        print(token)
        
        print("--- Authenticated Successfully ---")

        # 2. Get All Gateways
        # This lists the Gateway Clusters (the "folders" that hold connections)
        gateways_url = "https://api.powerbi.com/v1.0/myorg/gateways"
        gateway_response = requests.get(gateways_url, headers=headers)
        
        if gateway_response.status_code != 200:
            print(f"Error fetching gateways: {gateway_response.text}")
            return

        gateways = gateway_response.json().get('value', [])
        print(f"Found {len(gateways)} Gateways.\n")

        # 3. Display Basic Auth Datasources Summary
        print(f"\n{'='*100}")
        print("BASIC AUTH DATASOURCES SUMMARY")
        print(f"{'='*100}\n")
        
        all_datasources = get_all_datasources_sorted(headers)
        
        if not all_datasources:
            print("No Basic Auth datasources found.")
        else:
            print(f"Found {len(all_datasources)} Basic Auth datasource(s) (sorted by name):\n")
            
            for idx, ds in enumerate(all_datasources, 1):
                print(f"{idx}. {ds['datasource_name']}")
                print(f"   Database: {ds['database']}")
                print(f"   Server: {ds['server']}")
                print()

        # Automatically update batch based on configuration
        print("\n" + "="*100)
        print("BATCH UPDATE CONFIGURATION")
        print("="*100)
        print(f"Username: {NEW_USERNAME}")
        print(f"Password: {'********' if NEW_PASSWORD else 'NOT SET'}")
        print(f"Batch Number: {BATCH_NUMBER}")
        print(f"Batch Size: {BATCH_SIZE}")
        
        if not NEW_USERNAME or not NEW_PASSWORD or NEW_USERNAME == 'your_username_here':
            print("\n❌ Please configure NEW_USERNAME and NEW_PASSWORD at the top of the script.")
            return
        
        proceed = input("\nProceed with automatic batch update? (yes/no): ").strip().lower()
        if proceed == 'yes':
            update_batch_automatically(headers, BATCH_NUMBER, BATCH_SIZE, NEW_USERNAME, NEW_PASSWORD)
    
    except Exception as e:
        print(f"\n❌ An error occurred: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
