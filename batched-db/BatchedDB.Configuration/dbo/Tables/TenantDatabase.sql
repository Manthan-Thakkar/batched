CREATE TABLE [dbo].[TenantDatabase]
(
    [ID]                    VARCHAR(36)     NOT NULL,
    [TenantId]              VARCHAR(36)     CONSTRAINT [FK_TenantDatabase_TenantId] FOREIGN KEY REFERENCES Tenant(ID),
    [DbName]                NVARCHAR(64)    NULL,
    [DatabaseInstanceId]    VARCHAR(36)     NULL CONSTRAINT [FK_DatabaseInstance_DatabaseInstanceId] FOREIGN KEY REFERENCES DatabaseInstance(Id),
    [TenantSizeTypeId]      VARCHAR(36)     NULL CONSTRAINT [FK_TenantSizeType_TenantSizeTypeId] FOREIGN KEY REFERENCES TenantSizeType(Id),
    CONSTRAINT [PK_TenantDatabaseID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT USP_CSTNTDB UNIQUE (TenantId)
)
