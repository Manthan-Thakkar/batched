CREATE TABLE [dbo].[OdbcDataSourceQuery](
	[ID]								VARCHAR (36)  NOT NULL,
	[DataSourceId]						VARCHAR (36)  NOT NULL CONSTRAINT [FK_OdbcDataSourceQuery_DataSourceId] FOREIGN KEY REFERENCES DataSource(Id),
	[DatasetName]						NVARCHAR(128) NOT NULL,
	[QueryText]							NVARCHAR(MAX) NULL,
	[Sequence]							INT			  NOT NULL,
	[CreatedOn]							DATETIME      NOT NULL,
    [ModifiedOn]						DATETIME      NULL,
    CONSTRAINT [PK_OdbcDataSourceQueryID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);