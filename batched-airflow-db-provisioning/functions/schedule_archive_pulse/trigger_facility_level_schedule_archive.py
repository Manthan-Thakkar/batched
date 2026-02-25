import json
from botocore.exceptions import ClientError
from batched_common.HttpClient import *
from batched_common.Database import *
from datetime import datetime, timedelta, timezone
import pytz # timezone management
import uuid

def is_dst(dt):
    return dt.dst() != timedelta(0)

def get_facility_query_string(facilities : list) :
    return "?facilities=" + "&facilities=".join(str(e) for e in facilities)
    

def TriggerFacilityScheduleArchive(event, context):
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

        currentTimeUTC = datetime.now(pytz.timezone("UTC"))
        # If 0th hour then multiply directly 24*60 to satisfy the schedule run condition below
        if currentTimeUTC.hour == 0 and currentTimeUTC.minute == 0:
            dt_now = 24*60
        else:
            dt_now = currentTimeUTC.hour*60 + currentTimeUTC.minute
                 
        dt_4minsago = currentTimeUTC - timedelta(minutes=4)
        dt_4minsago_ts = dt_4minsago.hour*60 + dt_4minsago.minute

        tenant_query = f"""select SI.Id, F.TenantId, SI.FacilityId, WLTZ.LinuxTZ, SI.ArchivalTimeUTC, SI.ArchivalTimeUTCDST, F.Name 
        from batched.dbo.facilityScheduleArchival SI 
        INNER JOIN batched.dbo.Facility F ON F.ID = SI.FacilityId
        INNER JOIN batched.dbo.timezone TZ ON F.TimeZone = TZ.ID
        INNER JOIN batched.dbo.WindowsLinuxTimezone WLTZ ON TZ.ID = WLTZ.WindowsId
        where SI.IsEnabled = 1 and (SI.ArchivalTimeUTC between '{currentTime_4MinsAgo}' and '{currentTime}' or SI.ArchivalTimeUTCDST between '{currentTime_4MinsAgo}' and '{currentTime}') 
        or SI.ArchivalTimeUTC = '{currentTime}'
        or sI.ArchivalTimeUTCDST = '{currentTime}'"""

        archival_results = rds.ExecuteReader(tenant_query)  
        archival_results_4mins_ago = []
        if archival_results is not None:
            for row in archival_results:
                try:
                    archive_record = tuple(row)
                    schedule_archive_id = archive_record[0]
                    facility_name = archive_record[6]
                    tz = pytz.timezone(archive_record[3]) 

                    archival_time = archive_record[4] # UTC
                    if is_dst(datetime.now(tz)):
                        print("IS DST")
                        # UTC time as per DB
                        archival_time = archive_record[5] # UTC for DST

                    # If 0th hour then multiply directly 24*60
                    if archival_time.hour == 0 and archival_time.minute == 0:
                        dt_ts = 24*60
                    else:
                        dt_ts = archival_time.hour*60 + archival_time.minute
                    
                    if dt_4minsago_ts <= dt_ts and dt_ts <= dt_now: # check if the schedule was in the last 4 mins
                        archival_results_4mins_ago.append(archive_record)
                    else:
                        print("Skipping schedule archival for " + str(facility_name) + " since it not in expected execution time window")
                    
                except Exception as e:
                    logging.error("Exception when archiving/purging schedule - " + schedule_archive_id)
                    logging.error(e)
                    continue

            grouped_records_byTenant = {}
            for schedule_archive_id, tenantId, facilityId, linuxTZ, utc, utcdst, name  in archival_results_4mins_ago:
                if tenantId in grouped_records_byTenant:
                    grouped_records_byTenant[tenantId].append(facilityId)
                else:
                    grouped_records_byTenant[tenantId] = [facilityId]

            for tenantId, value in grouped_records_byTenant.items():
                correlation_id = str(uuid.uuid1())
                facility_query_string = get_facility_query_string(value)
                TriggerScheduleArchival(tenantId, facility_query_string , correlation_id)
                TriggerPurgeArchive(tenantId, facility_query_string, correlation_id)
                TriggerScheduleAnalysis(tenantId, facility_query_string, correlation_id)
                
        else:
            logging.info("No records found")
            print("No records found")
    except Exception as e:
        logging.error("Exception when archiving schedule")
        logging.error(e)
        print(e)
        return False

def TriggerScheduleArchival(tenant_id, facilityQueryString, correlation_id):

    logging.info("Schedule Archive triggered for tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       archive_schedule_url = Constants.SCHEDULE_ARCHIVE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id) + facilityQueryString
       httpClient.post(archive_schedule_url, None , headers)
    except Exception as e:
      logging.error("An error occurred while invoking schedule archive for "+ tenant_id)
      logging.error(e)

def TriggerPurgeArchive(tenant_id, facilityQueryString, correlation_id):

    logging.info("Purge Archive triggered for tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       purge_archived_schedule_url = Constants.SCHEDULE_PURGE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id) + facilityQueryString
       httpClient.delete(purge_archived_schedule_url , headers)
    except Exception as e:
      logging.error("An error occurred while invoking purge archive for "+ tenant_id)
      logging.error(e)

def TriggerScheduleAnalysis(tenant_id, facilityQueryString, correlation_id):

    logging.info("Schedule Analysis triggered for tenant Id " + tenant_id + "and correlation_id " + correlation_id)
    try:
       httpClient = ArchivalServiceHttpClient() 

       headers = { "content-type": "application/json", "tenantId": tenant_id, "correlationId": correlation_id}
       analyze_schedule_url = Constants.SCHEDULE_ANALYZE_ENDPOINT.replace(Constants.QUERY_REPLACE_TENANTID, tenant_id) + facilityQueryString
       httpClient.post(analyze_schedule_url, None , headers)
    except Exception as e:
      logging.error("An error occurred while invoking analyze archive for "+ tenant_id)
      logging.error(e)

