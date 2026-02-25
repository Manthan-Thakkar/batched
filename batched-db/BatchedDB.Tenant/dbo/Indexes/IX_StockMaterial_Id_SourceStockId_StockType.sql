CREATE NONCLUSTERED INDEX [IX_StockMaterial_Id_SourceStockId_StockType]
	ON [dbo].[StockMaterial]
	(Id) 
	INCLUDE ([SourceStockId],[Type])