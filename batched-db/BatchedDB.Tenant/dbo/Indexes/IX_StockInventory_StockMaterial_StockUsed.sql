CREATE NONCLUSTERED INDEX [IX_StockInventory_StockMaterial_StockUsed]
	ON [dbo].[StockInventory]
	(StockMaterialId,StockUsed)
	INCLUDE (FacilityId,Width,DimWidth,DimLength,Length)