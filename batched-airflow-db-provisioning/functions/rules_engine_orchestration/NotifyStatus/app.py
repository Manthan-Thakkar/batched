import boto3
import os
import json
from opensearchpy import OpenSearch,RequestsHttpConnection
from datetime import datetime, timedelta, timezone
from time import time

current_month_year = (datetime.utcnow()).strftime('%Y-%m')

def notifyStatus(event,context):
    try:
        if event.get('stepsDetails', {}).get('stepStatus') == 'ERROR':
            error_message = get_failure_message(str(event['CorrelationId']))
            print(error_message)
            send_failure_email(event['TenantId'],event['CorrelationId'],event['stepsDetails']['stepStatus'],error_message,None)
            return {
                'fail_message_sent' : True
            }
        elif event.get('Error', {}) == 'Exception':
            send_failure_email(None,None,None,None,event.get('Cause'))
            return {
                'exception_handled': True
            }
        else:
            return {
                'workflow_success' : True
            }
    except Exception as e:
        try:
            send_failure_email(event['TenantId'],event['CorrelationId'],event['stepsDetails']['stepStatus'],None,e)
        except:
            send_failure_email(None,None,None,None,e)
        raise e

def get_failure_message(cid):
    conn = es_connection()
    query = {"_source":["errorMessage"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":[cid]}},{"term":{"app_name.keyword":"rules-web"}},{"term":{"message.keyword":"Eval-Completed"}},{"term":{"status.keyword":"failure"}},{"range":{"@timestamp":{"gte":"now-1h/d","lte":"now/d"}}}]}}}
    try:
        resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)['hits']['hits'][0]['_source']
    except:
        resp = "Unable to Fetch Failure Message"
    return resp

def es_connection():
    es_connection_values = fetchDBSecret('batched-es-envs')
    es_conn = OpenSearch(
    hosts=es_connection_values['host'],
    http_auth=(es_connection_values['username'],es_connection_values['password']),
    timeout=60,
    connection_class = RequestsHttpConnection,
    scheme="https",
    verify_certs=True
    )

    return es_conn

def fetchDBSecret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
    SecretId=secret_name,
    )
    return json.loads(response['SecretString'])

def send_failure_email(tid,cid,task_status,error,Exception):
    message = f"""Hello Team,
    Failure Notification for RulesEngineOrchestration Step Function.

    TenantId - {tid}.
    Correlation ID - {cid}.
    Task Status - {task_status}.
    Error Message from RulesEngine - {error}
    NotifyLambdaException - {Exception}.


    """
    sns_client = boto3.client('sns')
    if os.environ['environment'] == 'DEV':
        subject = 'DEV - RulesEngineOrchestration Failure Notification'
    elif os.environ['environment'] == 'PROD':
        subject = 'PROD - RulesEngineOrchestration Failure Notification'
    response = sns_client.publish(
        TopicArn=os.environ['sns_topic_arn'],
        Message=message,
        Subject=subject
    )
    print(response)