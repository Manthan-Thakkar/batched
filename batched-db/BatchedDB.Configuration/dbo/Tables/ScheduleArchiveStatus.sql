CREATE TABLE [dbo].[ScheduleArchiveStatus](
		[Id] [varchar](36) CONSTRAINT [PK_ScheduleArchiveStatusId] PRIMARY KEY  NOT NULL,
		[TenantId] [varchar](36) CONSTRAINT [FK_Id_Tenant] FOREIGN KEY REFERENCES Tenant(Id) NOT NULL,
		[ScheduleArchiveID] [varchar](36) CONSTRAINT [FK_ScheduleArchiveId_ScheduleArchive] FOREIGN KEY REFERENCES ScheduleArchiveInfo(Id) NULL,
		[FacilityScheduleArchiveId] [varchar](36) CONSTRAINT [FK_FacilityScheduleArchiveId_ScheduleArchive] FOREIGN KEY REFERENCES FacilityScheduleArchival(Id) NULL,
		[Status] [varchar](15) NOT NULL,
		[ErrorMessage] [nvarchar](MAX) NULL,
		[RetryCount] [int] NOT NULL DEFAULT 0,
		[CorrelationId] [varchar](36) NOT NULL,
		[CreatedOnUTC] [datetime] NOT NULL
	)