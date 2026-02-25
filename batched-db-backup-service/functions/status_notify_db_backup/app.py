import os
import boto3
import pymsteams

def notifyStatus(event,context):
    s3_data = check_s3_file(event['s3_arn'])
    try:
        if event['Exception'] != None or 's3_object_exception' in s3_data:
            try:
                event_exception=str(event['Exception'])
            except:
                event_exception='Exception in s3_object_exception'
            try:
                s3_exception=s3_data['s3_object_exception']
            except:
                s3_exception=None
            message = f"""DB Backup Service Notification

            Database Name -> {str(event["db_name"])}
            Task ID -> {str(event['task_id'])}
            Task Status -> {str(event['task_status'])}
            Exception -> {event_exception}
            S3_Object_Exception -> {s3_exception}

            """
            send_teams_notification(message)
            send_failure_email(str(event["db_name"]),str(event["task_id"]),str(event["task_status"]),str(event_exception),str(s3_exception),str(event['task_info']))
        else:
            message = f"""DB Backup Service Notification
            
            Database Name -> {str(event["db_name"])}
            Task ID -> {str(event['task_id'])}
            Task Status -> {str(event['task_status'])}
            Duration (in mins) -> {str(event['duration'])}
            S3 BucketName -> {str(s3_data['bucket_name'])}
            S3 Object Key -> {str(s3_data['object_key'])}
            S3 Object Size -> {str(s3_data['object_size'])}

            """
            send_teams_notification(message)
            
    except Exception as e:
        event_exception=str(event['Exception'])
        message = f"""DB Backup Service Notification
        
        Database Name -> {str(event["db_name"])}
        Exception -> {event_exception}
        Notify Lambda Exception -> {str(e)}

        """
        send_teams_notification(message)
        send_failure_email(str(event["db_name"]),str(None),str(None),str(event_exception),str(e),str(None))

def check_s3_file(s3_arn):
    try:
        bucket_name = s3_arn.split(':::')[1].split('/')[0]
        key_name = s3_arn.split(':::')[1].split('/', 1)[1]
    except:
        bucket_name = None
        key_name = None
    s3_client = boto3.client('s3')
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=key_name)
        object_size_bytes = response['ContentLength']
        object_size_gb = round(object_size_bytes / (1024 ** 3),2)

        return {
            'bucket_name' : bucket_name,
            'object_key' : key_name,
            'object_size' : str(object_size_gb)+' GB'
        }
    except Exception as e:
        return {
            's3_object_exception' : str(e),
        }
    
def send_failure_email(db_name,task_id,task_status,Exception,S3_Object_Exception,task_info):
    message = f"""Hello Team,
    
    Failure Notification for Step Function DB Backup.


    Database Name - {db_name}.
    Task ID - {task_id}.
    Task Status - {task_status}.
    Exception - {Exception}.
    Notify Lambda or S3_Exception - {S3_Object_Exception}.
    Task Info - {task_info}



    """
    sns_client = boto3.client('sns')
    if os.environ['environment'] == 'DEV':
        subject = 'DEV - DB Backup Failure Notification'
    elif os.environ['environment'] == 'PROD':
        subject = 'PROD - DB Backup Failure Notification'
    response = sns_client.publish(
        TopicArn=os.environ['sns_topic_arn'],
        Message=message,
        Subject=subject
    )
    print(response)

def send_teams_notification(message):
    sns_client = boto3.client('sns')
    if os.environ['environment'] == 'DEV':
        subject = 'DEV - DB Backup Notification'
    elif os.environ['environment'] == 'PROD':
        subject = 'PROD - DB Backup Notification'
    response = sns_client.publish(
        TopicArn=os.environ['teams_sns_topic_arn'],
        Message=message,
        Subject=subject
    )
    print(response)