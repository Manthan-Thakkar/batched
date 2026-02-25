CREATE TABLE [dbo].[UserRole] (
    [Id]              VARCHAR (36)   NOT NULL,
    [UserId]          VARCHAR (36)   NULL,
    [RoleId]          VARCHAR (36)   NULL,
    [CreatedOn]       DATETIME       NULL,
    [ModifiedOn]      DATETIME       NULL,
    [CreatedBy] NVARCHAR(4000) NULL,
    [ModifiedBy] NVARCHAR(4000) NULL,
    CONSTRAINT [PK_UserRoleId] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserRole_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Role] ([Id]),
    CONSTRAINT [FK_UserRole_UserAccountsId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[UserAccounts] ([Id])
);

