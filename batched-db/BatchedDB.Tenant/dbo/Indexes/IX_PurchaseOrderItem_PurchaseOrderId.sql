CREATE NONCLUSTERED INDEX [IX_PurchaseOrderItem_PurchaseOrderId]
	ON [dbo].[PurchaseOrderItem]
	(PurchaseOrderId)
	INCLUDE (StockMaterialId,Width,Length,OpenQty,FacilityId)