CREATE TABLE [dbo].[CloudJobQuery](
	[Id]								VARCHAR (36)  NOT NULL,
	[JobId]								VARCHAR (36)  NOT NULL CONSTRAINT [FK_CloudJobQuery_JobId] FOREIGN KEY REFERENCES Job(Id),
	[DatasetName]						NVARCHAR(128) NOT NULL,
	[QueryText]							NVARCHAR(MAX) NULL,
	[Sequence]							INT			  NOT NULL,
    [LastSuccessAt]						DATETIME      NULL,
	[CreatedOn]							DATETIME      NOT NULL,
    [ModifiedOn]						DATETIME      NULL,
    CONSTRAINT [PK_CloudJobQueryID] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);