import json
import boto3
import logging
import re
import requests
import sqlalchemy as sa
import os
from datetime import datetime


logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Configuration from environment variables
secrets_client = boto3.client('secretsmanager')
API_BASE = os.environ['API_BASE']  # e.g. https://api.example.com
CLOUD_API_BASE = os.environ['CLOUD_API_BASE']  # e.g. https://api.example.com
HEADER_KEY = os.environ.get('STATIC_HEADER_KEY', 'x-api-key')
HEADER_VALUE   = os.environ.get('STATIC_HEADER_VALUE', '7wEJtncY9fUJYpXnUQWzLuMsyG427NVyrNF8HAcJyYDy9rRWTUCwbGh7VHm')
STATIC_HEADERS = {HEADER_KEY: HEADER_VALUE}


DB_CONNECTION_SECRET = os.environ.get('DB_CONNECTION_SECRET')


def extract_batched_tenant_id(secret_name):
    """Extract BatchedtenantId from secret name BackendAPI/<BatchedtenantId>/LTCloudAPIToken"""
    pattern = r'BackendAPI/([^/]+)/LTCloudAPIToken'
    match = re.match(pattern, secret_name)
    
    if not match:
        raise ValueError(f"Secret name does not match expected pattern: {secret_name}")
    
    tenant_id = match.group(1)
    logger.info("Extracted Batched Tenant ID")
    return tenant_id

def get_tenant_name_from_db(batched_tenant_id):
    """Fetch tenant name from MSSQL database and remove spaces"""
    try:
        # Get database connection string from Secrets Manager
        logger.info(f"Retrieving database connection from secret: {DB_CONNECTION_SECRET}")
        
        response = secrets_client.get_secret_value(SecretId=DB_CONNECTION_SECRET)
        secret_value = json.loads(response['SecretString'])
        rds_engine = sa.create_engine('mssql+pyodbc://'+secret_value['username']+':'+secret_value['password']+'@'+secret_value['host']+'/batched?driver=ODBC+Driver+18+for+SQL+Server',connect_args={'autocommit': True})
        
        logger.info("Successfully retrieved database connection string")
        
        # Connect to database
        conn = rds_engine.raw_connection()
        cursor = conn.cursor()
        
        # Execute query - Replace with your actual query
        query = """
        SELECT Name 
        FROM Tenant 
        WHERE ID = ?
        """
        
        cursor.execute(query, (batched_tenant_id,))
        result = cursor.fetchone()
        
        if not result:
            raise ValueError(f"No tenant found for Batched Tenant ID: {batched_tenant_id}")
        
        tenant_name = result[0]
        
        # Remove spaces and clean the tenant name
        final_tenant_name = tenant_name.replace(" ", "").strip()
        print(final_tenant_name)
        
        logger.info(f"Fetched tenant name: {tenant_name} -> Final: {final_tenant_name}")
        
        cursor.close()
        conn.close()
        
        return final_tenant_name
        
    except Exception as e:
        logger.error(f"Error fetching tenant name from database: {str(e)}")
        raise

def get_dw_tenant_id(tenant_name):
    """Get Data Warehouse Tenant ID from LTDW/<TenantName> secret"""
    try:
        secret_name = f"LTDW/{tenant_name}"
        
        logger.info(f"Fetching DW Tenant ID from secret: {secret_name}")
        
        response = secrets_client.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(response['SecretString'])
        
        # Look for tenantId key
        dw_tenant_id = secret_data.get('tenantId')
        
        if not dw_tenant_id:
            raise ValueError(f"tenantId key not found in secret: {secret_name}")
        
        logger.info(f"Retrieved DW Tenant ID: {dw_tenant_id}")
        return dw_tenant_id
        
    except Exception as e:
        logger.error(f"Error getting DW Tenant ID: {str(e)}")
        raise

def create_new_api_token(dw_tenant_id, tenant_name):
    """Create new API token using POST API call"""
    try:
        url = f"{API_BASE}/api/admin/restapi"
        
        payload = {
            "Email": "SecretManagerLambdaRotation",
            "data" : {
                "Owner" : dw_tenant_id,
                "Name": "Batched_" + tenant_name
            }
        }
        
        # Use static headers from environment variables
        headers=STATIC_HEADERS
        
        logger.info(f"Creating new API token for DW Tenant ID: {dw_tenant_id}")
        logger.info(f"API URL: {url}")
        
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Parse response to get the new token
        response_data = response.text.strip('"')
        
        if not response_data:
            raise ValueError("New token not found in API response")
        
        logger.info("Successfully created new API token")
        return response_data
        
    except Exception as e:
        logger.error(f"Error creating new API token: {str(e)}")
        raise

