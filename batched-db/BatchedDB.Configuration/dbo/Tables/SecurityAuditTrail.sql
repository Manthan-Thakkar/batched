CREATE TABLE [dbo].[SecurityAuditTrail] 
(
    [ID]             VARCHAR (36) NOT NULL,
    [UserId]         VARCHAR (36) NULL,
    [Status]         NVARCHAR (10) NULL,
    [TimeStamp]      DATETIME     NULL,
    [ClientName]     NVARCHAR (64) NULL,
    [ApiErrorCode]   NVARCHAR (50) NULL,
    [AuditTrailType] NVARCHAR (20) NULL,
    [Username]       NVARCHAR(100) null,
    [Description]    NVARCHAR(256) null,
    [UserAgentInfo]  NVARCHAR(256) null
    CONSTRAINT [PK_SecurityAuditTrailID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_SecurityAuditTrail_UserAccountsId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[UserAccounts] ([Id])
)