import json
import os
from botocore.exceptions import ClientError
from batched_common.HttpClient import *
from batched_common.Database import *
from datetime import datetime, timedelta, timezone, time
import pytz
import boto3
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def is_dst(dt):
    return dt.dst() != timedelta(0)

def schedule_event(tenant_id, db_name, schedule_id, scheduled_time, delay_seconds):
    try:
        
        # Get function details to construct ARN
        target_lambda_arn = os.environ.get('TARGET_LAMBDA_ARN', 'default-lambda-arn')
        scheduler_role_arn = os.environ.get('SCHEDULER_EXECUTION_ROLE_ARN', 'default-lambda-arn')
        scheduler_group = os.environ.get('SCHEDULER_GROUP_NAME', 'default')
        
        client = boto3.client('scheduler')
        # Truncate db_name to 30 chars to stay within 64 char limit
        db_name_truncated = db_name[:30] if len(db_name) > 30 else db_name
        schedule_name = f"{db_name_truncated}-algo-schedule-{scheduled_time.strftime('%Y%m%d%H%M')}"
        
        # Check if schedule already exists
        try:
            existing_schedule = client.get_schedule(
                GroupName=scheduler_group,
                Name=schedule_name
            )
            print(f"Schedule {schedule_name} already exists, skipping creation")
            return True
        except client.exceptions.ResourceNotFoundException:
            # Schedule doesn't exist, proceed with creation
            pass
        
        schedule_expression = f"at({scheduled_time.strftime('%Y-%m-%dT%H:%M:%S')})"
        
        response = client.create_schedule(
            ActionAfterCompletion='DELETE',
            FlexibleTimeWindow={
                'Mode': 'OFF'
            },
            GroupName=scheduler_group,
            Name=schedule_name,
            ScheduleExpression=schedule_expression,
            Target={
                'Arn': target_lambda_arn,
                'RoleArn': scheduler_role_arn,
                'Input': json.dumps({
                    'tenant_id': tenant_id,
                    'db_name': db_name,
                    'schedule_id': schedule_id,
                    'scheduled_execution': True
                })
            }
        )
        
        print(f"Scheduled event for {db_name} at {scheduled_time} - Schedule ARN: {response.get('ScheduleArn')}")
        return True
        
    except Exception as e:
        print(f"Error scheduling event for {db_name}: {e}")
        return False

def DailyScheduler(event, context):
    try:
        rds = Database()
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return False

    if event.get('isHealthCheckWithDB', False):
        conn = rds.getConnection()
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass
            return True
        else:
            return False

    try:
        current_utc = datetime.now(pytz.timezone("UTC"))
        current_date = current_utc.date()
        
        print(f"Running daily scheduler for date: {current_date}")
        
        tenant_query = f"""select se.TenantId, td.DbName, t.TimeZone, se.UTCDSTTimeSpan, se.UTCTimeSpan, wlt.LinuxTZ, se.TimeSpan, se.Id 
from batched.dbo.ScheduleEvent se 
inner join batched.dbo.TenantDatabase td on se.TenantId = td.TenantId 
inner join batched.dbo.Tenant t on td.TenantId = t.Id
inner join batched.dbo.timezone tz on t.TimeZone = tz.id
inner join batched.dbo.WindowsLinuxTimezone wlt on tz.id = wlt.WindowsID
where se.IsDisabled = 0"""

        tenant_results = rds.ExecuteReader(tenant_query)
        if tenant_results is not None:
            scheduled_count = 0
            for tenant in tenant_results:
                tenant_id = tenant[0]
                dbName = tenant[1]
                tz = pytz.timezone(tenant[5])
                
                tenant_dt = tenant[4]
                if is_dst(datetime.now(tz)):
                    print(f"Tenant {dbName} is in DST")
                    tenant_dt = tenant[3]
                
                # tenant_dt is already a time object from the database, not datetime
                scheduled_time = datetime.combine(
                    current_date,
                    tenant_dt,
                    tzinfo=pytz.timezone("UTC")
                )
                
                scheduleId = tenant[7]
                
                # Only schedule if it's within the current UTC day and hasn't passed yet
                current_utc_end_of_day = datetime.combine(
                    current_date,
                    time(23, 59, 59),
                    tzinfo=pytz.timezone("UTC")
                )
                
                # Skip if scheduled time has already passed or is outside current UTC day
                if scheduled_time <= current_utc:
                    print(f"Skipping {dbName} - scheduled time {scheduled_time} has already passed (current: {current_utc})")
                    continue
                
                if scheduled_time > current_utc_end_of_day:
                    print(f"Skipping {dbName} - scheduled time {scheduled_time} is outside current UTC day")
                    continue
                
                print(f"Scheduling {dbName} for today at {scheduled_time}")
                
                delay_seconds = (scheduled_time - current_utc).total_seconds()
                
                if schedule_event(tenant_id, dbName, scheduleId, scheduled_time, delay_seconds):
                    scheduled_count += 1
                
            print(f"Successfully scheduled {scheduled_count} events for the day")
            return True
        else:
            print("No schedule events found")
            return True
            
    except Exception as e:
        logging.error("Exception in daily scheduler")
        logging.error(e)
        print(e)
        return False

def TriggerAlgo(event, context):
    if event.get('scheduled_execution', False):
        tenant_id = event.get('tenant_id')
        db_name = event.get('db_name')
        schedule_id = event.get('schedule_id')
        
        if all([tenant_id, db_name, schedule_id]):
            current_utc = datetime.now(pytz.timezone("UTC"))
            run_time = current_utc.strftime('%Y%m%d%H%M')
            TriggerFullScheduleRun(tenant_id, db_name, schedule_id, run_time)
            return True
        else:
            print("Missing required parameters for scheduled execution")
            return False
    
    if event.get('daily_scheduler', False):
        return DailyScheduler(event, context)
    
    try:
        rds = Database()
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return False

    if event.get('isHealthCheckWithDB', False):
        conn = rds.getConnection()
        if conn is not None:
            try:
                conn.close()
            except Exception:
                pass
            return True
        else:
            return False
    
    print("No valid event type provided. Use 'daily_scheduler' or 'scheduled_execution' flags.")
    return False

def TriggerFullScheduleRun(tenant_id, dbName, scheduleId, run_time):
    print(tenant_id)
    print("fullSchedule run triggered on " + dbName)
    try:
        action = "fullSchedule_V2"
        logging.info("Schedule Version : "+ action)
        httpClient = AlgoTriggerHttpClient() 
        payload = { "action": action }
        headers = { "content-type": "application/json", "tenantName": dbName, "tenantId": tenant_id, "scheduleId": scheduleId, "runtime": run_time }
        httpClient.post(Constants.API_TRIGGER_ALGO, json.dumps(payload), headers)
    except Exception as e:
        print("TriggerFullScheduleRun Error")
        print(e)