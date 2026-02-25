import json
import yaml
import boto3
import logging
import os
import time
import requests
import jwt
from cryptography.hazmat.primitives import serialization
import base64
import nacl.public
import nacl.encoding

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def refresh_dotnet_lambdas():
    """Refresh .NET Lambda functions to pick up new parameter store values"""
    try:
        lambda_client = boto3.client('lambda')
        
        # Get all Lambda functions with .NET 8 runtime
        dotnet_functions = []
        paginator = lambda_client.get_paginator('list_functions')
        
        for page in paginator.paginate():
            for function in page['Functions']:
                runtime = function.get('Runtime', '')
                if runtime == 'dotnet8':
                    dotnet_functions.append(function['FunctionName'])
        
        if not dotnet_functions:
            logger.info("No .NET 8 Lambda functions found in account")
            return
            
        logger.info(f"Found {len(dotnet_functions)} .NET 8 Lambda functions: {dotnet_functions}")
        
        for function_name in dotnet_functions:
            try:
                # Get current environment variables
                response = lambda_client.get_function(FunctionName=function_name)
                current_env = response['Configuration'].get('Environment', {}).get('Variables', {})
                
                # Add timestamp to force refresh
                updated_env = current_env.copy()
                updated_env['LAST_REFRESH'] = str(int(time.time()))
                
                # Update function configuration to force refresh (this triggers container restart)
                lambda_client.update_function_configuration(
                    FunctionName=function_name,
                    Environment={
                        'Variables': updated_env
                    }
                )
                logger.info(f"Refreshed .NET Lambda function: {function_name}")
                
            except Exception as e:
                logger.error(f"Failed to refresh Lambda function {function_name}: {e}")
                # Continue with other functions
                
        logger.info(f"Completed refresh attempt for {len(dotnet_functions)} .NET 8 Lambda functions")
        
    except Exception as e:
        logger.error(f"Failed to refresh .NET Lambda functions: {e}")
        # Don't raise - Lambda refresh is optional

def invoke_health_check_lambda():
    """Invoke the dedicated health check Lambda function"""
    try:
        health_check_function_name = os.environ.get('HEALTH_CHECK_FUNCTION_NAME', 'SecretRotationHealthCheck')
        
        lambda_client = boto3.client('lambda')
        
        payload = {
            'trigger': 'secret_rotation_completed',
            'timestamp': time.time()
        }
        
        logger.info(f"Invoking health check Lambda: {health_check_function_name}")
        
        response = lambda_client.invoke(
            FunctionName=health_check_function_name,
            InvocationType='RequestResponse',  # Synchronous invocation
            Payload=json.dumps(payload)
        )
        
        # Parse response
        response_payload = json.loads(response['Payload'].read())
        status_code = response_payload.get('statusCode', 500)
        
        if status_code == 200:
            logger.info("Health check Lambda completed successfully")
            return True
        else:
            logger.error(f"Health check Lambda failed with status {status_code}: {response_payload}")
            return False
            
    except Exception as e:
        logger.error(f"Failed to invoke health check Lambda: {e}")
        return False

def delete_redis_keys():
    """Delete Redis keys matching pattern *TenantDBConnection*"""
    try:
        redis_endpoint = os.environ.get('REDIS_ENDPOINT')
        redis_port = os.environ.get('REDIS_PORT', '6379')
        
        if not redis_endpoint:
            logger.info("REDIS_ENDPOINT not set, skipping Redis key deletion")
            return
            
        import redis
        
        # Connect to Redis
        r = redis.Redis(
            host=redis_endpoint,
            port=int(redis_port),
            decode_responses=True,
            ssl=True,
            socket_connect_timeout=5,
            socket_timeout=5
        )
        
        # Find and delete keys matching pattern
        pattern = "*TenantDBConnection*"
        keys = r.keys(pattern)
        
        if keys:
            deleted_count = r.delete(*keys)
            logger.info(f"Deleted {deleted_count} Redis keys matching pattern '{pattern}'")
        else:
            logger.info(f"No Redis keys found matching pattern '{pattern}'")
            
    except ImportError:
        logger.warning("Redis library not available, skipping Redis key deletion")
    except Exception as e:
        logger.error(f"Failed to delete Redis keys: {e}")
        # Don't raise - Redis cleanup is optional

