CREATE TABLE [dbo].[ScheduleReport_Temp](
	[Id] [varchar](36) NOT NULL PRIMARY KEY,
	[EquipmentId] [varchar](36) NOT NULL,
	[SourceTicketId] [NVARCHAR](255) Null,
	[TaskName] [nvarchar](255) NOT NULL,
	[StartsAt] [datetime] NOT NULL,	
	[EndsAt] [datetime] NOT NULL,
	[ChangeoverMinutes] [float] NULL,
	[TaskMinutes] [float] NULL,
	[IsPinned] [bit] NULL,
	[FeasibilityOverride] [bit] NULL,
	[IsUpdated] [bit] NULL,
	[IsCalculated] [bit] NULL,
	[MasterRollNumber] [varchar](255) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[PinType] [nvarchar](24) null,
	[ChangeoverCount] int NULL,
	[ChangeoverDescription] nvarchar(4000) NULL, 
    [ForcedGroup] NVARCHAR(128) NULL
  	CONSTRAINT [AK_Temp_EquipmentId_TaskName_SourceTicketId] UNIQUE NONCLUSTERED (EquipmentId,SourceTicketId,TaskName)	
)