def delete_old_api_token(old_token):
    """Delete old API token using DELETE API call"""
    try:
        url = f"{API_BASE}/api/admin/restapi/{old_token}"
        
        # Use static headers from environment variables
        headers=STATIC_HEADERS

        payload = {
            "Email": "SecretManagerLambdaRotation",
        }
        
        logger.info("Deleting old API token")
        logger.info(f"API URL: {url}")
        
        response = requests.delete(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        
        logger.info("Successfully deleted old API token")
        
    except Exception as e:
        logger.error(f"Error deleting old API token: {str(e)}")
        # Don't raise here as this is cleanup - log the error but continue

def create_secret(secret_id, token):
    """Step 1: Create new secret version"""
    logger.info("Step 1: Creating new secret version")
    
    # Extract Batched Tenant ID from secret name
    batched_tenant_id = extract_batched_tenant_id(secret_id.split(":")[-1])
    
    # Get tenant name from database
    tenant_name = get_tenant_name_from_db(batched_tenant_id)
    
    # Get DW Tenant ID from LTDW secret
    dw_tenant_id = get_dw_tenant_id(tenant_name)
    
    # Create new API token
    new_token = create_new_api_token(dw_tenant_id, tenant_name)
    
    secrets_client.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=new_token,
        VersionStages=['AWSPENDING']
    )
    
    logger.info("Successfully created new secret version")


def set_secret(secret_id, token):
    """Step 2: Set secret - No action needed for API tokens"""
    logger.info("Step 2: Set secret - No action needed")
    # No action needed for API tokens


def test_secret(secret_id, token):
    """Step 3: Test the new secret"""
    logger.info("Step 3: Testing new secret")
    
    # Get the pending secret to test
    response = secrets_client.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage="AWSPENDING"
    )
    
    pending_secret = response['SecretString']
    
    # Test the new token
    try:
        url = f"{CLOUD_API_BASE}/addresses-count"
        
        # Use static headers from environment variables
        headers = {"Authorization": f"{pending_secret}"}
        
        logger.info(f"Testing new API token ")
        logger.info(f"API URL: {url}")
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Parse response to get the new token
        response_data = response.text.strip('"')
        print(response_data)
        
        if not response_data:
            raise ValueError("No Data found in API response")
        
        logger.info("New token is ready for use")
        return response_data
        
    except Exception as e:
        logger.error(f"Error Testing new API token: {str(e)}")
        raise

def finish_secret(secret_id, token):
    """Step 4: Finish secret rotation"""
    logger.info("Step 4: Finishing secret rotation")
    
    # 1) find old AWSCURRENT version
    meta = secrets_client.describe_secret(SecretId=secret_id)
    old_ver = next(
        (v for v, s in meta['VersionIdsToStages'].items()
         if 'AWSCURRENT' in s),
        None
    )
    
    # 2) if an old version exists, delete its token
    if old_ver:
        old = secrets_client.get_secret_value(
            SecretId=secret_id,
            VersionId=old_ver
        )
        old_token = old['SecretString']
        
        if old_token:
            print(f"Old token to delete: {old_token}")
            logger.info(f"finishSecret: deleting old API token")
            
            try:
                delete_old_api_token(old_token)
                logger.info("finishSecret: deleted old API token")
            except Exception as e:
                logger.warning(f"Failed to delete old API token: {str(e)}")
                # Don't raise here as this is cleanup
    
    # 3) promote the new version
    if old_ver == token:
        logger.info("finishSecret: token already AWSCURRENT")
    else:
        secrets_client.update_secret_version_stage(
            SecretId=secret_id,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token,
            RemoveFromVersionId=old_ver
        )
        logger.info("finishSecret: promoted AWSPENDING to AWSCURRENT")


def lambda_handler(event, context):
    """AWS Secrets Manager rotation handler for LTCloudAPIToken"""
    
    try:
        print(event)
        secret_id = event['SecretId']
        token     = event['ClientRequestToken']
        step      = event['Step']
        
        logger.info(f"Rotation step: {step} for secret: {secret_id}")
        logger.info(f"Using API Base: {API_BASE}")
        logger.info(f"Using DB Connection Secret: {DB_CONNECTION_SECRET}")
        
        # ensure rotation is enabled & token is valid
        meta = secrets_client.describe_secret(SecretId=secret_id)
        if not meta.get('RotationEnabled'):
            raise ValueError("Secret not enabled for rotation")
        if token not in meta['VersionIdsToStages']:
            raise ValueError("Invalid rotation token")
        
        # dispatch
        {
            'createSecret': create_secret,
            'setSecret':    set_secret,
            'testSecret':   test_secret,
            'finishSecret': finish_secret
        }[step](secret_id, token)
        
    except Exception as e:
        logger.error(f"Rotation failed at step {step}: {str(e)}")
        raise