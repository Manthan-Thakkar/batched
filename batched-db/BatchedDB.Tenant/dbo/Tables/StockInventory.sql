CREATE TABLE StockInventory
(
	Id						varchar(36)		NOT NULL,	
	StockMaterialId			varchar(36)		NOT NULL	CONSTRAINT [FK_StockInventory_StockMaterialId] FOREIGN KEY REFERENCES StockMaterial(Id),
	Source					varchar(36)		NOT NULL,
	SourceStockInventoryId	nvarchar(4000)	NULL,
	Width					nvarchar(4000)	NULL,
	DimWidth				real			NULL,
	DimLength				real			NULL,
	StockedOn				Datetime		NULL,
	LastUsedOn				Datetime		NULL,
	StockUsed				bit				NOT NULL,
	Location				nvarchar(4000)	NULL,
	SourceCreatedOn			Datetime		NULL,
	CreatedOn				Datetime		NOT NULL,
	ModifiedOn				Datetime		NOT NULL,
	Length					INT				NULL,
	FacilityId				VARCHAR (36)	NULL,
    CONSTRAINT [PK_StockInventoryID] PRIMARY KEY NONCLUSTERED ([Id])
);
