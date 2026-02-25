from botocore.exceptions import ClientError
import logging
from batched_common.SSM import *
from batched_common.Database import *
from batched_common.Constants import *

def UpdateStatus(event):
    # Ensure stepsDetails exists in event
    if 'stepsDetails' not in event:
        event['stepsDetails'] = {}
    
    if event['stepsDetails'].get('stepStatus') == 'SUCCESS':
        return UpdateStatusToComplete(event)
    elif event['stepsDetails'].get('stepStatus') == 'ERROR':
        return UpdateStatusToError(event)
    else:
        # If status is neither SUCCESS nor ERROR, return event as-is
        logging.warning(f"Unexpected stepStatus: {event['stepsDetails'].get('stepStatus')}")
        event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
        return event

def UpdateStatusToComplete(event):
    # Ensure stepsDetails exists in event
    if 'stepsDetails' not in event:
        event['stepsDetails'] = {}
    
    try:
        rds = Database()   
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        # Even on error, return event to proceed to health check configuration
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
        event['stepsDetails']['errorMessage'] = 'Failed to create Database object'
        return event
    
    try:
        # Extracting database to be backedup FROM API parameters
        restore_db_name = event[Constants.DAGRUNPARAM_RESTOREDB]
        tenantQuery = "SELECT TenantID FROM batched.dbo.TenantDatabase where DbName = '" + restore_db_name + "'"
        tenant_results = rds.ExecuteReader(tenantQuery)
        if tenant_results is not None:
            tenantId = tenant_results[0][0]

            if tenantId:
                updateQuery = "UPDATE Tenant SET Status = 'Complete', IsEnabled = 1 where ID = '" + tenantId + "'"
                rds.ExecuteNonQuery(updateQuery)
                # Route to health check configuration step
                event['stepsDetails']['stepStatus'] = 'SUCCESS'
                event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
                return event
            else:
                logging.error("TenantID is None or empty")
                event['stepsDetails']['stepStatus'] = 'ERROR'
                event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
                event['stepsDetails']['errorMessage'] = 'TenantID is None or empty'
                return event
        else:
            logging.error("Tenant not found in database")
            event['stepsDetails']['stepStatus'] = 'ERROR'
            event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
            event['stepsDetails']['errorMessage'] = 'Tenant not found in database'
            return event
    
    except Exception as e:
        logging.error("Exception while updating table")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
        event['stepsDetails']['errorMessage'] = str(e)
        return event

def UpdateStatusToError(event):
    # Ensure stepsDetails exists in event
    if 'stepsDetails' not in event:
        event['stepsDetails'] = {}
    
    try:
        rds = Database()   
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
        event['stepsDetails']['errorMessage'] = 'Failed to create Database object for error status update'
        return event
    
    try:
        # Extracting database to be backedup FROM API parameters
        restore_db_name = event[Constants.DAGRUNPARAM_RESTOREDB]
        tenantQuery = "SELECT TenantID FROM batched.dbo.TenantDatabase where DbName = '" + restore_db_name + "'"
        tenant_results = rds.ExecuteReader(tenantQuery)
        if tenant_results is not None:
            tenantId = tenant_results[0][0]

            if tenantId:
                updateQuery = "UPDATE Tenant SET Status = 'Error', IsEnabled = 0 where ID = '" + tenantId + "'"
                rds.ExecuteNonQuery(updateQuery)
                event['stepsDetails']['stepStatus'] = 'ERROR'
                event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
                return event
            else:
                logging.error("TenantID is None or empty")
                event['stepsDetails']['stepStatus'] = 'ERROR'
                event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
                event['stepsDetails']['errorMessage'] = 'TenantID is None or empty'
                return event
        else:
            logging.error("Tenant not found in database")
            event['stepsDetails']['stepStatus'] = 'ERROR'
            event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
            event['stepsDetails']['errorMessage'] = 'Tenant not found in database'
            return event

    except Exception as e:
        logging.error("Exception while updating table")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'ConfigureHealthChecks'
        event['stepsDetails']['errorMessage'] = str(e)
        return event

def UpdateStatusToInprogress(event):
    # Ensure stepsDetails exists in event
    if 'stepsDetails' not in event:
        event['stepsDetails'] = {}
    
    try:
        rds = Database()   
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['errorMessage'] = 'Failed to create Database object for in-progress status update'
        return event
    
    try:
        # Extracting database to be backedup FROM API parameters
        restore_db_name = event[Constants.DAGRUNPARAM_RESTOREDB]
        tenantQuery = "SELECT TenantID FROM batched.dbo.TenantDatabase where DbName = '" + restore_db_name + "'"
        tenant_results = rds.ExecuteReader(tenantQuery)
        if tenant_results is not None:
            tenantId = tenant_results[0][0]

            if tenantId:
                updateQuery = "UPDATE Tenant SET Status = 'InProgress' where ID = '" + tenantId + "'"
                rds.ExecuteNonQuery(updateQuery)
                event['stepsDetails']['stepStatus'] = 'SUCCESS'
                return event
            else:
                logging.error("TenantID is None or empty")
                event['stepsDetails']['stepStatus'] = 'ERROR'
                event['stepsDetails']['errorMessage'] = 'TenantID is None or empty'
                return event
        else:
            logging.error("Tenant not found in database")
            event['stepsDetails']['stepStatus'] = 'ERROR'
            event['stepsDetails']['errorMessage'] = 'Tenant not found in database'
            return event
    
    except Exception as e:
        logging.error("Exception while updating table")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['errorMessage'] = str(e)
        return event