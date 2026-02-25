import os
import json
import sqlalchemy as sa
from datetime import datetime, timezone
import time
import boto3
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

def create_DB_Backup(event,context):
    create_backup_db_name = event['db_name']
    date_today=datetime.utcnow().strftime("%Y-%m-%d")
    current_time=datetime.utcnow().strftime('%H-%M')
    db_connection_values = fetchDBSecret(os.environ['rds_secret_name'])
    rds_engine = sa.create_engine('mssql+pyodbc://'+db_connection_values['username']+':'+db_connection_values['password']+'@'+db_connection_values['host']+'/batched?driver=ODBC+Driver+18+for+SQL+Server',connect_args={'autocommit': True})
    connection = rds_engine.raw_connection()
    sql = "exec [msdb].[dbo].[rds_backup_database] '"+create_backup_db_name+"', 'arn:aws:s3:::"+os.environ['storage_bucket_name']+"/"+date_today+"/"+create_backup_db_name+"/"+create_backup_db_name+"-"+date_today+"-"+current_time+".bak'"
    try:
        cursor = connection.cursor()
        result = cursor.execute(sql)
        output_data = list(result.fetchall()[0])
        cursor.close()
        log_data(log_level='INFO',status='Success',db_name=create_backup_db_name,step='TaskCreation',task_id='ID '+str(output_data[0]),s3_arn=output_data[6],message='Backup Task Created Successfully')
        return {
            'task_id' : output_data[0],
            'task_type' : output_data[1],
            'task_lifecycle' : output_data[2],
            'db_name' : create_backup_db_name,
            's3_arn' : output_data[6],
            'Exception' : None
        }
    except Exception as e:
        log_data(log_level='ERROR',status='Failure',db_name=create_backup_db_name,step='TaskCreation',task_id=None,s3_arn=None,message='Backup Task Error '+str(e),Exception=str(e))
        return {
            'task_id' : None,
            'task_type' : None,
            'task_lifecycle' : None,
            's3_arn' : None,
            'db_name' : create_backup_db_name,
            'Exception' : str(e)
        }
    finally:
        connection.close()

def fetchDBSecret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(
    SecretId=secret_name,
    )
    return json.loads(response['SecretString'])