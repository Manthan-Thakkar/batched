CREATE VIEW StockSubstitutes
AS

	Select sm.SourceStockId as StockNum, sm.SourceStockId as StockSubstitute
	From StockMaterial sm
	
	UNION ALL

	Select sm1.SourceStockId as StockNum, sm2.SourceStockId as StockSubstitute
	From StockMaterialSubstitute sms
	INNER JOIN StockMaterial sm1 on sms.StockMaterialId = sm1.Id
	INNER JOIN StockMaterial sm2 on sms.AlternateStockMaterialId = sm2.Id