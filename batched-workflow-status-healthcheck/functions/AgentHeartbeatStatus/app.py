import boto3
import os
import json
from opensearchpy import OpenSearch,RequestsHttpConnection
from datetime import datetime, timedelta, timezone
from time import time
import redis
import urllib3

current_month_year = datetime.utcnow().strftime('%Y-%m')
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
    if 'tenantId' not in body or 'agentId' not in body:
        return {
            'statusCode': 400,
            'body': json.dumps({'msg': 'Missing required fields: tenantId or agentId'})
        }
    else:
        conn = redis_connection()
        try:
            if body['getFailureDetails'] == False and body['hardReload'] == False:
                try:
                    return {
                        'statusCode': 200,
                        'body': json.dumps({'healthy': redis_get_data(conn,TenantId=body['tenantId'],WorkflowKey='AgentHeartbeat')})
                    }
                except Exception as e:
                    print(f"Redis fetch failed: {e}")
                    response = get_heartbeat_status_for_tenant(body['agentId'], body.get('DWAgentName'), body.get('tenantId'))
            elif body['getFailureDetails'] == False and body['hardReload'] == True:
                response = get_heartbeat_status_for_tenant(body['agentId'], body.get('DWAgentName'), body.get('tenantId'))
            elif body['getFailureDetails'] == True and body['hardReload'] == True:
                response = get_heartbeat_status_for_tenant(body['agentId'], body.get('DWAgentName'), body.get('tenantId'))
            else:
                return {
                    'statusCode': 200,
                    'body': 'Condition not Allowed.'
                }
        except Exception as e:
            print(f"Fetching Status with Default Option.")
            response = get_heartbeat_status_for_tenant(body['agentId'], body.get('DWAgentName'), body.get('tenantId'))

        # Store error message if response is not True
        error_message = None
        print(f"Healthcheck response: {response}")
        if response != True:
            # If response is a dictionary (exception message), extract the message
            if isinstance(response, dict) and 'message' in response:
                error_message = response['message']
            elif isinstance(response, str):
                error_message = response
            elif response == False:
                error_message = "Agent Connectivity missing"
            else:
                error_message = 'Health check failed'

        # Send webhook notification if unhealthy
        if response != True:
            send_to_webhook(
                healthcheck_type='AgentHeartbeat',
                tenant_id=body['tenantId'],
                agent_id=body.get('agentId'),
                agent_name=body.get('agentName'),
                tenant_name=body.get('tenantName'),
                failure_details=error_message
            )

        # Determine agent type based on DWAgentName presence
        agent_type = "Cloud Agent" if body.get('DWAgentName') else "On-Premise Agent"
        
        redis_put_data(
            conn,
            TenantId=body['tenantId'],
            WorkflowKey='AgentHeartbeat',
            WorkflowValue=(str(response)).lower(),
            ErrorMessage=error_message,
            AgentType=agent_type
        )
        redis_get_and_put_general_historic_data(conn,TenantId=body['tenantId'])

        return {
            'statusCode': 200,
            'body': json.dumps({'healthy': response})
        }

