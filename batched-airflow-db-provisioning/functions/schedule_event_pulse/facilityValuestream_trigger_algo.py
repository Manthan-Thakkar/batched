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

def group_by_facilities(Input):
    Output = {}
    for tenantId, dbName, facilityId, vsId, tz, utcdst, utc, wltz, sid, runtime in Input:
        if facilityId in Output:
            Output[facilityId].append((tenantId, dbName, facilityId, vsId, tz, utcdst, utc, wltz, sid, runtime))
        else:
            Output[facilityId] = [(tenantId, dbName, facilityId, vsId, tz, utcdst, utc, wltz, sid, runtime)]
     
    facilityAndValueStreams = []
    for attribute, value in Output.items():
        vsResult = []
        for item in value:
            if item[3] is not None:
                vsResult.append(item[3])
        result = { 
            "id": attribute,
            "valueStreams": vsResult if len(vsResult) > 0 else None
        }
        facilityAndValueStreams.append(result)
    return facilityAndValueStreams

def schedule_facility_event_for_later(tenant_id, db_name, schedule_id, scheduled_time, delay_seconds, facilities):
    try:
        target_lambda_arn = os.environ.get('TARGET_LAMBDA_ARN', 'default-lambda-arn')
        scheduler_role_arn = os.environ.get('SCHEDULER_EXECUTION_ROLE_ARN', 'default-lambda-arn')
        scheduler_group = os.environ.get('SCHEDULER_GROUP_NAME', 'default')

        client = boto3.client('scheduler')
        # Truncate db_name to 30 chars to stay within 64 char limit
        db_name_truncated = db_name[:30] if len(db_name) > 30 else db_name
        schedule_name = f"{db_name_truncated}-facility-schedule-{scheduled_time.strftime('%Y%m%d%H%M')}"
        
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
                    'facilities': facilities,
                    'scheduled_execution': True
                })
            }
        )
        
        print(f"Scheduled facility event for {db_name} at {scheduled_time} - Schedule ARN: {response.get('ScheduleArn')}")
        return True
        
    except Exception as e:
        print(f"Error scheduling facility event for {db_name}: {e}")
        return False

def DailyFacilityScheduler(event, context):
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
        
        print(f"Running daily facility scheduler for date: {current_date}")
        
        tenant_query = f"""select f.TenantId, td.DbName, fvs.FacilityId, fvs.valueStreamId, f.TimeZone, fvs.UTCDSTTimeSpan, fvs.UTCTimeSpan, wltz.LinuxTZ, fvs.ScheduleTimeSpanId 
from batched.dbo.FacilityValueStreamScheduleEvent fvs 
inner join batched.dbo.Facility f on f.ID = fvs.FacilityId
inner join batched.dbo.Tenant t on f.TenantId = t.ID
inner join batched.dbo.TenantDatabase td on t.Id = td.TenantId 
inner join batched.dbo.timezone tz on f.TimeZone = tz.ID
inner join batched.dbo.WindowsLinuxTimezone wltz on tz.id = wltz.WindowsId
where fvs.isEnabled = 1"""

        tenant_results = rds.ExecuteReader(tenant_query)
        if tenant_results is not None:
            # Group by tenant and schedule time
            schedule_groups = {}
            
            for row in tenant_results:
                tenant_id = row[0]
                dbName = row[1]
                tz = pytz.timezone(row[7])
                
                tenant_dt = row[6]  # UTC time
                if is_dst(datetime.now(tz)):
                    print(f"Tenant {dbName} is in DST")
                    tenant_dt = row[5]  # UTC DST time
                
                # Create scheduled time for today only (within current UTC day)
                scheduled_time = datetime.combine(
                    current_date,
                    tenant_dt,
                    tzinfo=pytz.timezone("UTC")
                )
                
                # Only schedule if it's within the current UTC day and hasn't passed yet
                current_utc_end_of_day = datetime.combine(
                    current_date,
                    time(23, 59, 59),
                    tzinfo=pytz.timezone("UTC")
                )
                
                # Skip if scheduled time has already passed or is outside current UTC day
                if scheduled_time <= current_utc:
                    print(f"Skipping {dbName} facility - scheduled time {scheduled_time} has already passed (current: {current_utc})")
                    continue
                
                if scheduled_time > current_utc_end_of_day:
                    print(f"Skipping {dbName} facility - scheduled time {scheduled_time} is outside current UTC day")
                    continue
                
                print(f"Scheduling {dbName} facility for today at {scheduled_time}")
                
                # Group by tenant and schedule time for batching
                key = (tenant_id, dbName, scheduled_time, row[8])  # Include schedule ID
                if key not in schedule_groups:
                    schedule_groups[key] = []
                
                run_time = scheduled_time.strftime('%Y%m%d%H%M')
                schedule_groups[key].append((tenant_id, dbName, row[2], row[3], row[4], row[5], row[6], row[7], row[8], run_time))
            
            scheduled_count = 0
            for (tenant_id, dbName, scheduled_time, schedule_id), facility_data in schedule_groups.items():
                facilities = group_by_facilities(facility_data)
                delay_seconds = (scheduled_time - current_utc).total_seconds()
                
                if schedule_facility_event_for_later(tenant_id, dbName, schedule_id, scheduled_time, delay_seconds, facilities):
                    scheduled_count += 1
                
            print(f"Successfully scheduled {scheduled_count} facility events for the day")
            return True
        else:
            print("No facility schedule events found")
            return True
            
    except Exception as e:
        logging.error("Exception in daily facility scheduler")
        logging.error(e)
        print(e)
        return False

def FacilityValueStreamTriggerAlgo(event, context):
    print("Facility and valueStream level algo triggered.")
    
    # Check if this is a scheduled execution from the daily scheduler
    if event.get('scheduled_execution', False):
        tenant_id = event.get('tenant_id')
        db_name = event.get('db_name')
        schedule_id = event.get('schedule_id')
        facilities = event.get('facilities')
        
        if all([tenant_id, db_name, schedule_id, facilities]):
            current_utc = datetime.now(pytz.timezone("UTC"))
            run_time = current_utc.strftime('%Y%m%d%H%M')
            Trigger_FacilityValueStream_Schedule(tenant_id, db_name, facilities, schedule_id, run_time)
            return True
        else:
            print("Missing required parameters for scheduled facility execution")
            return False
    
    # Check if this is a daily scheduler request
    if event.get('daily_scheduler', False):
        return DailyFacilityScheduler(event, context)
    
    try:
        rds = Database()
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return False

    # Health check logic
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

def Trigger_FacilityValueStream_Schedule(tenant_id, dbName, facilities, scheduleId, run_time):
    print(tenant_id)
    print("fullSchedule run triggered on " + dbName)
    try:
        action = "fullSchedule_V2"
        logging.info("Schedule Version : "+ action)
        httpClient = AlgoTriggerHttpClient() 
        payload = { 
            "action": action,
            "facilities": facilities
        }
        print(payload)
        headers = { "content-type": "application/json", "tenantName": dbName, "tenantId": tenant_id, "scheduleId": scheduleId, "runtime": run_time }
        httpClient.post(Constants.API_TRIGGER_ALGO, json.dumps(payload), headers)
    except Exception as e:
        print("TriggerFullScheduleRunFacilityValueStreams Error")
        print(e)