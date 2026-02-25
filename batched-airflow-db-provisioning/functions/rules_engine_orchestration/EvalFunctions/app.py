import os
import json
import boto3
# from steps import *
from eval_steps import *

def lambda_handler(event,context):
    if 'stepsDetails' not in event:
        return TicketAttributes(event)

    elif event['stepsDetails']['NextStep'] == "TicketTask":
        return TicketTask(event)

    elif event['stepsDetails']['NextStep'] == "TicketTaskCleanup":
        return TicketTaskCleanup(event)

    elif event['stepsDetails']['NextStep'] == "Reservations":
        return Reservations(event)

    elif event['stepsDetails']['NextStep'] == "GenerateCylinders":
        return GenerateCylinders(event)

    elif event['stepsDetails']['NextStep'] == "StockPlanning":
        return StockPlanning(event)

    elif event['stepsDetails']['NextStep'] == "TicketStockAttributes":
        return TicketStockAttributes(event)

    elif event['stepsDetails']['NextStep'] == "FeasibleRoutes":
        return FeasibleRoutes(event)

    elif event['stepsDetails']['NextStep'] == "ReportsData":
        return ReportsData(event)

    elif event['stepsDetails']['NextStep'] == "Changeovers":
        return Changeovers(event)