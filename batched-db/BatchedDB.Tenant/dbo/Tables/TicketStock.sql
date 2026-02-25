CREATE TABLE [dbo].[TicketStock]
(
	Id					VARCHAR(36)		NOT NULL,
	TicketId			VARCHAR(36)		NOT NULL CONSTRAINT [FK_TicketStock_TicketMasterId] FOREIGN KEY REFERENCES TicketMaster(Id),
	StockMaterialId		VARCHAR(36)		NOT NULL CONSTRAINT [FK_TicketStock_StockMaterialId] FOREIGN KEY REFERENCES StockMaterial(Id),
	[Sequence]			SMALLINT		NOT NULL,
	StockType			NVARCHAR(255)	NOT NULL,
	Width				REAL			NULL,
	[Length]			REAL			NULL,
	Notes				NVARCHAR(4000)	NULL,
	CreatedOn			DATETIME		NOT NULL,
	ModifiedOn			DATETIME		NOT NULL,
	RequiredQuantity	REAL			NULL,
	TaskName			VARCHAR(36)		NOT NULL,	
	[RoutingNo]			TINYINT			NULL, 
    CONSTRAINT [PK_TicketStockId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);