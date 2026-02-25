import boto3
import os
import json
from opensearchpy import OpenSearch,RequestsHttpConnection
from datetime import datetime, timedelta, timezone
from time import time
import redis
import urllib3

current_month_year = (datetime.utcnow() - timedelta(hours=int(os.environ['ES_DURATION'][:-1]))).strftime('%Y-%m')
http = urllib3.PoolManager()

def lambda_handler(event, context):
    # Handle both SQS and ALB events
    if 'Records' in event:
        # SQS event - extract body from the first record
        sqs_message = event['Records'][0]
        body = json.loads(sqs_message['body'])
        print(f"Processing SQS message: {body}")
    elif 'body' in event and event.get('httpMethod') == 'POST':
        # ALB event
        body = json.loads(event['body'])
        print(f"Processing ALB request: {body}")
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({'msg': 'Bad Request - Invalid event source'})
        }

    # Validate required fields
    if 'tenantId' not in body:
        return {
            'statusCode': 400,
            'body': json.dumps({'msg': 'Missing required field: tenantId'})
        }

    else:
        conn = redis_connection()
        try:
            if body['getFailureDetails'] == False and body['hardReload'] == False:
                try:
                    return {
                        'statusCode': 200,
                        'body': json.dumps({'healthy': redis_get_data(conn,TenantId=body['tenantId'],WorkflowKey='RulesStepExecution')})
                    }
                except Exception as e:
                    print(f"Redis fetch failed: {e}")
                    response = get_status_for_tenant(body['tenantId'],body)
            elif body['getFailureDetails'] == False and body['hardReload'] == True:
                response = get_status_for_tenant(body['tenantId'],body)
            elif body['getFailureDetails'] == True and body['hardReload'] == True:
                response = get_status_for_tenant(body['tenantId'],body)
            else:
                return {
                    'statusCode': 200,
                    'body': 'Condition not Allowed.'
                }
        except Exception as e:
            print(f"Fetching Status with Default Option.")
            response = get_status_for_tenant(body['tenantId'],body)

        # Store error message if response is not True
        error_message = None
        if response != True:
            error_message = str(response) if isinstance(response, str) else 'Health check failed'
            # Send webhook notification if unhealthy
            send_to_webhook(
                healthcheck_type='RulesStepExecution',
                tenant_id=body['tenantId'],
                tenant_name=body.get('tenantName'),
                failure_details=error_message
            )
            # Replace "No Latest CID Found" with custom message
            if "No Latest CID Found" in error_message:
                error_message = "Business Rules Execution missing"
            redis_put_data(
                conn,
                TenantId=body['tenantId'],
                WorkflowKey='RulesStepExecution',
                WorkflowValue='false',
                ErrorMessage=error_message
            )
            redis_get_and_put_general_historic_data(conn,TenantId=body['tenantId'])
        else:
            redis_put_data(
                conn,
                TenantId=body['tenantId'],
                WorkflowKey='RulesStepExecution',
                WorkflowValue=(str(response)).lower()
            )
            redis_get_and_put_general_historic_data(conn,TenantId=body['tenantId'])

        return {
            'statusCode': 200,
            'body': json.dumps({'healthy': response})
        }

def send_to_webhook(healthcheck_type, tenant_id, tenant_name=None, failure_details=None):
    """Send unhealthy status notification to webhook"""
    webhook_url = os.environ.get('WEBHOOK_URL')
    
    if not webhook_url:
        print("WARNING: WEBHOOK_URL not configured. Skipping webhook notification.")
        return
    
    # Build title with tenant name and workflow
    tenant_display = tenant_name if tenant_name else f"TenantID: {tenant_id}"
    
    payload = {
        "Title": f"🔴  {tenant_display} - {healthcheck_type}",
        "Body": failure_details or "Health check failed",
        "AlertType": "default"
    }
    
    try:
        response = http.request(
            'POST',
            webhook_url,
            body=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            timeout=5.0
        )
        print(f"Webhook notification sent. Status: {response.status}")
    except Exception as e:
        print(f"Failed to send webhook: {e}")

def redis_connection():
    r = redis.Redis(os.environ['redis_host'],decode_responses=True,ssl=True)
    return r

def redis_put_data(r,TenantId,WorkflowKey,WorkflowValue,ErrorMessage=None):
    redis_key = "TenantHealthJSON-"+TenantId
    max_retries = 4
    
    for attempt in range(max_retries):
        try:
            # Watch the key for changes
            with r.pipeline() as pipe:
                pipe.watch(redis_key)
                
                # Get current data
                existing_data = pipe.get(redis_key)
                if existing_data:
                    data_to_store = json.loads(existing_data)
                else:
                    data_to_store = {}
                
                # Update workflow status
                data_to_store[WorkflowKey] = WorkflowValue
                
                # Handle error message
                if ErrorMessage:
                    data_to_store[WorkflowKey + '_ErrorMessage'] = ErrorMessage
                else:
                    data_to_store.pop(WorkflowKey + '_ErrorMessage', None)
                
                # Execute transaction
                pipe.multi()
                pipe.set(redis_key, json.dumps(data_to_store))
                pipe.execute()
                break  # Success
        except redis.WatchError:
            # Key was modified, retry
            if attempt == max_retries - 1:
                print(f"Failed to update Redis after {max_retries} attempts")
                raise
            continue
    
    if WorkflowValue == 'true':
        MetricValue = 1
    else:
        MetricValue = 0
    # put_metric_data(TenantId,WorkflowKey,MetricValue)

    ############ HISTORIC DATA #######################

    timestamp = int(time())  # Current epoch time
    history_data = r.get("RulesStepExecutionHistoricData-"+TenantId)
    if history_data:
        history_list = json.loads(history_data)
    else:
        history_list = []
    # Create the new entry
    if WorkflowValue == "true":
        new_entry = {
            "index": 0,
            "timestamp": timestamp,
            "status": True,
            "error_message": ""
        }
    else:
        new_entry = {
            "index": 0,
            "timestamp": timestamp,
            "status": False,
            "error_message": ErrorMessage or ""
        }
    # Update indices of the existing entries
    for entry in history_list:
        entry["index"] += 1
    # Insert the new entry at the beginning
    history_list.insert(0, new_entry)
    # Trim the list to keep at most 10 entries
    history_list = history_list[:10]
    # Save the updated list back to Redis
    r.set("RulesStepExecutionHistoricData-"+TenantId, json.dumps(history_list))

