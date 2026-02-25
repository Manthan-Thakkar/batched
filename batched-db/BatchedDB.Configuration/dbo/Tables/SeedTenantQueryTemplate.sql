CREATE TABLE [dbo].[SeedTenantQueryTemplate]
(
    [ID]            VARCHAR(36) NOT NULL,
    [TableName]     NVARCHAR(64) NOT NULL,
    [QueryTemplate] NVARCHAR(MAX) NOT NULL,
    [IsEnabled]     BIT NOT NULL,
    CONSTRAINT [PK_TenantSeedQueryTemplateID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);
