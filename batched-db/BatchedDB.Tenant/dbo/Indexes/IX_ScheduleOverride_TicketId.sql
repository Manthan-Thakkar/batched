CREATE NONCLUSTERED INDEX [IX_ScheduleOverride_TicketId] ON [dbo].[ScheduleOverride]
(
	[TicketId] ASC
)
INCLUDE([TaskName],[IsScheduled])