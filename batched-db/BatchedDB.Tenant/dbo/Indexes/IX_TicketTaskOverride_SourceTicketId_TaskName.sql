CREATE NONCLUSTERED INDEX [IX_TicketTaskOverride_TicketId_TaskName] ON [dbo].[TicketTaskOverride]
(
	[TicketId]
)
INCLUDE([TaskName])