CREATE TABLE [dbo].[Job] (
	[ID]								VARCHAR (36)	NOT NULL,
	[Name]								NVARCHAR (256)  NOT NULL,
	[AgentId]							VARCHAR(36)		NOT NULL CONSTRAINT [FK_Job_AgentID] FOREIGN KEY REFERENCES Agent(Id),
	[RecurrenceRequired]				BIT				NOT NULL,
	[RecurrenceInMinutes]				INT				NOT NULL,
	[JobType]							NVARCHAR(30)	NOT NULL, --fullldataload/incrementaldataload/HotFolder
	[SourceType]						NVARCHAR(56)	NOT NULL, --OdbcDataSource/PostgresQL
	[DestinationType]					NVARCHAR(56)	NOT NULL, --S3Bucket
	[IsEnabled]							BIT				NOT NULL,
	[Mechanism]							varchar(10)		NOT NULL default('Import'),
	[JobFirstRunAt]						DATETIME		NULL,
	[JobLastRunAt]						DATETIME		NULL,
	[EventBridgeScheduleARN]			VARCHAR(2048)	NULL, --Only populated for cloud agent jobs
	[MaxParallelism]					INT				NOT NULL DEFAULT(1),
	[CreatedOn]							DATETIME		NOT NULL,
    [ModifiedOn]						DATETIME		NULL,
    CONSTRAINT [PK_JobID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);