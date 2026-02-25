CREATE TABLE [dbo].[UserOTP] (
    [Id]        VARCHAR (36)  NOT NULL,
    [UserId]    VARCHAR (36)  NULL,
    [OTP]       NVARCHAR (256) NULL,
    [ValidFrom] DATETIME      NULL,
    [ValidTo]   DATETIME      NULL,
    CONSTRAINT [PK_UserOTPId] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserOTP_UserAccountsId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[UserAccounts] ([Id])
);

