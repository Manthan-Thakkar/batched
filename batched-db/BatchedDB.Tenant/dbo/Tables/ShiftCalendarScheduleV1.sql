CREATE TABLE [dbo].[ShiftCalendarScheduleV1]
(
	[Id] [varchar](36) CONSTRAINT [PK_ShiftCalendarScheduleV1] PRIMARY KEY  NOT NULL,
	[Name] [varchar](255) NULL,
	[Description] [varchar](500) NULL,
	[IsEnabled] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL
)