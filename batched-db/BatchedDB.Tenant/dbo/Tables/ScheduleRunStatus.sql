CREATE TABLE [dbo].[scheduleRunStatus](
	[Id] [varchar](36) CONSTRAINT [PK_scheduleRunStatus] PRIMARY KEY NOT NULL,
	[Entity] [varchar](50) NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[ExpiryTimeStamp] [datetime] NOT NULL,
	[TimeStamp] [datetime] NOT NULL,
	[RefId] [varchar](36) NOT NULL,
	[CreateOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL);