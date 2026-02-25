CREATE NONCLUSTERED INDEX [IX_ScheduleArchiveInfo_Id_TenantId] ON [dbo].[ScheduleArchiveInfo]
	(
		[Id] ASC,
		[TenantId] ASC
	)
	INCLUDE([ArchiveTimeUTC],[ArchiveTimeTenantTimezone])