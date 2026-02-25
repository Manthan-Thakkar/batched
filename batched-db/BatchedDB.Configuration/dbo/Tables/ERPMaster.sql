	CREATE TABLE [dbo].[ERPMaster](
	[Id] varchar(36)  PRIMARY KEY  NOT NULL,
	[Name] Varchar(128) NOT NULL,
	[CreateIntermediateTables] bit NOT NULL DEFAULT 0,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NULL
	);