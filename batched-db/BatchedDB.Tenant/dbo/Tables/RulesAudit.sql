CREATE TABLE [dbo].[RulesAudit]
(
	[Id] varchar(36) NOT NULL PRIMARY KEY,
	[Type] varchar(64) NOT NULL,
	[ModifiedOnUtc] datetime NOT NULL
)
