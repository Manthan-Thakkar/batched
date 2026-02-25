import json
from botocore.exceptions import ClientError
from batched_common.HttpClient import *
from batched_common.Database import *
from datetime import datetime, timedelta, timezone
import pytz # timezone management
import uuid

def is_dst(dt):
    return dt.dst() != timedelta(0)


def TriggerScheduleArchive(event, context):
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
    try:

        # UTC Times
        dateTimeObj = datetime.utcnow()
        FourMinsAgo = dateTimeObj - timedelta(minutes=4)
        currentTime =str(dateTimeObj.hour) +":"+str(dateTimeObj.minute)+":00"
        currentTime_4MinsAgo =str(FourMinsAgo.hour) +":"+str(FourMinsAgo.minute)+":00"

        tenant_query = f"""select SI.Id, SI.TenantId, SI.TotalArchiveDays from batched.dbo.ScheduleArchiveInfo SI 
        where  SI.IsEnabled = 1 and (ArchiveTimeUTC between '{currentTime_4MinsAgo}' and '{currentTime}' or ArchiveTimeUTC = '{currentTime}')"""

        tenant_results = rds.ExecuteReader(tenant_query)  
        if tenant_results is not None:
            for tenant in tenant_results:
                try:
                   schedule_archive_id = tenant[0]
                   tenant_id = tenant[1]
                   max_archive_days = tenant[2]
                   correlation_id = str(uuid.uuid1())
                
                   TriggerPurgeArchive(schedule_archive_id, tenant_id, max_archive_days, correlation_id)
                   TriggerScheduleArchival(schedule_archive_id, tenant_id, max_archive_days, correlation_id)
                   TriggerScheduleAnalysis(schedule_archive_id, tenant_id, correlation_id)
                except Exception as e:
                    logging.error("Exception when archiving/purging schedule - " + schedule_archive_id)
                    logging.error(e)
                    continue
        else:
            logging.info("No records found")
            print("No records found")
    except Exception as e:
        logging.error("Exception when archiving schedule")
        logging.error(e)
        print(e)
        return False

def TriggerScheduleArchival(schedule_archive_id, tenant_id, max_archive_days, correlation_id):

    logging.info("Schedule Archive triggered for archive Id " + schedule_archive_id + ",tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       archive_schedule_url = Constants.SCHEDULE_ARCHIVE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id)
       httpClient.post(archive_schedule_url, None , headers)
    except Exception as e:
      logging.error("An error occurred while invoking schedule archive for "+ tenant_id)
      logging.error(e)

def TriggerPurgeArchive(schedule_archive_id, tenant_id, max_archive_days, correlation_id):

    logging.info("Purge Archive triggered for archive Id " + schedule_archive_id + ",tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       purge_archived_schedule_url = Constants.SCHEDULE_PURGE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id)

       httpClient.delete(purge_archived_schedule_url , headers)
    except Exception as e:
      logging.error("An error occurred while invoking purge archive for "+ tenant_id)
      logging.error(e)

def TriggerScheduleAnalysis(schedule_archive_id, tenant_id, correlation_id):

    logging.info("Schedule Analysis triggered for archive Id " + schedule_archive_id + ",tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       analyze_schedule_url = Constants.SCHEDULE_ANALYZE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id)

       httpClient.post(analyze_schedule_url, None , headers)
    except Exception as e:
      logging.error("An error occurred while invoking analyze archive for "+ tenant_id)
      logging.error(e)

