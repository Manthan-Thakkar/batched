from datetime import datetime, timedelta


class Constants:

    APISTATUS_SUCCESS = "Completed"
    APISTATUS_ERROR = "Failed"
    APISTATUS_INPROGRESS = "InProgress"

    # AWS Paramaters
    AWSPARAM_ENCRYPTION = True
    AWSPARAM_RULES_ENGINE_URL = "rules_engine_url_alb"


    #DagRun Configs
    DAGRUNPARAM_TENANTID = "TenantId"
    DAGRUNPARAM_ISMOCKED = "is_mocked"
    DAGRUNPARAM_CID = "CorrelationId" # to be obsolete
    DAGRUNPARAM_CORRELATIONID = "correlation_id" #recommended to use
    DAGRUNPARAM_SINCE = "Since" #recommended to use
    DAGRUNPARAM_JOBID = "JobId" #recommended to use
    DAGRUNPARAM_ERP_NAME = "erp_name"

    #Query Replacement Values
    QUERY_REPLACE_SESSIONID = "{sessionId}"

    #Apis
    BASE_RULES_ENGINE_URL = "/api/rule/v1"

    API_STATUS_TICKET_ATTRIBUTES = BASE_RULES_ENGINE_URL + "/ticketattribute/status/{sessionId}"

    API_STATUS_FEASIBLE_ROUTES = BASE_RULES_ENGINE_URL + "/constraints/status/{sessionId}"

    API_STATUS_CHANGEOVERS = BASE_RULES_ENGINE_URL + "/changeover/status/{sessionId}"

    API_STATUS__TICKET_TASK = BASE_RULES_ENGINE_URL + "/tickettask/status/{sessionId}"
    
    API_STATUS_STOCK_PLANNING = BASE_RULES_ENGINE_URL + "/stockplanning/status/{sessionId}"
    
    API_STATUS_RESERVATIONS = BASE_RULES_ENGINE_URL + "/reservations/status/{sessionId}"
    
    API_STATUS_REPORTS_DATA = BASE_RULES_ENGINE_URL + "/reportsdata/status/{sessionId}"

    API_STATUS_TICKET_STOCK_ATTRIBUTE = BASE_RULES_ENGINE_URL + "/ticketattribute/ticketstockattribute/status/{sessionId}"

    API_STATUS_GENERATE_CYLINDERS = BASE_RULES_ENGINE_URL + "/tools/cylinders/status/{sessionId}"