CREATE TABLE [dbo].[DataSource](
	[ID]								VARCHAR (36)  NOT NULL,
	[JobId]								VARCHAR (36)  NOT NULL  CONSTRAINT [FK_DataSource_JobID] FOREIGN KEY REFERENCES Job(Id),
	[ConnectionString]					NVARCHAR(128) NOT NULL,
	[DataSourceType]					NVARCHAR(20)  NOT NULL,
	[CreatedOn]							DATETIME      NOT NULL,
    [ModifiedOn]						DATETIME      NULL,
    CONSTRAINT [PK_DataSourceID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);