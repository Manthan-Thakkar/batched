CREATE TABLE [dbo].[ExportDestination](
	[ID]								VARCHAR (36)  NOT NULL,
	[JobId]								VARCHAR (36)  NOT NULL CONSTRAINT [FK_ExportDestination_JobID] FOREIGN KEY REFERENCES Job(Id),
	[Destination]					NVARCHAR(256) NOT NULL,
	[Type]					NVARCHAR(20)  NOT NULL,
	[CreatedOn]							DATETIME      NOT NULL,
    [ModifiedOn]						DATETIME      NULL,
    CONSTRAINT [PK_ExportDestinationID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
	CONSTRAINT UED_JID UNIQUE (JobId)
);