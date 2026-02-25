import os
import boto3
from datetime import datetime

def lambda_handler(event,context):
    delete_old_snapshots(event['rds_db_name'])
    rds_db_name = event['rds_db_name']
    date_today=datetime.utcnow().strftime("%Y-%m-%d")
    client = boto3.client('rds')
    try:
        response = client.create_db_snapshot(
            DBSnapshotIdentifier=rds_db_name+'-snapshot-'+date_today,
            DBInstanceIdentifier=rds_db_name,
            Tags=[
                {
                    'Key': 'Manual Backup Date',
                    'Value': date_today
                }
            ]
        )
    except Exception as e:
        response = str(e)
    notifyStatus(response,rds_db_name)

def notifyStatus(response,db_name):
    try:
        message = f"""Weekly RDS Manual Backup Status

        Database Name -> {str(response['DBSnapshot']["DBInstanceIdentifier"])}
        Snapshot Name -> {str(response['DBSnapshot']['DBSnapshotIdentifier'])}
        RDS Engine -> {str(response['DBSnapshot']['Engine'])}
        Storage Size -> {str(response['DBSnapshot']['AllocatedStorage'])}
        Current State of Backup -> {str(response['DBSnapshot']['Status'])}

        """
        send_teams_notification(message)
    except:
        message = f"""Weekly Manual Snapshot Service
        
        Database Name -> {str(db_name)}
        Backup Exception -> {str(response)}
        """
        send_teams_notification(message)

def send_teams_notification(message):
    sns_client = boto3.client('sns')
    if os.environ['environment'] == 'DEV':
        subject = 'DEV - Weekly DB Backup Notification'
    elif os.environ['environment'] == 'PROD':
        subject = 'PROD - Weekly DB Backup Notification'
    response = sns_client.publish(
        TopicArn=os.environ['teams_sns_topic_arn'],
        Message=message,
        Subject=subject
    )
    print(response)

def delete_old_snapshots(db_instance_identifier):
    client = boto3.client('rds')
    snapshots = client.describe_db_snapshots(
        DBInstanceIdentifier=db_instance_identifier,
        SnapshotType='manual',
        MaxRecords=20
    )['DBSnapshots']
    snapshots.sort(key=lambda x: x['SnapshotCreateTime'], reverse=True)
    # Check if there are more than 2 snapshots
    number_of_snapshots_to_keep = 2
    if len(snapshots) > number_of_snapshots_to_keep:
        # Delete all older snapshots, keep the latest 2
        for snapshot in snapshots[number_of_snapshots_to_keep:]:
            snapshot_identifier = snapshot['DBSnapshotIdentifier']
            try:
                client.delete_db_snapshot(DBSnapshotIdentifier=snapshot_identifier)
                print(f"Deleted snapshot: {snapshot_identifier}")
            except Exception as e:
                print(f"Error deleting snapshot {snapshot_identifier}: {e}")