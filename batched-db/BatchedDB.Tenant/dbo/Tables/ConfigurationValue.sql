CREATE TABLE [dbo].[ConfigurationValue]
(
	[Id] [varchar](36) NOT NULL,
	[Value] [varchar](1000) NULL,
	[ConfigId] [varchar](36) NULL,
	[IsDisabled] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	CONSTRAINT [PK_ConfigurationValue] PRIMARY KEY NONCLUSTERED([ID] ASC),
	CONSTRAINT [FK_ConfigurationValue_ConfigurationMasterID]  FOREIGN KEY ([ConfigId]) REFERENCES [dbo].[ConfigurationMaster] ([ID])
)
