from batched_common.StatusCheck import *

def TicketAttributesStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_TICKET_ATTRIBUTES,"TicketTask")

def TicketTaskStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS__TICKET_TASK,"TicketTaskCleanup")

def TicketTaskCleanupStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS__TICKET_TASK,"Reservations")

def ReservationsStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_RESERVATIONS,"GenerateCylinders")

def GenerateCylindersStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_GENERATE_CYLINDERS,"StockPlanning")

def StockPlanningStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_STOCK_PLANNING,"TicketStockAttributes")

def TicketStockAttributesStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_TICKET_STOCK_ATTRIBUTE,"FeasibleRoutes")

def FeasibleRoutesStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_FEASIBLE_ROUTES,"ReportsData")

def ReportsDataStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_REPORTS_DATA,"Changeovers")

def ChangeoversStatusCheck(event):
    return StatusCheck(event,Constants.API_STATUS_CHANGEOVERS,"Last")