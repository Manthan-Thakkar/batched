CREATE TABLE [dbo].[Role] (
    [Id]                   VARCHAR (36)   NOT NULL,
    [Name]                 NVARCHAR (100) NOT NULL,
    [ScopeHierarchyId]     VARCHAR(36)    NULL    CONSTRAINT [FK_Role_ScopeHierarchyId] FOREIGN KEY REFERENCES ScopeHierarchy(Id),
    [CreatedOn]            DATETIME       NULL,
    [ModifiedOn]           DATETIME       NULL,
    [IsEnabled]            BIT            NULL,
    [CreatedBy] NVARCHAR(4000) NULL,
    [ModifiedBy] NVARCHAR(4000) NULL,
    CONSTRAINT [PK_RoleId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);

