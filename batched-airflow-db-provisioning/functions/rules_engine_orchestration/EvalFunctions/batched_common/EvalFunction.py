from batched_common.HttpClient import *
from batched_common.Constants import *

def Eval_Function(eval_event, constant_value, next_step):
    try:
        httpClient = RulesEngineHttpClient()
    except Exception as e:
        raise e

    try:
        cid = eval_event[Constants.DAGRUNPARAM_CID]
    except Exception as e:
        print("Cid does not exists")
        raise e
    
    try:
        # Extracting 
        tenant_id = eval_event[Constants.DAGRUNPARAM_TENANTID]
        since = eval_event[Constants.DAGRUNPARAM_SINCE]
        jobid = eval_event[Constants.DAGRUNPARAM_JOBID]
        header = {"TenantId":tenant_id, "correlationId": cid, "since": since, "jobId":  jobid}
        print(header)
        sessionId = httpClient.get(constant_value, header)
        print(sessionId)
        if sessionId is None:
            eval_event['stepsDetails'] = {'sessionId' : sessionId, 'stepStatus' : None, 'NextStep' : next_step}
            return eval_event
        else:
            eval_event['stepsDetails'] = {'sessionId' : sessionId, 'stepStatus' : None, 'NextStep' : next_step}
            return eval_event
    except Exception as e:
        raise e