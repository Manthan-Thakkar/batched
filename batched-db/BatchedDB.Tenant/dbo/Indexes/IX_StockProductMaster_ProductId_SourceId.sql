CREATE INDEX IX_StockProductMaster_ProductId_SourceId 
ON dbo.StockProductMaster (ProductId, SourceStockProductId);