from batched_common.EvalFunction import *

def TicketAttributes(event):
    return Eval_Function(event,Constants.API_EVALUATE_TICKET_ATTRIBUTES,'TicketAttributesStatusCheck')

def TicketTask(event):
    return Eval_Function(event,Constants.API_EVALUATE_TICKET_TASK,'TicketTaskStatusCheck')

def TicketTaskCleanup(event):
    return Eval_Function(event,Constants.API_CLEANUP_TICKET_TASK,'TicketTaskCleanupStatusCheck')

def Reservations(event):
    return Eval_Function(event,Constants.API_EVALUATE_RESERVATIONS,'ReservationsStatusCheck')

def GenerateCylinders(event):
    return Eval_Function(event,Constants.API_EVALUATE_GENERATE_CYLINDERS,'GenerateCylindersStatusCheck')

def StockPlanning(event):
    return Eval_Function(event,Constants.API_EVALUATE_STOCK_PLANNING,'StockPlanningStatusCheck')

def TicketStockAttributes(event):
    return Eval_Function(event,Constants.API_EVALUATE_TICKET_STOCK_ATTRIBUTE,'TicketStockAttributesStatusCheck')

def FeasibleRoutes(event):
    return Eval_Function(event,Constants.API_EVALUATE_FEASIBLE_ROUTES,'FeasibleRoutesStatusCheck')

def ReportsData(event):
    return Eval_Function(event,Constants.API_EVALUATE_REPORTS_DATA,'ReportsDataStatusCheck')

def Changeovers(event):
    return Eval_Function(event,Constants.API_EVALUATE_CHANGEOVERS,'ChangeoversStatusCheck')