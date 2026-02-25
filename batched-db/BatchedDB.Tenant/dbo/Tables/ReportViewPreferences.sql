CREATE TABLE [dbo].[ReportViewPreferences]
(
	[Id]					[VARCHAR] (36)		PRIMARY KEY NOT NULL,
	[ReportViewId]			[VARCHAR] (36)		NOT NULL,
	[Context]				[VARCHAR] (36)		NOT NULL,
	[Value]					[VARCHAR] (36)		NOT NULL,
	[CreatedBy]				[VARCHAR] (100)		NOT NULL,
	[ModifiedBy]			[VARCHAR] (100)		NOT NULL,
	[CreatedOnUtc]			DATETIME			NOT NULL,
	[ModifiedOnUtc]			DATETIME			NOT NULL
);