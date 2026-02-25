CREATE NONCLUSTERED INDEX [IX_TicketMaster_TicketId_StockStatus]
	ON [dbo].[TicketMaster]
	(Id) 
	INCLUDE ([StockStatus])