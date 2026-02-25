from eval_check_status_steps import *

def lambda_handler(event,context):
    if event['stepsDetails']['NextStep'] == "TicketAttributesStatusCheck":
        return TicketAttributesStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "TicketTaskStatusCheck":
        return TicketTaskStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "TicketTaskCleanupStatusCheck":
        return TicketTaskCleanupStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "ReservationsStatusCheck":
        return ReservationsStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "GenerateCylindersStatusCheck":
        return GenerateCylindersStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "StockPlanningStatusCheck":
        return StockPlanningStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "TicketStockAttributesStatusCheck":
        return TicketStockAttributesStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "FeasibleRoutesStatusCheck":
        return FeasibleRoutesStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "ReportsDataStatusCheck":
        return ReportsDataStatusCheck(event)

    elif event['stepsDetails']['NextStep'] == "ChangeoversStatusCheck":
        return ChangeoversStatusCheck(event)