def redis_get_data(r,TenantId,WorkflowKey):
    redis_key = "TenantHealthJSON-"+TenantId
    existing_data = r.get(redis_key)
    if existing_data:
        data = json.loads(existing_data)
        return data.get(WorkflowKey), data.get(WorkflowKey+"_SuccessCount")
    return None, None

def redis_get_and_put_general_historic_data(r,TenantId):
    list_data = r.get("RulesStepExecutionHistoricData-"+TenantId)
    decoded_data = json.loads(list_data)
    statuses = [entry['status'] for entry in decoded_data]
    success_count = str(sum(statuses))+"/"+str(len(statuses))
    
    redis_key = "TenantHealthJSON-"+TenantId
    max_retries = 4
    
    for attempt in range(max_retries):
        try:
            with r.pipeline() as pipe:
                pipe.watch(redis_key)
                
                existing_data = pipe.get(redis_key)
                if existing_data:
                    data_to_store = json.loads(existing_data)
                else:
                    data_to_store = {}
                
                data_to_store['RulesStepExecution_SuccessCount'] = success_count
                
                pipe.multi()
                pipe.set(redis_key, json.dumps(data_to_store))
                pipe.execute()
                break
        except redis.WatchError:
            if attempt == max_retries - 1:
                print(f"Failed to update success count after {max_retries} attempts")
            continue

def get_status_for_tenant(tenant_id,body):
    cid_list = get_cid(tenant_id)
    print(cid_list)
    return get_status(cid_list,body)

def get_cid(tenant_id):
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}]\
            ,"query":{"bool":{"must":[{"term":{"app_name.keyword":"rules-web"}},{"term":{"message.keyword":"Eval-Completed"}},{"term":{"tid.keyword":tenant_id}}\
            ,{"range":{"@timestamp":{"gte":"now-"+str(os.environ['ES_DURATION'])+"/d","lte":"now/d"}}}]}}\
            ,"aggs":{"unique_cids":{"terms":{"field":"cid.keyword","size":1,"order":{"latest_event":"desc"}},"aggs":{"latest_event":{"max":{"field":"@timestamp"}}}}}}

    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    cid_values = list(map(lambda i: i['key'], resp['aggregations']['unique_cids']['buckets']))
    return cid_values

def get_status(cid,body):
    print(cid)
    if cid == []:
        return " No Latest CID Found in Past "+str(os.environ['ES_DURATION'])
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"rules-web"}},{"term":{"message.keyword":"Eval-Completed"}},{"range":{"@timestamp":{"gte":"now-"+str(os.environ['ES_DURATION'])+"/d","lte":"now/d"}}}]}},"aggs":{"unique_status":{"terms":{"field":"status.keyword","size":100,"order":{"latest_event":"desc"}},"aggs":{"latest_event":{"max":{"field":"@timestamp"}}}}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)

    status_values = list(map(lambda i: i['key'], resp['aggregations']['unique_status']['buckets']))
    print("CID - "+str(cid)+ " has status_values - "+str(status_values))
    if 'failure' in status_values:
        try:
            if body['getFailureDetails'] == False:
                return False
        except:
            return str(get_failure_message(cid))
    else:
        return True

def get_failure_message(cid):
    conn = es_connection()
    query = {"_source":["errorMessage"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"rules-web"}},{"term":{"message.keyword":"Eval-Completed"}},{"term":{"status.keyword":"failure"}},{"range":{"@timestamp":{"gte":"now-"+str(os.environ['ES_DURATION'])+"/d","lte":"now/d"}}}]}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)['hits']['hits'][0]['_source']
    return resp

def put_metric_data(TenantId,WorkflowKey,WorkflowValue):
    cloudwatch = boto3.client('cloudwatch')
    response = cloudwatch.put_metric_data(
    Namespace="TenantHealthWorkflows",  # Custom namespace
    MetricData=[
        {
            'MetricName': 'Status',
            'Dimensions': [
                {'Name': 'TenantID', 'Value': TenantId},  # Tenant dimension
                {'Name': 'WorkflowName', 'Value': WorkflowKey}  # Workflow dimension
            ],
            'Timestamp': datetime.now(timezone.utc),
            'Value': int(WorkflowValue),
            'Unit': 'Count'
        }
    ]
    )

def fetchDBSecret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
    SecretId=secret_name,
    )
    return json.loads(response['SecretString'])

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