CREATE PROCEDURE [dbo].[spGetStockMaterialDimensions]
@facilities AS UDT_SINGLEFIELDFILTER readonly

AS
BEGIN
		SELECT 
			StockMaterialId, 
			SourceStockId, 
			Width,
			[Length],
			FacilityId,
			'tbl_stockMaterialDimension' AS __dataset_tableName   
		FROM StockDimensions 
		WHERE ((SELECT Count(1) FROM @facilities) = 0  OR FacilityId  IN (SELECT field FROM @facilities))
		ORDER BY FacilityId, SourceStockId, Width, [Length]
		
END