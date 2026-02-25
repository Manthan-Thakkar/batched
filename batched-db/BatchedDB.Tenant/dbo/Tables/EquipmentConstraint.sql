CREATE TABLE [dbo].[EquipmentConstraint] (
    [Id]                VARCHAR (36)  NOT NULL,
    [EquipmentId]       VARCHAR (36)  NOT NULL,
    [Name]              NVARCHAR (64)  NOT NULL,
    [Description]       NVARCHAR (256) NOT NULL,
    [Operator]          NVARCHAR (16)  NULL,
    [Value]             NVARCHAR (64)  NULL,
    [TicketAttributeId] VARCHAR (36)  NULL,
    [IsEnabled]         BIT           NOT NULL,
    [CreatedOn]         DATETIME      NOT NULL,
    [ModifiedOn]        DATETIME      NULL,
    [Scope]             NVARCHAR(16) NULL,
    [RuleText]          VARCHAR(8000) NULL,
    [GroupId]           VARCHAR(36) NOT NULL
    CONSTRAINT [PK_EquipmentConstraintId]  PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_EquipmentConstraint_EquipmentMasterID]  FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[EquipmentMaster] ([ID]),
    CONSTRAINT [FK_EquipmentConstraint_TicketAttributeID] FOREIGN KEY ([TicketAttributeId]) REFERENCES [dbo].[TicketAttribute] ([ID])
);

