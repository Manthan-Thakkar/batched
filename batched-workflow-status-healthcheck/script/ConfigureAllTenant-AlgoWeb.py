import json
import sqlalchemy as sa
import pandas as pd
import boto3
from botocore.exceptions import ClientError

# Configuration
REGION = 'us-east-2'  # Update to your region
SCHEDULER_GROUP_NAME = 'algoweb-healthcheck-schedules'
SQS_QUEUE_ARN = 'arn:aws:sqs:us-east-2:<AccountID>:AlgoWeb-HealthCheck.fifo'  # Update with actual ARN
SCHEDULER_ROLE_ARN = 'arn:aws:iam::<AccountID>:role/EventBridgeSchedulerToSQSRole'  # Update with actual role ARN

scheduler_client = boto3.client('scheduler', region_name=REGION)

def get_all_tenants():
    """Fetch all enabled tenants from the database"""
    rds_engine = sa.create_engine('mssql+pyodbc://<Username>:<Password>@<endpoint>/batched?driver=ODBC+Driver+17+for+SQL+Server')
    with rds_engine.connect() as connection:
        df = pd.read_sql_query('SELECT t.ID as tenantId, t.Name, t.TimeZone, tz.Name AS TimeZoneName, db.DbName AS DbName FROM batched.dbo.Tenant t \
                            JOIN batched.dbo.Timezone tz ON t.TimeZone = tz.ID \
                            JOIN batched.dbo.TenantDatabase db on t.ID = db.TenantId \
                            WHERE t.IsEnabled = 1;', connection)

    selected_columns_df = df[["Name","tenantId"]]
    selected_columns_df.to_csv('AlgoWebData.csv', index=False)
    print(f"Found {len(selected_columns_df)} tenants")
    return json.loads(selected_columns_df.to_json(orient="records"))

def create_schedule(tenant_name, tenant_id):
    """Create EventBridge schedule for a tenant's AlgoWeb health check"""
    # Sanitize schedule name (remove special characters)
    schedule_name = f"algoweb-hc-{tenant_name}".replace(' ', '-').replace('_', '-')[:64]
    
    # Message payload for SQS
    message_payload = {
        "tenantName": tenant_name,
        "tenantId": tenant_id
    }
    
    try:
        response = scheduler_client.create_schedule(
            Name=schedule_name,
            GroupName=SCHEDULER_GROUP_NAME,
            ScheduleExpression='cron(0/15 * * * ? *)',  # Every 15 minutes (at :00, :15, :30, :45)
            FlexibleTimeWindow={
                'Mode': 'OFF'
            },
            Target={
                'Arn': SQS_QUEUE_ARN,
                'RoleArn': SCHEDULER_ROLE_ARN,
                'Input': json.dumps(message_payload),
                'SqsParameters': {
                    'MessageGroupId': 'algoweb-healthcheck-group'  # Single group ID for sequential processing
                }
            },
            State='ENABLED',
            Description=f'AlgoWeb health check schedule for tenant {tenant_name}'
        )
        print(f"✅ Created schedule: {schedule_name} for tenant {tenant_name}")
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConflictException':
            print(f"⚠️  Schedule {schedule_name} already exists, updating...")
            try:
                scheduler_client.update_schedule(
                    Name=schedule_name,
                    GroupName=SCHEDULER_GROUP_NAME,
                    ScheduleExpression='cron(0/15 * * * ? *)',  # Every 15 minutes (at :00, :15, :30, :45)
                    FlexibleTimeWindow={
                        'Mode': 'OFF'
                    },
                    Target={
                        'Arn': SQS_QUEUE_ARN,
                        'RoleArn': SCHEDULER_ROLE_ARN,
                        'Input': json.dumps(message_payload),
                        'SqsParameters': {
                            'MessageGroupId': 'algoweb-healthcheck-group'  # Single group ID for sequential processing
                        }
                    },
                    State='ENABLED',
                    Description=f'AlgoWeb health check schedule for tenant {tenant_name}'
                )
                print(f"✅ Updated schedule: {schedule_name}")
                return True
            except Exception as update_error:
                print(f"❌ Failed to update schedule {schedule_name}: {update_error}")
                return False
        else:
            print(f"❌ Failed to create schedule {schedule_name}: {e}")
            return False
    except Exception as e:
        print(f"❌ Unexpected error creating schedule {schedule_name}: {e}")
        return False

def main():
    print("=" * 80)
    print("AlgoWeb Health Check - EventBridge Schedule Configuration")
    print("=" * 80)
    
    # Fetch all tenants
    tenants = get_all_tenants()
    
    if not tenants:
        print("No tenants found. Exiting.")
        return
    
    print(f"\nConfiguring schedules for {len(tenants)} tenants...")
    print("-" * 80)
    
    success_count = 0
    failure_count = 0
    
    for tenant in tenants:
        tenant_name = tenant['Name']
        tenant_id = tenant['tenantId']
        
        if create_schedule(tenant_name, tenant_id):
            success_count += 1
        else:
            failure_count += 1
    
    print("-" * 80)
    print(f"\n✅ Successfully created/updated: {success_count} schedules")
    if failure_count > 0:
        print(f"❌ Failed: {failure_count} schedules")
    print("\nDone!")

if __name__ == '__main__':
    main()