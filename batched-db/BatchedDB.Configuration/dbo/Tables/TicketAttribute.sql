CREATE TABLE [dbo].[TicketAttribute] (
    [ID]                VARCHAR  (36)    NOT NULL,
    [Name]              NVARCHAR (64)   NULL,
    [Description]       NVARCHAR (256)  NULL,
    [DataType]          NVARCHAR (16)   NULL,
    [UnitOfMeasurement] NVARCHAR (16)   NULL,
    [Scope]             NVARCHAR (16)   NULL,
    [CreatedOn]         DATETIME        NULL,
    [ModifiedOn]        DATETIME        NULL,
    [IsEnabled]         BIT             NOT NULL,
    [RequiredForMaterialPlanning] BIT   NOT NULL,
    CONSTRAINT [PK_TicketAttributeID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);

