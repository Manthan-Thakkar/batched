CREATE TABLE [dbo].[UserProfile] (
    [Id]                 VARCHAR (36)   NOT NULL,
    [UserId]             VARCHAR (36)   NULL,
    [FirstName]          NVARCHAR (4000) NOT NULL,
    [LastName]           NVARCHAR (4000) NOT NULL,
    [EmailAddress]       NVARCHAR (4000) NOT NULL,
    [PhoneCountryPrefix] NVARCHAR (10)  NULL,
    [PhoneNumber]        NVARCHAR (4000)  NULL,
    [PhoneType]          NVARCHAR (20)  NULL,
    [POPermission]       INT  NULL, 
    [CreatedOn]          DATETIME       NOT NULL,
    [ModifiedOn]         DATETIME       NULL,
    CONSTRAINT [PK_UserProfileId] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserProfile_UserAccountsId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[UserAccounts] ([Id]),
    CONSTRAINT [USP_SDID] UNIQUE NONCLUSTERED ([UserId] ASC)
);

