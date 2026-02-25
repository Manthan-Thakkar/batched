CREATE TABLE [dbo].[WorkcenterChangeover] (
    [ID]                  VARCHAR (36)  NOT NULL,
    [Name]                NVARCHAR (32)  NULL,
    [Description]         NVARCHAR (256) NULL,
    [ComparisonType]      NVARCHAR (16)  NULL,
    [ChangeTimeInMinutes] NVARCHAR (16)  NULL,
    [CreatedOn]           DATETIME      NULL,
    [ModifiedOn]          DATETIME      NULL,
    [IsEnabled]           BIT           NOT NULL,
    [WorkcenterTypeId]    VARCHAR (36)  NOT NULL,
    [TicketAttributeId]   VARCHAR (36)  NULL,
    [Scope]               [nvarchar](16) NULL,
    [RuleText]              varchar(1024)  null,
    [ApplicableRuleText]     varchar(1024)  null,
    [SavedRuleText]         varchar(1024)  null,
    CONSTRAINT [PK_WorkcenterChangeoverID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_WorkcenterChangeover_TicketAttributeId] FOREIGN KEY ([TicketAttributeId]) REFERENCES [dbo].[TicketAttribute] ([ID]),
    CONSTRAINT [FK_WorkcenterChangeover_WorkCenterTypeId] FOREIGN KEY ([WorkcenterTypeId]) REFERENCES [dbo].[WorkCenterType] ([ID])
);

