from datetime import datetime, timedelta


class Constants:

    AWSPARAM_CONNECTIONSTRING = "py-batched-cn"
    AWSPARAM_ENCRYPTION = True
    AWSPARAM_ALGO_TRIGGER_URL = "algo_trigger_url"

    #Apis
    BASE_R_ALGO_URL = "/api/scheduler/v1"

    API_TRIGGER_ALGO = BASE_R_ALGO_URL + "/trigger"