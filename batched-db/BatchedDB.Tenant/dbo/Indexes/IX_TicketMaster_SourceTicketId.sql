CREATE NONCLUSTERED INDEX [IX_TicketMaster_SourceTicketId]
ON
	[dbo].[TicketMaster]
	([SourceTicketId])
	INCLUDE ([ID])
