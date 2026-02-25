from batched_common.TenantDatabase import TenantDatabase
import logging
import time
from batched_common.SSM import *
from batched_common.Database import *
from batched_common.Constants import *
from statusupdate import UpdateStatusToInprogress, UpdateStatusToError

def create_model_tenant_DB_Backup(event):
    try:
        rds = Database()
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return e
    try:
        UpdateStatusToInprogress(event)
        # Extracting database to be backedup from API parameters
        aws_ssm_param_db = get_parameter(Constants.AWSPARAM_MODELDB, Constants.AWSPARAM_ENCRYPTION)
        aws_ssm_param_s3 = get_parameter(Constants.AWSPARAM_S3_PATH, Constants.AWSPARAM_ENCRYPTION)
        erp_name = event[Constants.DAGRUNPARAM_ERP_NAME].lower()
        db_name = aws_ssm_param_db['Parameter']['Value']
        backup_db_name = db_name + "-" + str(erp_name)
        db_name_s3 = db_name.replace("-", Constants.AWS_BACKUP_PATH_NAME_REPLACE)
        s3_location = aws_ssm_param_s3['Parameter']['Value'] + db_name_s3 + "_" + str(int(time.time())) + Constants.AWS_BACKUP_FILE_EXTENSION
        
    except Exception as e:
        logging.error("Exception while fetching parameter store values")
        logging.error(e)
        print(e)
        return e
    try:
        params = [["source_db_name", backup_db_name], ["S3_arn_to_backup_to", s3_location], ["overwrite_s3_backup_file", Constants.AWS_BACKUP_FILE_OVERWRITE]]
        results = rds.executeSP('[msdb].[dbo].[rds_backup_database]',params)
        
        if results is not None:
            sql_task_id = results[0][0]
            event['stepsDetails'] = {'sql_task_id' : sql_task_id, 'stepStatus' : None, 'NextStep' : 'ModelTenantDB-BackupStatusCheck', 's3_location': s3_location}
            return event
        else:
            event['stepsDetails'] = {'sql_task_id' : 'Error', 'stepStatus' : None, 'NextStep' : 'Fail'}
            UpdateStatusToError(event)
            return event

    except Exception as e:
        logging.error("Exception while executing stored procedure")
        logging.error(e)
        print(e)
        return e

def restore_model_tenant_db_backup_to_tenant(event):
    try:
        # Extracting database to be backedup from API parameters
        restore_db_name = event[Constants.DAGRUNPARAM_RESTOREDB]  #tenant-name
        tenant_id = event[Constants.DAGRUNPARAM_TENANTID]  #tenant-id
        correlation_id = event[Constants.DAGRUNPARAM_CORRELATIONID] #cid

        tenant_rds = TenantDatabase(tenant_id, correlation_id)   
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return e
    
    try:
        s3_location = event['stepsDetails']['s3_location']
        params = [["restore_db_name", restore_db_name], ["s3_arn_to_restore_from", s3_location]]
        results = tenant_rds.executeSP('[msdb].[dbo].[rds_restore_database]', params)

        if results is not None:
            sql_task_id = results[0][0]
            event['stepsDetails']['sql_task_id'] = sql_task_id
            event['stepsDetails']['stepStatus'] = None
            event['stepsDetails']['NextStep'] = 'RestoreTenantDB-BackupStatusCheck'
            return event
        else:
            event['stepsDetails']['sql_task_id'] = 'Error'
            event['stepsDetails']['stepStatus'] = None
            event['stepsDetails']['NextStep'] = 'Fail'
            UpdateStatusToError(event)
            return event
        
    except Exception as e:
        logging.error("Exception while executing stored procedure")
        logging.error(e)
        print(e)
        return e