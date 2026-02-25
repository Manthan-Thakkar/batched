
CREATE TABLE [dbo].[WebSvcDataQuery](
	[ID]								VARCHAR (36)    NOT NULL,
	[DataSourceId]						VARCHAR (36)    NOT NULL CONSTRAINT [FK_WebSvcDataQuery_DataSourceId] FOREIGN KEY REFERENCES DataSource(Id),
	[DatasetName]						NVARCHAR(256)   NOT NULL,
	[APIUrl]							NVARCHAR(256)   NOT NULL,
	[QueryString]						NVARCHAR(256)   NOT NULL,
	[Headers]							NVARCHAR(MAX)   NULL,
	[Body]								NVARCHAR(MAX)   NULL,
	[HttpMethod]						NVARCHAR(256)	NOT NULL,
	[Sequence]							INT				NOT NULL,
	[CreatedOn]							DATETIME        NOT NULL,
    [ModifiedOn]						DATETIME        NULL,
    CONSTRAINT [PK_WebSvcDataQueryID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);
