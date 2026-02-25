CREATE PROCEDURE [dbo].[spShipTimeDslValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN

	---- Ticket shipping
	SELECT
		TS.[TicketId] 					AS __ticketId,
		TS.[SourceShipVia] 		        AS Shipvia_dsl,
		TM.[SourceCustomerId] 		AS CustomerNum_dsl,
		TM.[CustomerName] 			AS CustomerName_dsl,
		TM.[SourcePriority] 		AS TicketPriority_dsl
	FROM 
		TicketShipping TS
		INNER JOIN TicketMaster TM on TS.TicketId = TM.Id
	    --INNER JOIN Ticket T on Tm.SourceTicketId = T.Number --- Eleminate deleted tickets from ticket but present in ticketmaster
	WHERE TM.IsOpen = 1 and Tm.SourceTicketType <> 0

END

