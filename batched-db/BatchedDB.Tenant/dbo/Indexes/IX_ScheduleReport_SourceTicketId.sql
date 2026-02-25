CREATE NONCLUSTERED INDEX [IX_ScheduleReport_SourceTicketId] ON [dbo].[ScheduleReport]
(
	[SourceTicketId] ASC
)
INCLUDE([TaskName],[StartsAt],[EndsAt],[PinType])