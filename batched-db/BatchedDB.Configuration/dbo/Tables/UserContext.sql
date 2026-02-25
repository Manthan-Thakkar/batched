CREATE TABLE [dbo].[UserContext]
(
	[Id]					[VARCHAR] (36)		PRIMARY KEY NOT NULL,
	[UserId]				[VARCHAR] (36)		NOT NULL,
	[TenantId]				[VARCHAR] (36)		NOT NULL,
	[Context]				[VARCHAR] (36)		NOT NULL,
	[Value]					[VARCHAR] (36)		NOT NULL,
	[ValueDescription]		[VARCHAR] (100)		NOT NULL,
	[CreatedOnUtc]			DATETIME			NOT NULL,
	[ModifiedOnUtc]			DATETIME			NOT NULL
);