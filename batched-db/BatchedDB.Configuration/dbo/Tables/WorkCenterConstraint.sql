CREATE TABLE [dbo].[WorkCenterConstraint] (
    [Id]                VARCHAR (36)    NOT NULL,
    [WorkCenterTypeId]  VARCHAR (36)    NOT NULL,
    [Name]              NVARCHAR (64)   NOT NULL,
    [Description]       NVARCHAR (256)  NOT NULL,
    [TicketAttributeId] VARCHAR (36)    NULL,
    [Operator]          NVARCHAR (16)   NULL,
    [Value]             NVARCHAR (64)   NULL,
    [IsEnabled]         BIT             NOT NULL,
    [CreatedOn]         DATETIME        NOT NULL,
    [ModifiedOn]        DATETIME        NULL,
    [Scope]             [nvarchar](16)  NULL,
    CONSTRAINT [PK_WorkCenterConstraintID] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorkCenterConstraint_TicketAttributeId] FOREIGN KEY ([TicketAttributeId]) REFERENCES [dbo].[TicketAttribute] ([ID]),
    CONSTRAINT [FK_WorkCenterConstraint_WorkCenterTypeId] FOREIGN KEY ([WorkCenterTypeId]) REFERENCES [dbo].[WorkCenterType] ([ID])
);

