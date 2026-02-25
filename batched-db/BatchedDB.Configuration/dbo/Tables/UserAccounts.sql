CREATE TABLE [dbo].[UserAccounts] (
    [Id]                  VARCHAR (36)   NOT NULL,
    [Username]            NVARCHAR (100) NOT NULL,
    [Password]            NVARCHAR (100) NOT NULL,
    [Source]              NVARCHAR (100) NOT NULL,
    [Scope]               NVARCHAR (100) NOT NULL,
    [Enabled]             BIT            NOT NULL,
    [PromptResetPassword] BIT            NOT NULL,
    [CreatedOn]           DATETIME       NOT NULL,
    [LastLogin]           DATETIME       NULL,
    [ModifiedOn]          DATETIME       NULL,
    [SourceUserId]        NVARCHAR(64)   NULL, 
    CONSTRAINT [PK_UserAccountsId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);

