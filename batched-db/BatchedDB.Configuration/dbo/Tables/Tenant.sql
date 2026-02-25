CREATE TABLE [dbo].[Tenant] (
    [ID]         VARCHAR (36) NOT NULL,
    [Name]       NVARCHAR (64) NOT NULL,
    [TimeZone]   NVARCHAR (64) NULL,
    [CreatedOn]  DATETIME     NULL,
    [ModifiedOn] DATETIME     NULL,
    [IsEnabled]  BIT          NOT NULL,
    [ClientId]   VARCHAR (36) NOT NULL,
    [Status]       varchar(20),
    [ERPId]     varchar (36) NULL,
    CONSTRAINT [PK_TenantID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Tenant_ClientId] FOREIGN KEY ([ClientId]) REFERENCES [dbo].[Client] ([ID])
);

