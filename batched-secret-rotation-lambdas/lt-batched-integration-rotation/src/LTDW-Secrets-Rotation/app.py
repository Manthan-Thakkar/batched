import os
import json
import logging

import boto3
import requests
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')
API_BASE       = os.environ['API_BASE']  # e.g. https://api.example.com
HEADER_KEY     = os.environ.get('STATIC_HEADER_KEY', 'x-api-key')
HEADER_VALUE   = os.environ.get('STATIC_HEADER_VALUE', '7wEJtncY9fUJYpXnUQWzLuMsyG427NVyrNF8HAcJyYDy9rRWTUCwbGh7VHm')
STATIC_HEADERS = {HEADER_KEY: HEADER_VALUE}


def lambda_handler(event, context):
    print(event)
    secret_id = event['SecretId']
    token     = event['ClientRequestToken']
    step      = event['Step']

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


def create_secret(secret_id, token):
    # idempotency: skip if AWSPENDING already exists
    try:
        secrets_client.get_secret_value(
            SecretId=secret_id,
            VersionId=token,
            VersionStage='AWSPENDING'
        )
        logger.info("createSecret: pending version already exists")
        return
    except secrets_client.exceptions.ResourceNotFoundException:
        pass

    # 1) fetch the current secret to read tenantId and preserve other fields
    current = secrets_client.get_secret_value(
        SecretId=secret_id,
        VersionStage='AWSCURRENT'
    )
    current_data = json.loads(current['SecretString'])
    tenant = current_data['tenantId']

    # 2) call your API to create a new Postgres login
    resp = requests.post(
        f"{API_BASE}/api/admin/tenant/{tenant}/logins",
        headers=STATIC_HEADERS,
        json={ "Email": "SecretManagerLambdaRotation" },
        timeout=10
    )
    resp.raise_for_status()
    login_info = resp.json()   # expects { "username": "...", "password": "..." }

    # 3) merge new credentials into the existing secret payload
    new_data = { **current_data, **login_info }

    # 4) store this as the AWSPENDING version
    secrets_client.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(new_data),
        VersionStages=['AWSPENDING']
    )
    logger.info("createSecret: stored merged secret in AWSPENDING")


def set_secret(secret_id, token):
    # no-op since creation is handled in create_secret
    logger.info("setSecret: no action needed")


def test_secret(secret_id, token):
    # fetch the pending secret payload
    resp = secrets_client.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    data = json.loads(resp['SecretString'])
    # Required DB connection parameters
    host     = data['host']
    port     = data['port']
    dbname   = data['dbname']
    user     = data['username']
    password = data['password']
    engine   = data.get('engine', 'postgresql')

    logger.info("testSecret: attempting DB connection (user, host, port, dbname redacted)")

    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
            connect_timeout=5
        )
        conn.close()
        logger.info("testSecret: DB connection successful")
    except Exception as e:
        logger.error("testSecret: DB connection failed", exc_info=True)
        raise RuntimeError("testSecret failed: could not connect to DB") from e

def finish_secret(secret_id, token):
    # 1) find old AWSCURRENT version
    meta = secrets_client.describe_secret(SecretId=secret_id)
    old_ver = next(
        (v for v, s in meta['VersionIdsToStages'].items()
         if 'AWSCURRENT' in s),
        None
    )

    # 2) if an old version exists, delete its login
    if old_ver:
        old = secrets_client.get_secret_value(
            SecretId=secret_id,
            VersionId=old_ver
        )
        old_data = json.loads(old['SecretString'])
        tenant   = old_data['tenantId']
        old_user = old_data['username']
        print(old_user)

        delete_resp = requests.delete(
            f"{API_BASE}/api/admin/tenant/{tenant}/logins",
            headers=STATIC_HEADERS,
            json={ "Email": "SecretManagerLambdaRotation", "Data": old_user },
            timeout=10
        )
        delete_resp.raise_for_status()
        logger.info("finishSecret: deleted old Postgres login")

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
