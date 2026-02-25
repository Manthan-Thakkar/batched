from datetime import datetime
import boto3
from botocore.exceptions import ClientError
import os

session = boto3.Session()

def get_parameter(parameter_name, with_decryption):
    """Get parameter details in AWS SSM

    :param parameter_name: Name of the parameter to fetch details from SSM
    :param with_decryption: return decrypted value for secured string params, ignored for String and StringList
    :return: Return parameter details if exist else None
    """

    ssm_client = session.client('ssm')

    try:
        result = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=with_decryption
        )
    except ClientError as e:
        #logging.error(e)
        print(e)
        return None
    return result