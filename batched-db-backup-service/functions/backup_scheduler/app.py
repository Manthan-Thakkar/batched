import os
import pandas as pd
import re
import sqlalchemy as sa
from datetime import datetime, timedelta, timezone
import boto3
import json
import pymsteams
from opensearchpy import OpenSearch,RequestsHttpConnection

def log_data(**kwargs):
    now = datetime.now(timezone.utc)
    es_connection_values = fetchDBSecret('batched-es-envs')
    es_conn = OpenSearch(
    hosts=es_connection_values['host'],
    http_auth=(es_connection_values['username'],es_connection_values['password']),
    timeout=60,
    connection_class = RequestsHttpConnection,
    scheme="https",
    verify_certs=True
    )
    timestamp = now.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + '000+00:00'
    kwargs['@timestamp'] = timestamp
    date_today = now.strftime('%Y-%m-%d')
    log_json = json.dumps(kwargs)
    try:
        response = es_conn.index(index='batched-manual-backup-logs-'+date_today, body=log_json)
        print(response)
    except Exception as e:
        raise e

def lambda_handler(event,context):
    db_connection_values = fetchDBSecret(os.environ['rds_secret_name'])
    rds_engine = sa.create_engine('mssql+pyodbc://'+db_connection_values['username']+':'+db_connection_values['password']+'@'+db_connection_values['host']+'/batched?driver=ODBC+Driver+18+for+SQL+Server')
    with rds_engine.connect() as connection:
        df = pd.read_sql_query('SELECT t.ID, t.Name, t.TimeZone, tz.Name AS TimeZoneName, db.DbName AS DbName FROM batched.dbo.Tenant t \
                            JOIN batched.dbo.Timezone tz ON t.TimeZone = tz.ID \
                            JOIN batched.dbo.TenantDatabase db on t.ID = db.TenantId \
                            WHERE t.IsEnabled = 1;', connection)
    extra_db_name = ['batched']
    df['utc_offsets'] = df['TimeZoneName'].apply(extract_utc_offset)
    df['utc_midnight'] = df['utc_offsets'].apply(calculate_utc_midnight)
    selected_columns_df = df[["Name","DbName", "utc_midnight"]]
    incremented_time_df = increment_time(selected_columns_df)
    schedule_info = []
    for index, row in incremented_time_df.iterrows():
        if row['DbName'] != 'nosco-nosco':
            information = event_scheduler(row['DbName'],row['utc_midnight'],os.environ['schedule_group_name'])
            schedule_info.append(information)
    for db_name in extra_db_name:
        information = event_scheduler(db_name,'00:00',os.environ['schedule_group_name'])
        schedule_info.append(information)
    notifyStatus(pd.DataFrame(schedule_info))

def increment_time(df):
    df['utc_midnight_dt'] = pd.to_datetime(df['utc_midnight'], format='%H:%M')
    df.sort_values(by='utc_midnight_dt', inplace=True)
    seen_times = {}
    increment = timedelta(minutes=3)
    for i, row in df.iterrows():
        original_time = row['utc_midnight_dt']
        if original_time in seen_times:
            new_time = original_time + increment * seen_times[original_time]
            df.at[i, 'utc_midnight_dt'] = new_time
            seen_times[original_time] += 1
        else:
            seen_times[original_time] = 1
    df['utc_midnight'] = df['utc_midnight_dt'].dt.strftime('%H:%M')
    df.drop(columns=['utc_midnight_dt'], inplace=True)
    
    return df

def event_scheduler(tenant_name,utc_midnight_time,scheduler_group):
    date_today=datetime.utcnow().strftime("%Y-%m-%d")
    client = boto3.client('scheduler')
    try:
        response = client.create_schedule(
            ActionAfterCompletion='DELETE',
            FlexibleTimeWindow={
                'Mode': 'OFF'
            },
            GroupName=scheduler_group,
            Name=str(tenant_name)+'-DB-Backup-Schedule',
            ScheduleExpression='at('+date_today+'T'+utc_midnight_time+':00)',
            Target={
                'Arn': os.environ['target_state_machine_arn'],
                'RoleArn': os.environ['start_execution_target_state_machine_role_arn'],
                'Input' : '{"db_name" : "'+str(tenant_name)+'"}'
            }
            )
        log_data(log_level='INFO',status='Success',db_name=tenant_name,step='Scheduler',message='EventBridge Schedule Created Successfully')
        return {
            'tenant_name': tenant_name,
            'scheduled' : str('True'),
            'utc_time' : str(date_today+'T'+utc_midnight_time+':00'),
            'Exception': None
        }
    except Exception as e:
        log_data(log_level='ERROR',status='Failure',db_name=tenant_name,step='Scheduler',message='EventBridge Schedule Error '+str(e),Exception=str(e))
        return {
            'tenant_name': tenant_name,
            'scheduled' : str('False'),
            'utc_time' : str(date_today+'T'+utc_midnight_time+':00'),
            'Exception': str(e)
        }

def fetchDBSecret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
    SecretId=secret_name,
    )
    return json.loads(response['SecretString'])

def extract_utc_offset(text):
    """
    Extracts the UTC offset (e.g., +10:00) from a string enclosed in parentheses.

    Args:
        text: The string containing the UTC offset information.

    Returns:
        The extracted UTC offset string (e.g., +10:00) or None if not found.
    """
    match = re.search(r"\(UTC([+-][\d:]+)\)", text)
    if match:
        return match.group(1)
    else:
        return '+00:00'

def calculate_utc_midnight(offset):
    sign = 1 if offset[0] == '+' else -1
    hours, minutes = map(int, offset[1:].split(':'))
    offset_hours = sign * (hours + minutes / 60)
    
    # Calculate UTC time for midnight in the given offset's timezone
    utc_midnight = (datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=offset_hours)).time()
    return utc_midnight.strftime('%H:%M')

def notifyStatus(df):
    sorted_df = df.sort_values(by="tenant_name")
    markdown_table = sorted_df.to_markdown(index=False)
    sns_client = boto3.client('sns')
    subject = "Manual Scheduler Status"
    message = f"{subject}\n\n{markdown_table}"
    response = sns_client.publish(
        TopicArn=os.environ['teams_sns_topic_arn'],
        Subject=subject,
        Message=message
    )
    print(response)