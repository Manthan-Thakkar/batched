CREATE NONCLUSTERED INDEX [IX_ScheduleArchiveStatus_TenantId_ScheduleArchiveId] ON [dbo].[ScheduleArchiveStatus]
	(
		[TenantId] ASC,
		[ScheduleArchiveId] ASC
	)
	INCLUDE([Status],[RetryCount],[CorrelationId])