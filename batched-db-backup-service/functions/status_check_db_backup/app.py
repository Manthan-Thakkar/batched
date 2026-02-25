import os
import sqlalchemy as sa
import boto3
import json
from datetime import datetime, timezone
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
    date_today = now.strftime('%Y-%m-%d')
    kwargs['@timestamp'] = timestamp
    log_json = json.dumps(kwargs)
    try:
        response = es_conn.index(index='batched-manual-backup-logs-'+date_today, body=log_json)
        print(response)
    except Exception as e:
        raise e

def check_DB_Backup_Status(event,context):
    db_name = event['db_name']
    task_id = event['task_id']
    db_connection_values = fetchDBSecret(os.environ['rds_secret_name'])
    rds_engine = sa.create_engine('mssql+pyodbc://'+db_connection_values['username']+':'+db_connection_values['password']+'@'+db_connection_values['host']+'/batched?driver=ODBC+Driver+18+for+SQL+Server',connect_args={'autocommit': True})
    connection = rds_engine.raw_connection()
    sql = "exec msdb.dbo.rds_task_status '"+db_name+"',"+str(task_id)+""
    try:
        cursor = connection.cursor()
        result = cursor.execute(sql)
        output_data = list(result.fetchall()[0])
        cursor.close()
        log_data(log_level='INFO',status=str(output_data[5]),db_name=db_name,step='TaskStatus',task_id='ID '+str(task_id),task_info=str(output_data[6]),s3_arn=output_data[9],duration=str(output_data[4])+" min",message='Check Backup Task Status - '+str(output_data[5]))
        return {
            'task_id' : task_id,
            'db_name' : db_name,
            'task_type' : str(output_data[1]),
            'duration' : str(output_data[4]),
            'task_status' : str(output_data[5]),
            'task_info': str(output_data[6]),
            's3_arn': str(output_data[9]),
            'Exception' : None
        }
    except Exception as e:
        log_data(log_level='ERROR',status='Failure',db_name=db_name,step='TaskStatus',task_id=task_id,message='Check Backup Task Error - '+str(e))
        return {
            'task_id' : task_id,
            'db_name' : db_name,
            'task_status' : "ERROR",
            'Exception' : str(e)
        }

def fetchDBSecret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
    SecretId=secret_name,
    )
    return json.loads(response['SecretString'])