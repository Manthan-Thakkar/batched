CREATE TABLE [dbo].[MasterDataType](
	[Id] [varchar](36) NOT NULL,
	[Name] [varchar](10) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	CONSTRAINT [PK_MasterDataType] PRIMARY KEY NONCLUSTERED([ID] ASC)
);