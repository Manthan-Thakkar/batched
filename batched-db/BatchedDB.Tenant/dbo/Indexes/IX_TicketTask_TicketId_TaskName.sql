CREATE NONCLUSTERED INDEX [IX_TicketTask_TicketId_TaskName] ON [dbo].[TicketTask]
(
	[TicketId] ASC
)
INCLUDE([TaskName],[Sequence],[IsComplete],[EstMaxDueDateTime])