CREATE PROCEDURE [dbo].[spCalculateUnassignedJobsDSLValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN

	
	---- Ticket shipping
	SELECT
		TS.[TicketId] 					AS __ticketId,
		TS.[TicketId] 					AS __contextId,
		TS.[ShipByDateTime] 		    AS ShipTime_dsl
	FROM 
		TicketShipping TS WITH (NOLOCK)
		INNER JOIN TicketMaster TM WITH (NOLOCK) on TS.TicketId = TM.Id
	WHERE TM.ID in (SELECT TicketId from @tickets)

END