
CREATE PROCEDURE [dbo].[spTicketImportFilterDslValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN
	
	---- Ticket MAster
	SELECT
		TM.[ID] 					AS __ticketId,
		TM.[SourcePriority] 		AS Priority_dsl
	FROM 
		TicketMASter TM
	WHERE TM.IsOpen =1 or tm.IsOnHold =1
END


GO


