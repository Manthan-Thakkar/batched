class Constants:

    # Misc
    S3_FILE_EXTENSION = ".backup"
    AWS_S3_CONN_ID = "s3_conn_str"

    RDSSTATUS_SUCCESS = "SUCCESS"
    RDSSTATUS_ERROR = "ERROR"
    RDSSTATUS_CREATED = "CREATED"
    RDSSTATUS_INPROGRESS = "IN_PROGRESS"

    # AWS Paramaters
    AWSPARAM_CONNECTIONSTRING = "py-batched-cn"
    AWSPARAM_MODELDB = "backup-db-model"
    AWSPARAM_S3_PATH = "db-backup-s3-path"
    AWSPARAM_S3_BUCKET = "db-backup-s3-bucket"
    AWSPARAM_ENCRYPTION = True
    AWS_BACKUP_FILE_OVERWRITE = 1
    AWSPARAM_DB_INSTANCE_SERVICE_URL = "db_instance_service_url"

    AWS_BACKUP_PATH_NAME_REPLACE = "_"
    AWS_BACKUP_FILE_EXTENSION = ".backup"


    #DagRun Configs
    DAGRUNPARAM_RESTOREDB = "restore_db"
    DAGRUNPARAM_TENANTID = "tenant_id"
    DAGRUNPARAM_CORRELATIONID = "correlation_id" #recommended to use
    DAGRUNPARAM_ERP_NAME = "erp_name"

    #Apis
    BASE_DBINSTANCE_SERVICE_URL = "/api/dbinstance/v1"

    API_GET_CONNECTIONSTRING = BASE_DBINSTANCE_SERVICE_URL + "/connection-info/"