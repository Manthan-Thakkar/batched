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

    #Apis
    BASE_RULES_ENGINE_URL = "/api/rule/v1"

    API_EVALUATE_TICKET_ATTRIBUTES = BASE_RULES_ENGINE_URL + "/ticketattribute/eval"

    API_EVALUATE_FEASIBLE_ROUTES = BASE_RULES_ENGINE_URL + "/constraints/eval"

    API_EVALUATE_CHANGEOVERS = BASE_RULES_ENGINE_URL + "/changeover/eval"

    API_CLEANUP_TICKET_TASK = BASE_RULES_ENGINE_URL + "/tickettask/cleanup"
    API_EVALUATE_TICKET_TASK = BASE_RULES_ENGINE_URL + "/tickettask/eval"
    
    API_EVALUATE_STOCK_PLANNING = BASE_RULES_ENGINE_URL + "/stockplanning/eval"
    
    API_EVALUATE_RESERVATIONS = BASE_RULES_ENGINE_URL + "/reservations/eval"
    
    API_EVALUATE_REPORTS_DATA = BASE_RULES_ENGINE_URL + "/reportsdata/eval"

    API_EVALUATE_TICKET_STOCK_ATTRIBUTE = BASE_RULES_ENGINE_URL + "/ticketattribute/ticketstockattribute/eval"

    API_EVALUATE_GENERATE_CYLINDERS = BASE_RULES_ENGINE_URL + "/tools/cylinders/eval"