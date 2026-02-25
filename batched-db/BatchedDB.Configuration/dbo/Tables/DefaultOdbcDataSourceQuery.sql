CREATE TABLE [dbo].[DefaultOdbcDataSourceQuery]
(
	[ID]            VARCHAR (36) NOT NULL,
    [DatasetName]   NVARCHAR (128) NOT NULL,
    [QueryText]     NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_DefaultOdbcDataSourceQuery] PRIMARY KEY NONCLUSTERED ([ID] ASC)
)
