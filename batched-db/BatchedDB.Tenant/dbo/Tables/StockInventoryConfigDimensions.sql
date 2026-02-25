CREATE TABLE [dbo].[StockInventoryConfigDimensions]
(
	[Id] VARCHAR(36) NOT NULL PRIMARY KEY,
	[StockInventoryConfigId] VARCHAR(36) NOT NULL FOREIGN KEY REFERENCES StockInventoryConfiguration(Id),
	[DimWidth] REAL NOT NULL,
	[DimLength] REAL NULL,
	[CreatedOnUTC] DATETIME NOT NULL,
	[ModifiedOnUTC] DATETIME NOT NULL
);
