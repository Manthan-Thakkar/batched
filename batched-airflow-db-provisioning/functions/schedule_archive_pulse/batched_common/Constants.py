from datetime import datetime, timedelta


class Constants:

    # AWS Paramaters
    AWSPARAM_CONNECTIONSTRING = "py-batched-cn"
    AWSPARAM_ENCRYPTION = True
    AWSPARAM_ARCHIVAL_SERVICE_URL = "archive_service_url"

    #Query Replacement Values
    QUERY_REPLACE_TENANTID = "{tenantId}"

    ARCHIVE_SERVICE_BASE_URL = "/api/archival/v1"
    SCHEDULE_ARCHIVE_ENDPOINT = ARCHIVE_SERVICE_BASE_URL + "/schedule/{tenantId}/archive"
    SCHEDULE_PURGE_ENDPOINT = ARCHIVE_SERVICE_BASE_URL + "/schedule/{tenantId}/purge"
    SCHEDULE_ANALYZE_ENDPOINT = ARCHIVE_SERVICE_BASE_URL + "/schedule/{tenantId}/analyze"