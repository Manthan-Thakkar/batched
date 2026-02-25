
CREATE   PROCEDURE [dbo].[generateOpenTicketTools]

AS

BEGIN

	if OBJECT_ID('OpenTicketTools') is not null
		DROP table OpenTicketTools

	;With opentickets as (Select Distinct Number
				From dbo.OpenTicketRoutesRaw
				Where routefeasible=1 and TaskDone = 0
				
				Union All
				
				Select Ticket_No as Number
				From [dbo].[LastJobsRun] ljr
				Left Join  [MasterEquipmentReference] mer on ljr.PressNo=mer.Press),
	
	tickettools as (
						Select *
						From dbo.TicketTools
						Where Number in (Select Number from opentickets))

	Select *
	Into OpenTicketTools
	From tickettools

END

--exec generateOpenTicketTools
