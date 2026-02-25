CREATE TABLE [dbo].[TicketTool]
(
	[Id]				VARCHAR(36)		NOT NULL,
	[TicketId]			VARCHAR(36)		NOT NULL	CONSTRAINT [FK_TicketStock_TicketId]			FOREIGN KEY REFERENCES TicketMaster(Id),
	[ToolingId]			VARCHAR(36)		NULL		CONSTRAINT [FK_TicketStock_ToolingInventoryId]	FOREIGN KEY REFERENCES ToolingInventory(Id),
	[Sequence]			SMALLINT		NOT NULL,
	[RequiredQuantity]	REAL			NOT NULL,
	[CreatedOn]			DATETIME		NOT NULL,
	[ModifiedOn]		DATETIME		NOT NULL,
	[Description]		NVARCHAR(4000)	NULL,
	[RoutingNumber]		TINYINT			NULL,
	CONSTRAINT [PK_TicketToolId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)