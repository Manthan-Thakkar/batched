CREATE TABLE [dbo].[RolePermission](
    [Id]                VARCHAR(36)  CONSTRAINT [PK_RolePermissionId] PRIMARY KEY NOT NULL,
    [BusinessEntityId]  VARCHAR(36)  CONSTRAINT [FK_RolePermission_BusinessEntityId] FOREIGN KEY REFERENCES BusinessEntity(Id),
    [RoleId]            VARCHAR(36)  CONSTRAINT [FK_RolePermission_RoleId] FOREIGN KEY REFERENCES Role(Id),
    [CreatedOn]         DATETIME     NULL,
    [ModifiedOn]        DATETIME     NULL
)