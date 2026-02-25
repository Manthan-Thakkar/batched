CREATE TABLE [dbo].[TicketAttributeFormula] (
    [ID]                VARCHAR (36)  NOT NULL,
    [FormulaType]       NVARCHAR (20)  NULL,
    [FormulaText]       NVARCHAR (512) NULL,
    [CreatedOn]         DATETIME      NULL,
    [ModifiedOn]        DATETIME      NULL,
    [TicketAttributeId] VARCHAR (36)  NULL,
    [RuleText]          VARCHAR(8000) NULL,
    CONSTRAINT [PK_TicketAttributeFormulaID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_TicketAttributeFormula_TicketAttributeID] FOREIGN KEY ([TicketAttributeId]) REFERENCES [dbo].[TicketAttribute] ([ID]),
    CONSTRAINT [AK_TicketAttributeFormula_TicketAttributeId] UNIQUE NONCLUSTERED ([TicketAttributeId] ASC)
);