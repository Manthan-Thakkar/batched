CREATE TABLE [dbo].[StockInventoryConfigFacilities]
(
	[Id] VARCHAR(36) NOT NULL PRIMARY KEY,
	[StockInventoryConfigId] VARCHAR(36) NOT NULL FOREIGN KEY REFERENCES StockInventoryConfiguration(Id),
	[FacilityId] VARCHAR(36) NOT NULL FOREIGN KEY REFERENCES Facility(Id),
	[CreatedOnUTC] DATETIME NOT NULL,
	[ModifiedOnUTC] DATETIME NOT NULL
);
