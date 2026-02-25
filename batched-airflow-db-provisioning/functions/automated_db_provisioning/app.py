from create_db_task import *
from check_db_task_status import db_task_status_check
from seed_tenant_data import SeedTenantData
from statusupdate import UpdateStatus
from configure_healthchecks import ConfigureHealthChecks

def lambda_handler(event,context):
    if 'stepsDetails' not in event:
        return create_model_tenant_DB_Backup(event)
    elif event['stepsDetails']['NextStep'] == "ModelTenantDB-BackupStatusCheck":
        return db_task_status_check(event,"RestoreTenantDB")
    elif event['stepsDetails']['NextStep'] == "RestoreTenantDB":
        return restore_model_tenant_db_backup_to_tenant(event)
    elif event['stepsDetails']['NextStep'] == "RestoreTenantDB-BackupStatusCheck":
        return db_task_status_check(event,"SeedTenantData")
    elif event['stepsDetails']['NextStep'] == "SeedTenantData":
        return SeedTenantData(event)
    elif event['stepsDetails']['NextStep'] == "UpdateStatus-For-Tenant":
        return UpdateStatus(event)
    elif event['stepsDetails']['NextStep'] == "ConfigureHealthChecks":
        return ConfigureHealthChecks(event)