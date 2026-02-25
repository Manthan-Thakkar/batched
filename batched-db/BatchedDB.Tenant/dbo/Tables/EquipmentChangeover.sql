CREATE TABLE [dbo].[EquipmentChangeover] (
    [Id]                  VARCHAR (36)  NOT NULL,
    [Name]                NVARCHAR (32)  NULL,
    [Description]         NVARCHAR (256) NULL,
    [ComparisonType]      NVARCHAR (16)  NULL,
    [ChangeTimeInMinutes] NVARCHAR (16)  NULL,
    [CreatedOn]           DATETIME      NULL,
    [ModifiedOn]          DATETIME      NULL,
    [IsEnabled]           BIT           NOT NULL,
    [EquipmentId]         VARCHAR (36)  NOT NULL,
    [TicketAttributeId]      VARCHAR (36)  NULL,
    [Scope]                  [nvarchar](16) NULL,
    [RuleText]              varchar(1024)  null,
    [ApplicableRuleText]    varchar(1024)  null,
    [SavedRuleText]         varchar(1024)  null,
    [GroupId]               varchar(36) NOT NULL
    CONSTRAINT [PK_EquipmentChangeoverId] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_EquipmentChangeover_EquipmentMasterID] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[EquipmentMaster] ([ID]),
    CONSTRAINT [FK_EquipmentChangeover_TicketAttributeID] FOREIGN KEY ([TicketAttributeId]) REFERENCES [dbo].[TicketAttribute] ([ID])
); 

