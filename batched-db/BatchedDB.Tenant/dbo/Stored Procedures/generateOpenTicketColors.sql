
CREATE   PROCEDURE [dbo].[generateOpenTicketColors]

AS

BEGIN

	if OBJECT_ID('OpenTicketColors') is not null
		DROP table OpenTicketColors

	;With openflexotickets as (Select Distinct Number
				From dbo.OpenTicketRoutesRaw
				Where TaskWorkCenter Like '%Flexo%' and routefeasible=1 and TaskDone = 0
				
				Union All
				
				Select Ticket_No as Number
				From [dbo].[LastJobsRun] ljr
				Left Join  [MasterEquipmentReference] mer on ljr.PressNo=mer.Press
				Where mer.Workcenter Like '%Flexo%'),
	
	ticketcolors as (
						Select Distinct ti.TicketNumber, UPPER(replace(pc.Color, ' ', '')) as Color
							FROM
								dbo.ProductColor pc 
							INNER JOIN 
								dbo.ticketItem ti
								ON pc.UniqueProdID=ti.UniqueProdID
							WHERE 
								ti.TicketNumber in (Select Number From openflexotickets) and pc.Color <> '' and pc.Color Not Like '%No Varnish%' and UPPER(replace(pc.Color, ' ', ''))<>'ADHESIVEKILL' and UPPER(pc.Color) <> 'CMYK'

						Union ALL

						Select Distinct ti.TicketNumber, 'C' as Color
						FROM
								dbo.ProductColor pc 
							INNER JOIN 
								dbo.ticketItem ti
								ON pc.UniqueProdID=ti.UniqueProdID
						WHERE 
								ti.TicketNumber in (Select Number From openflexotickets) and UPPER(pc.Color) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketNumber, 'M' as Color
						FROM
								dbo.ProductColor pc 
							INNER JOIN 
								dbo.ticketItem ti
								ON pc.UniqueProdID=ti.UniqueProdID
						WHERE 
								ti.TicketNumber in (Select Number From openflexotickets) and UPPER(pc.Color) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketNumber, 'Y' as Color
						FROM
								dbo.ProductColor pc 
							INNER JOIN 
								dbo.ticketItem ti
								ON pc.UniqueProdID=ti.UniqueProdID
						WHERE 
								ti.TicketNumber in (Select Number From openflexotickets) and UPPER(pc.Color) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketNumber, 'K' as Color
						FROM
								dbo.ProductColor pc 
							INNER JOIN 
								dbo.ticketItem ti
								ON pc.UniqueProdID=ti.UniqueProdID
						WHERE 
								ti.TicketNumber in (Select Number From openflexotickets) and UPPER(pc.Color) = 'CMYK')

	Select *
	Into OpenTicketColors
	From ticketcolors

END

--exec generateOpenTicketColors
