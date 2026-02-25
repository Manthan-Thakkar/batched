import sys
from botocore.exceptions import ClientError
import logging
from batched_common.SSM import *
from batched_common.Database import *
from batched_common.Constants import *
from statusupdate import UpdateStatusToError

def db_task_status_check(event,NextStep):
    try:
        sql_task_id = event['stepsDetails']['sql_task_id']
    except Exception as e:
        logging.error("Exception while reading from XComs")
        logging.error(e)

    
    try:
        rds = Database()
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return False
    
    
    try:
        params = [["task_id", sql_task_id]]
        results = rds.executeSP('msdb.dbo.rds_task_status',params)
        
        if results is not None:
            status = results[0][5]
        else:
            event['stepsDetails']['stepStatus'] = 'ERROR'
            UpdateStatusToError(event)
            return event

        if(status == Constants.RDSSTATUS_SUCCESS or status == Constants.RDSSTATUS_ERROR):
            event['stepsDetails']['stepStatus'] = status
            event['stepsDetails']['NextStep'] = NextStep
            return event
        if(status == Constants.RDSSTATUS_INPROGRESS or status == Constants.RDSSTATUS_CREATED):
            event['stepsDetails']['stepStatus'] = status
            return event  
    except Exception as e:
        logging.error("Exception while fetching status from RDS")
        logging.error(e)
        print(e)
        return e