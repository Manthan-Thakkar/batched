CREATE TABLE [dbo].[PowerBIConfiguration] (
	[Id]							VARCHAR (36)    NOT NULL,
	[TenantId]						VARCHAR (36)    NOT NULL,
	[ReportName]					NVARCHAR(100)   NOT NULL,
	[ReportId]						VARCHAR(36)     NOT NULL,
	[WorkspaceId]					VARCHAR(36)     NOT NULL,
	[CreatedOn]						DATETIME        NOT NULL,
	[ModifiedOn]					DATETIME        NOT NULL,
	CONSTRAINT [PK_PowerBIConfiguration_Id] PRIMARY KEY ([Id]),
	CONSTRAINT [FK_PowerBIConfiguration_TenantId] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant] ([ID])
)