def send_to_webhook(healthcheck_type, tenant_id, agent_id=None, agent_name=None, tenant_name=None, failure_details=None):
    """Send unhealthy status notification to webhook"""
    webhook_url = os.environ.get('WEBHOOK_URL')
    
    if not webhook_url:
        print("WARNING: WEBHOOK_URL not configured. Skipping webhook notification.")
        return
    
    # Build title with tenant name and workflow
    # tenant_display = tenant_name if tenant_name else f"TenantID: {tenant_id}"
    agent_info = f" - Agent: {agent_name or agent_id}" if agent_id else ""
    
    payload = {
        "Title": f"🔴 - {healthcheck_type}{agent_info}",
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

def redis_put_data(r,TenantId,WorkflowKey,WorkflowValue,ErrorMessage=None,AgentType=None):
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
                
                # Store AgentType if provided
                if AgentType:
                    data_to_store['AgentType'] = AgentType
                
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
    history_data = r.get("AgentHeartbeatHistoricData-"+TenantId)
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
    r.set("AgentHeartbeatHistoricData-"+TenantId, json.dumps(history_list))

def redis_get_data(r,TenantId,WorkflowKey):
    redis_key = "TenantHealthJSON-"+TenantId
    existing_data = r.get(redis_key)
    if existing_data:
        data = json.loads(existing_data)
        return data.get(WorkflowKey), data.get(WorkflowKey+"_SuccessCount")
    return None, None

def redis_get_and_put_general_historic_data(r,TenantId):
    list_data = r.get("AgentHeartbeatHistoricData-"+TenantId)
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
                
                data_to_store['AgentHeartbeat_SuccessCount'] = success_count
                
                pipe.multi()
                pipe.set(redis_key, json.dumps(data_to_store))
                pipe.execute()
                break
        except redis.WatchError:
            if attempt == max_retries - 1:
                print(f"Failed to update success count after {max_retries} attempts")
            continue

def get_heartbeat_status_for_tenant(agent_id, dw_agent_name=None, tenant_id=None):
    conn = es_connection()
    
    # If DWAgentName is provided, check cloud_agent flow only
    if dw_agent_name:
        # Check for cloud_agent completed message
        print(f"Checking cloud_agent heartbeat for AgentID: {agent_id}, TenantID: {tenant_id}")
        query = {"query":{"bool":{"must":[{"term":{"app_name.keyword":"cloud_agent"}},{"term":{"agent_id.keyword":agent_id}},{"term":{"message.keyword":"completed"}},{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}}, "sort":[{"@timestamp":{"order":"desc"}}]}
        resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
        
        if resp['hits']['total']['value'] > 0:
            # Completed message found, check for exceptions
            print(f"Completed message found for cloud_agent. Checking exceptions for TenantID: {tenant_id}")
            cloud_cid_values = get_cloud_agent_cid(tenant_id)
            
            if cloud_cid_values:
                print(f"Checking cloud_agent status for TenantID: {tenant_id} with CIDs: {cloud_cid_values}")
                cloud_status = get_cloud_agent_status(cloud_cid_values)
                if cloud_status != True:
                    return cloud_status
            
            # No exceptions found, now check DWCoordinator status
            print(f"No exceptions found for cloud_agent. Checking DWCoordinator for TenantName: {dw_agent_name}")
            return check_dw_coordinator_status(dw_agent_name)
        else:
            # No completed message found, fetch latest CID and check for exceptions
            cloud_cid_values = get_cloud_agent_cid(tenant_id)
            
            if cloud_cid_values:
                cloud_status = get_cloud_agent_status(cloud_cid_values)
                if cloud_status != True:
                    return cloud_status
            
            # No CID or no exceptions found
            return False
    
    # On-premise agent flow (no DWAgentName)
    # First check for heartbeat in dataingestionapi
    query = {"query":{"bool":{"must":[{"term":{"fields.agentId.keyword":agent_id}},{"term":{"fields.summary.keyword":"Hearbeat recieved"}},{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}}, "sort":[{"@timestamp":{"order":"desc"}}]}
    resp = conn.search(index="dataingestionapi-"+current_month_year+"*",body=query)
    print(resp)
    if resp['hits']['total']['value'] > 0:
        # Heartbeat found, now check for sync-agent exceptions
        cid_values = get_onprem_cid(agent_id)
        
        if cid_values:
            # Check status for this CID
            onprem_status = get_onprem_status(cid_values)
            if onprem_status != True:
                return onprem_status
        
        # No exceptions found
        return True

def get_onprem_cid(agent_id):
    """Get latest CID for sync-agent (on-premise agent)"""
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"term":{"app_name.keyword":"sync-agent"}},{"term":{"agent_id.keyword":agent_id}},{"exists":{"field":"cid"}},{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}],"must_not":[{"term":{"cid.keyword":""}}]}},"aggs":{"unique_cids":{"terms":{"field":"cid.keyword","size":1,"order":{"latest_event":"desc"}},"aggs":{"latest_event":{"max":{"field":"@timestamp"}}}}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    cid_values = list(map(lambda i: i['key'], resp['aggregations']['unique_cids']['buckets']))
    return cid_values

def get_onprem_status(cid):
    """Check status for sync-agent CID"""
    print(f"Checking status for sync-agent CID: {cid}")
    if cid == []:
        return True  # No CID means no sync activity, but heartbeat is working
    
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"sync-agent"}},{"term":{"type.keyword":"exception"}}],"must_not":[{"term":{"ex_type.keyword":"OdbcException"}}],"filter":[{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}},"aggs":{"exception_count":{"value_count":{"field":"type.keyword"}}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    
    exception_count = resp['aggregations']['exception_count']['value']
    print(f"Sync-agent CID - {cid} has exception_count (excluding OdbcException) - {exception_count}")
    
    if exception_count > 0:
        return str(get_sync_agent_exception_message(cid))
    else:
        return True  # No exceptions (or only OdbcException which we ignore)

def get_sync_agent_exception_message(cid):
    """Get exception message for sync-agent"""
    conn = es_connection()
    query = {"_source":["message"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"sync-agent"}},{"term":{"type.keyword":"exception"}}],"must_not":[{"term":{"ex_type.keyword":"OdbcException"}}],"filter":[{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)['hits']['hits'][0]['_source']
    return resp

def get_cloud_agent_cid(tenant_id):
    """Get latest CID for cloud_agent by tenant_id"""
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"term":{"app_name.keyword":"cloud_agent"}},{"term":{"tid.keyword":tenant_id}},{"exists":{"field":"cid"}},{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}],"must_not":[{"term":{"cid.keyword":""}}]}},"aggs":{"unique_cids":{"terms":{"field":"cid.keyword","size":1,"order":{"latest_event":"desc"}},"aggs":{"latest_event":{"max":{"field":"@timestamp"}}}}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    cid_values = list(map(lambda i: i['key'], resp['aggregations']['unique_cids']['buckets']))
    return cid_values

def get_cloud_agent_status(cid):
    """Check status for cloud_agent CID"""
    print(f"Checking status for cloud_agent CID: {cid}")
    if cid == []:
        return True  # No CID means no cloud agent activity
    
    conn = es_connection()
    query = {"_source":"false","size":0,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"cloud_agent"}},{"term":{"type.keyword":"exception"}}],"filter":[{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}},"aggs":{"exception_count":{"value_count":{"field":"type.keyword"}}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    
    exception_count = resp['aggregations']['exception_count']['value']
    print(f"Cloud_agent CID - {cid} has exception_count - {exception_count}")
    
    if exception_count > 0:
        return str(get_cloud_agent_exception_message(cid))
    else:
        return True  # No exceptions

def get_cloud_agent_exception_message(cid):
    """Get exception message for cloud_agent"""
    conn = es_connection()
    query = {"_source":["message"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"terms":{"cid.keyword":cid}},{"term":{"app_name.keyword":"cloud_agent"}},{"term":{"type.keyword":"exception"}}],"filter":[{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)['hits']['hits'][0]['_source']
    return resp

def check_dw_coordinator_status(dw_agent_name):
    """Check DWCoordinator status for the given tenant name"""
    print(f"Checking DWCoordinator status for TenantName: {dw_agent_name}")
    conn = es_connection()
    
    # Check for DWCoordinator message in last 1 hour
    query = {"_source":["message","@timestamp"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"term":{"app_name.keyword":"DWCoordinator"}},{"term":{"TenantName.keyword":dw_agent_name}},{"range":{"@timestamp":{"gte":"now-1h","lte":"now"}}}]}}}
    resp = conn.search(index="batched-logs-*",body=query)
    
    if resp['hits']['total']['value'] > 0:
        message = resp['hits']['hits'][0]['_source']['message']
        print(f"DWCoordinator message found: {message}")
        
        if "completed" in message.lower():
            return True
        elif "failed" in message.lower():
            # Look for last completed in 24 hours
            return get_last_completed_dw_coordinator(dw_agent_name)
    
    # No message found in last hour, check last 24 hours for completed
    return "Datawarehouse is Outdated"

def get_last_completed_dw_coordinator(dw_agent_name):
    """Get last completed timestamp for DWCoordinator in 24 hours"""
    print(f"Looking for last completed DWCoordinator in 24hrs for TenantName: {dw_agent_name}")
    conn = es_connection()
    
    query = {"_source":["@timestamp"],"size":1,"sort":[{"@timestamp":{"order":"desc"}}],"query":{"bool":{"must":[{"term":{"app_name.keyword":"DWCoordinator"}},{"term":{"TenantName.keyword":dw_agent_name}},{"match":{"message":"completed"}},{"range":{"@timestamp":{"gte":"now-24h","lte":"now"}}}]}}}
    resp = conn.search(index="batched-logs-"+current_month_year+"*",body=query)
    
    if resp['hits']['total']['value'] > 0:
        timestamp = resp['hits']['hits'][0]['_source']['@timestamp']
        # Convert ISO timestamp to epoch
        epoch_time = int(datetime.fromisoformat(timestamp.replace('Z', '+00:00')).timestamp())
        return f"Last Refreshed {epoch_time}"
    else:
        return "Not able to fetch messages from DWCoordinator"

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