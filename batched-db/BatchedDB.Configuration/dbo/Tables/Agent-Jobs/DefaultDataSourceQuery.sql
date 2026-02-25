CREATE TABLE [dbo].[DefaultDataSourceQuery]
(
	[ID]                    VARCHAR (36) NOT NULL,
    [DatasetName]           NVARCHAR (128) NOT NULL,
    [QueryText]             NVARCHAR (MAX) NOT NULL,
    [DataSourceType]		NVARCHAR(20)  NOT NULL,
    CONSTRAINT [PK_DefaultDataSourceQuery] PRIMARY KEY NONCLUSTERED ([ID] ASC)
)
