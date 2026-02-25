import requests
from requests.auth import HTTPProxyAuth

proxy = "http://34.196.64.136:31280"
username = "your_proxy_user"
password = "your_proxy_password"

proxies = {
    "http": proxy,
    "https": proxy
}

url = "https://api.ipify.org/"

# --- Basic Auth Example ---
try:
    print("Trying proxy with Basic Auth...")
    r = requests.get(url, proxies=proxies, auth=HTTPProxyAuth(username, password))
    print("Status code:", r.status_code)
    print("Text:", r.text[:200])  # Print head of response
except Exception as e:
    print("Basic Auth failed:", e)

# --- NTLM Auth Example (requires requests-ntlm) ---
try:
    from requests_ntlm import HttpNtlmAuth
    print("Trying proxy with NTLM Auth...")
    r = requests.get(url, proxies=proxies, auth=HttpNtlmAuth(username, password))
    print("Status code:", r.status_code)
    print("Text:", r.text[:200])
except ImportError:
    print("requests-ntlm not installed (pip install requests-ntlm)")
except Exception as e:
    print("NTLM Auth failed:", e)
