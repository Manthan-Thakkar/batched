CREATE TABLE [dbo].[ScheduleArchiveInfo](
		[Id] [varchar](36) CONSTRAINT [PK_ScheduleArchiveId] PRIMARY KEY  NOT NULL,
		[TenantId] [varchar](36) CONSTRAINT [FK_TenantId_Tenant] FOREIGN KEY REFERENCES Tenant(ID) NOT NULL,
		[TotalArchiveDays] [smallint] NOT NULL,
		[ArchiveTimeUTC] [time] NOT NULL,
		[ArchiveTimeTenantTimezone] [time] NOT NULL,
		[IsEnabled] BIT,
		[CreatedOnUTC] [datetime] NOT NULL,
		[ModifiedOnUTC] [datetime] NOT NULL,
		[CreatedBy] [varchar](100) NOT NULL,
		[ModifiedBy] [varchar](100)NOT NULL,
		CONSTRAINT UQ_TenantId_ArchiveTimeUTC UNIQUE(TenantId, ArchiveTimeUTC)
	)