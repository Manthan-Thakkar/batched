CREATE TABLE [dbo].[JobRunAdditionalInfo] (	
	[Id]			VARCHAR(36) NOT NULL,
	[JobRunId]		VARCHAR(36) NOT NULL CONSTRAINT [FK_JobRunAdditionalInfo_JobRunId] FOREIGN KEY REFERENCES JobRun(Id),
	[InfoKey]		NVARCHAR(100),
	[InfoValue]     NVARCHAR(MAX),
	CONSTRAINT [PK_JobRunAdditionalInfoId] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);