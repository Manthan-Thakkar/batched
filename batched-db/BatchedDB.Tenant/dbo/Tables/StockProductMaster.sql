CREATE TABLE [dbo].[StockProductMaster]
(
	Id						varchar(36),	
	TenantId				varchar(36) NOT NULL,
	Source					varchar(36) NOT NULL,
	SourceStockProductId	nvarchar(4000),
	ProductId				varchar(36) NULL CONSTRAINT [FK_StockProductMaster_ProductId] FOREIGN KEY REFERENCES ProductMaster(Id),
	IsAvailable				bit NOT NULL,
	InventoryQuantity		int NOT NULL,
	AvailableQuantity		int NOT NULL,
	BackOrderedQuantity		int NOT NULL DEFAULT 0,
	Location				nvarchar(4000),
	SourceCreatedOn			Datetime NULL,
	SourceModifiedOn		Datetime NULL,
	IsEnabled				bit NOT NULL,
	CreatedOn				Datetime NOT NULL,
	ModifiedOn				Datetime NOT NULL,
    CONSTRAINT [PK_StockProductMasterID] PRIMARY KEY NONCLUSTERED ([Id])
)
