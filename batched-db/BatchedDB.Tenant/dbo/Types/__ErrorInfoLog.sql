CREATE TYPE [dbo].[__ErrorInfoLog] AS TABLE
(
	[CorelationId] 	[NVARCHAR](100) NULL,
	[LogType] 		[nvarchar](10) NULL,
	[TenantId] 		[nvarchar](50) NULL,
	[AppName] 		[nvarchar](100) NULL,
	[Status] 		[nvarchar](20) NULL,
	[TimeTakenInMs] [int] NULL,
	[Timestamp] 	[datetime] NULL,
	[SPName]		[nvarchar](100) NULL,
	[ActionName] 	[nvarchar](100) NULL,
	[Type] 			[nvarchar](100) NULL,
	[CustomMessage] [nvarchar](4000) NULL
)