def update_github_environment_secrets(new_password):
    """Update GitHub Environment secrets with new password using GitHub App authentication.
    
    This function:
    1. Fetches the GitHub App private key from Parameter Store
    2. Creates a JWT token for GitHub App authentication
    3. Gets an installation access token
    4. Updates the specified environment secret with the new password
    """
    try:
        # Get environment variables
        app_id = os.environ.get('GITHUB_APP_ID')
        installation_id = os.environ.get('GITHUB_INSTALLATION_ID')
        repo_owner = os.environ.get('GITHUB_REPO_OWNER')
        repo_name = os.environ.get('GITHUB_REPO_NAME')
        environment_name = os.environ.get('GITHUB_ENVIRONMENT_NAME')
        secret_name = os.environ.get('GITHUB_SECRET_NAME')
        
        if not all([app_id, installation_id, repo_owner, repo_name, environment_name, secret_name]):
            logger.warning("Missing GitHub configuration environment variables, skipping GitHub secret update")
            return
        
        # Get private key from Parameter Store
        ssm_client = boto3.client('ssm')
        private_key_response = ssm_client.get_parameter(
            Name='/secret-rotation/github/private-key',
            WithDecryption=True
        )
        private_key_pem = private_key_response['Parameter']['Value']
        
        # Parse the private key
        private_key = serialization.load_pem_private_key(
            private_key_pem.encode('utf-8'),
            password=None
        )
        
        # Create JWT token for GitHub App authentication
        now = int(time.time())
        payload = {
            'iat': now - 60,  # Issued at time (60 seconds in the past to account for clock skew)
            'exp': now + 600,  # Expires in 10 minutes
            'iss': app_id    # GitHub App ID
        }
        
        jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
        
        # Get installation access token
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Secret-Rotation-Lambda/1.0'
        }
        
        installation_url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
        installation_response = requests.post(installation_url, headers=headers, timeout=30)
        installation_response.raise_for_status()
        
        access_token = installation_response.json()['token']
        
        # Get repository and environment IDs
        repo_headers = {
            'Authorization': f'token {access_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Secret-Rotation-Lambda/1.0'
        }
        
        # Get repository ID
        repo_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}'
        repo_response = requests.get(repo_url, headers=repo_headers, timeout=30)
        repo_response.raise_for_status()
        repo_id = repo_response.json()['id']
        
        # Get environment public key for encryption
        env_key_url = f'https://api.github.com/repositories/{repo_id}/environments/{environment_name}/secrets/public-key'
        env_key_response = requests.get(env_key_url, headers=repo_headers, timeout=30)
        env_key_response.raise_for_status()
        
        public_key_data = env_key_response.json()
        public_key = public_key_data['key']
        key_id = public_key_data['key_id']
        
        # Encrypt the secret value using libsodium sealed box encryption
        # Decode the GitHub public key
        public_key_bytes = base64.b64decode(public_key)
        
        # Create a libsodium public key object
        github_public_key = nacl.public.PublicKey(public_key_bytes)
        
        # Create a sealed box for encryption
        sealed_box = nacl.public.SealedBox(github_public_key)
        
        # Encrypt the secret value
        encrypted_bytes = sealed_box.encrypt(new_password.encode('utf-8'))
        
        # Encode to base64 for GitHub API
        encrypted_value = base64.b64encode(encrypted_bytes).decode('utf-8')
        
        # Update the environment secret
        secret_url = f'https://api.github.com/repositories/{repo_id}/environments/{environment_name}/secrets/{secret_name}'
        secret_payload = {
            'encrypted_value': encrypted_value,
            'key_id': key_id
        }
        
        secret_response = requests.put(secret_url, headers=repo_headers, json=secret_payload, timeout=30)
        secret_response.raise_for_status()
        
        logger.info(f"Successfully updated a GitHub environment secret in {repo_owner}/{repo_name}/{environment_name}")
        
    except Exception as e:
        logger.error(f"Failed to update GitHub environment secrets: {e}")
        # Don't raise - GitHub update is optional

def lambda_handler(event, context):
    """Process SQS message to update single parameter with new password.
    
    Expected SQS message body:
    {
      "parameter_name": "single_param_name",
      "new_password": "new_secret"
    }
    """
    
    # Parse SQS message (batch size = 1, so only one record)
    record = event['Records'][0]
    message_body = json.loads(record['body'])
    parameter_name = message_body.get('parameter_name')
    new_password = message_body.get('new_password')
    is_last_parameter = message_body.get('is_last_parameter', False)
    # if you also need to rotate userId in YAML, set new_user; otherwise leave as None
    new_user = None  # e.g. "rotate_user"
    
    if not parameter_name or not new_password:
        logger.error(f"Invalid message format: {message_body}")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Missing parameter_name or new_password'})}
    
    ssm = boto3.client('ssm')
    try:
        # 1) Fetch
        resp = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        raw = resp['Parameter']['Value']
        
        # 2) Detect format and update accordingly
        is_json = raw.lstrip().startswith('{')
        is_yaml = False
        is_connection_string = False
        is_plain_password = False
        
        # Check if it's YAML (starts with common YAML patterns)
        if not is_json:
            yaml_indicators = ['---', 'dev:', 'prod:', 'environment:', 'config:']
            is_yaml = any(indicator in raw for indicator in yaml_indicators)
        
        # Check if it's a connection string (contains Password= or PWD= pattern)
        if not is_json and not is_yaml:
            is_connection_string = 'password=' in raw.lower() or 'pwd=' in raw.lower()
        
        # If none of the above, treat as plain password
        if not is_json and not is_yaml and not is_connection_string:
            is_plain_password = True
        
        if is_json:
            # —— .NET JSON appsettings —— 
            cfg = json.loads(raw)
            
            # make sure ConnectionStrings exists
            cs = cfg.get('ConnectionStrings')
            if cs is None:
                raise KeyError("Missing ConnectionStrings in JSON payload")
            
            # update required + optional
            for key in ('BatchedDBConnection', 'TenantDBConnection'):
                conn = cs.get(key)
                if conn:
                    parts = [p.strip() for p in conn.split(';') if p.strip()]
                    new_parts = []
                    for p in parts:
                        p_lower = p.lower()
                        if p_lower.startswith('password='):
                            new_parts.append(f"Password={new_password}")
                        elif p_lower.startswith('pwd='):
                            new_parts.append(f"PWD={new_password}")
                        else:
                            new_parts.append(p)
                    cs[key] = ';'.join(new_parts)
                    logger.info(f"Rotated JSON connection string {key}")
                elif key == 'BatchedDBConnection':
                    raise KeyError("Required JSON key BatchedDBConnection not found")
                else:
                    logger.info(f"Optional JSON key {key} missing; skipping")
            
            updated_raw = json.dumps(cfg, indent=2)
            format_type = 'JSON'
        
        elif is_yaml:
            # —— R YAML appconfig —— 
            cfg = yaml.safe_load(raw)
            
            # only update dev/prod if they already exist
            for env in ('dev', 'prod'):
                if env in cfg:
                    env_section = cfg[env] or {}
                    db_env = env_section.get('db')
                    if db_env is not None:
                        db_env['password'] = new_password
                        logger.info(f"Rotated YAML {env}.db.password")
                        if new_user is not None:
                            db_env['userId'] = new_user
                    else:
                        logger.info(f"YAML {env}.db section missing; skipping")
                else:
                    logger.info(f"YAML {env} section not present; skipping")
            
            # dump back preserving block style
            updated_raw = yaml.safe_dump(
                cfg,
                default_flow_style=False,
                sort_keys=False
            )
            format_type = 'YAML'
            
        elif is_connection_string:
            # —— Direct Connection String ——
            # Replace Password= or PWD= value in connection string
            import re
            # Handle both Password= and PWD= patterns
            # Use a replacement function to avoid regex group reference issues
            def replace_password(match):
                return match.group(1) + new_password
            
            updated_raw = re.sub(
                r'(?i)((?:password|pwd)\s*=\s*)([^;]*)',
                replace_password,
                raw
            )
            logger.info("Rotated direct connection string password")
            format_type = 'CONNECTION_STRING'
            
        elif is_plain_password:
            # —— Plain Password Value ——
            # Replace entire value with new password
            updated_raw = new_password
            logger.info("Replaced plain password value")
            format_type = 'PLAIN_PASSWORD'
        
        # 3) Write back
        ssm.put_parameter(
            Name=parameter_name,
            Value=updated_raw,
            Type='SecureString',
            Overwrite=True
        )
        
        logger.info(f"Successfully updated parameter {parameter_name} with format {format_type}")
        
        # 4) If this is the last parameter, refresh Lambda functions, clear Redis, and perform health checks
        if is_last_parameter:
            logger.info("This is the last parameter. Starting post-update tasks...")
            
            # Refresh .NET Lambda functions to pick up new parameter values
            refresh_dotnet_lambdas()
            
            # Update GitHub Environment secrets with new password
            update_github_environment_secrets(new_password)
            
            # Delete Redis keys with wildcard pattern *TenantDBConnection*
            delete_redis_keys()

            time.sleep(30)  # brief pause to allow Redis to stabilize
            # Invoke health check Lambda
            invoke_health_check_lambda()

            logger.info(f"Completed Lambda refresh, GitHub update, Redis cleanup, and health check")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Credentials rotated',
                'format': format_type,
                'parameter': parameter_name,
                'is_last_parameter': is_last_parameter,
                'lambda_refreshed': is_last_parameter,
                'github_updated': is_last_parameter,
                'redis_cleared': is_last_parameter,
                'health_check_invoked': is_last_parameter
            })
        }
    
    except Exception as e:
        logger.error(f"Error rotating credentials for {parameter_name}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }