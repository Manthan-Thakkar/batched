CREATE TABLE [dbo].[StockInventoryConfiguration]
(
	[Id] VARCHAR(36) NOT NULL PRIMARY KEY,
	[StockMaterialId] VARCHAR(36) NOT NULL FOREIGN KEY REFERENCES StockMaterial(Id),
	[MinInventory] REAL NOT NULL,
	[MaxInventory] REAL NOT NULL,
	[ReorderQuantity] INT NOT NULL,
	[CreatedOnUTC] DATETIME NOT NULL,
	[ModifiedOnUTC] DATETIME NOT NULL,
);
