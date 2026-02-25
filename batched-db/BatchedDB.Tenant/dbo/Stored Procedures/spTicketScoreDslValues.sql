
CREATE PROCEDURE [dbo].[spTicketScoreDslValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN

	
	---- Ticket MAster
	SELECT
		TM.[ID] 					AS __ticketId,
		TM.[SourceCustomerId] 		AS CustomerNum_dsl,
		TM.[CustomerName] 			AS CustomerName_dsl,
		CR.[Rank]					AS CustomerRank_dsl
	FROM 
		TicketMASter TM 
		LEFT JOIN CustomerRank CR on Tm.SourceCustomerId = CR.SourceCustomerId
	WHERE TM.IsOpen =1 or tm.IsOnHold =1
END

GO


