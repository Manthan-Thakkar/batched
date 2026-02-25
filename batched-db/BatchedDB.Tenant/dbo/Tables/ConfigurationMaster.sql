CREATE TABLE [dbo].[ConfigurationMaster]
(
	[Id] [varchar](36) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[DataTypeId] [varchar](36) NULL,
	[IsMany] [bit] NOT NULL,
	[IsDisabled] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	CONSTRAINT [PK_ConfigurationMaster] PRIMARY KEY NONCLUSTERED([ID] ASC),
	CONSTRAINT [FK_ConfigurationMaster_MasterDataTypeID]  FOREIGN KEY ([DataTypeId]) REFERENCES [dbo].[MasterDataType] ([ID])
)
