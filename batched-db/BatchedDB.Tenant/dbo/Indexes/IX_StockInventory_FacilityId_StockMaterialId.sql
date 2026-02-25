CREATE NONCLUSTERED INDEX [IX_StockInventory_FacilityId_StockMaterialId] ON [StockInventory]
(
	[StockMaterialId] ASC,
	[FacilityId] ASC,
	[StockUsed] ASC
)
INCLUDE([Width],[Length])   