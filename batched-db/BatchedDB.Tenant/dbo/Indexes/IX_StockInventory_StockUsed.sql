CREATE NONCLUSTERED INDEX [IX_StockInventory_StockUsed]
	ON [dbo].[StockInventory]
	(StockUsed)
	INCLUDE (StockMaterialId,FacilityId,Width,DimLength,Length)