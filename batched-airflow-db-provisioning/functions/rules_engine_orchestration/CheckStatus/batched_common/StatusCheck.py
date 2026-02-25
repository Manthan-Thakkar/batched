from batched_common.HttpClient import *
from batched_common.Constants import *
def StatusCheck(status_check_event, constant_value, next_step):
    try:
        httpClient = RulesEngineHttpClient()   
    except Exception as e:
        raise e

    try:
        cid = status_check_event[Constants.DAGRUNPARAM_CID]
    except Exception as e:
        raise e

    try:
        # Extracting 
        tenant_id = status_check_event[Constants.DAGRUNPARAM_TENANTID]
        since = status_check_event[Constants.DAGRUNPARAM_SINCE]
        jobid = status_check_event[Constants.DAGRUNPARAM_JOBID]
        header = {"TenantId":tenant_id, "correlationId": cid, "since": since, "jobId":  jobid}
        url = constant_value.replace(Constants.QUERY_REPLACE_SESSIONID, status_check_event['stepsDetails']['sessionId'])
        response = httpClient.get(url, header)
        # logging.info(response)
        if(response['status'] == Constants.APISTATUS_SUCCESS):
            status_check_event['stepsDetails']['stepStatus'] = "SUCCESS"
            status_check_event['stepsDetails']['NextStep'] = next_step

        elif(response['status'] == Constants.APISTATUS_ERROR):
            status_check_event['stepsDetails']['stepStatus'] = "ERROR"

        elif(response['status'] == Constants.APISTATUS_INPROGRESS):
            status_check_event['stepsDetails']['stepStatus'] = "IN_PROGRESS"

        return status_check_event
    except Exception as e:
        raise e