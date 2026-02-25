import argparse
import json
import logging
import sys

import boto3
from botocore.exceptions import ClientError

# Configure logging
template = "%(asctime)s %(levelname)-8s %(message)s"
logging.basicConfig(format=template, level=logging.INFO)
logger = logging.getLogger(__name__)


def migrate_secret_to_ssm(secret_name: str, region: str = None, prefix: str = None):
    """
    Fetch a secret from AWS Secrets Manager and store each key/value pair
    as a SecureString parameter in AWS Systems Manager Parameter Store.

    :param secret_name: Name (or ARN) of the Secrets Manager secret.
    :param region: AWS region (e.g. 'us-east-1'). If None, uses default boto3 region.
    :param prefix: Optional path prefix for SSM parameters; defaults to secret_name.
    """
    # Initialize clients
    session_args = {} if region is None else {'region_name': region}
    session = boto3.Session(**session_args)
    secrets_client = session.client('secretsmanager')
    ssm_client = session.client('ssm')

    # Retrieve secret value
    try:
        logger.info(f"Retrieving secret '{secret_name}'")
        resp = secrets_client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        logger.error(f"Unable to fetch secret {secret_name}: {e}")
        sys.exit(1)

    # Parse secret string (JSON)
    try:
        secret_str = resp.get('SecretString')
        if not secret_str:
            raise ValueError("SecretString is empty or missing.")
        data = json.loads(secret_str)
    except Exception as e:
        logger.error(f"Error parsing secret JSON for {secret_name}: {e}")
        sys.exit(1)

    # Determine SSM parameter prefix
    param_prefix = prefix.rstrip('/') if prefix else secret_name.rstrip('/')

    # Iterate and store
    for key, value in data.items():
        param_name = f"/{param_prefix}/{key}"
        try:
            logger.info(f"Putting SSM parameter '{param_name}'")
            ssm_client.put_parameter(
                Name=param_name,
                Value=str(value),
                Type='String',
                Overwrite=True,
            )
        except ClientError as e:
            logger.error(f"Failed to put parameter {param_name}: {e}")
            continue

    logger.info("Migration complete.")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Migrate AWS Secrets Manager JSON secrets into SSM Parameter Store.'
    )
    parser.add_argument('--secret-name', '-s', required=True,
                        help='Name or ARN of the source secret in Secrets Manager')
    parser.add_argument('--region', '-r', required=False,
                        help='AWS region (default from environment)')
    parser.add_argument('--prefix', '-p', required=False,
                        help='Optional prefix path for SSM parameters (default: secret name)')
    args = parser.parse_args()

    migrate_secret_to_ssm(
        secret_name=args.secret_name,
        region=args.region,
        prefix=args.prefix
    )
