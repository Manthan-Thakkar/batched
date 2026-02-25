CREATE PROCEDURE [dbo].[spGetStockMaterialDimensionsByMaterialId]
	@facilities AS UDT_SINGLEFIELDFILTER readonly,
	@stockmaterialid AS VARCHAR(36) = NULL

AS
BEGIN
	DECLARE @temp_facilities UDT_SINGLEFIELDFILTER;
	INSERT INTO @temp_facilities SELECT * FROM @facilities;

	DECLARE @stockid varchar(36) = @stockmaterialid;

	WITH StockRecords AS (
		SELECT 
			StockMaterialId,
			SM.SourceStockId,
			Width,
			SI.DimLength AS [Length],
			SI.FacilityId
		FROM StockInventory SI WITH(NOLOCK) 
			INNER JOIN StockMaterial SM WITH(NOLOCK)  ON SM.Id = SI.StockMaterialId
		WHERE StockUsed=0 AND (@stockid IS NULL OR SM.Id = @stockid)
		GROUP BY StockMaterialId, Width, sm.SourceStockId, SI.DimLength, SI.FacilityId

		UNION
		
		SELECT 
			POI.StockMaterialId,
			SM.SourceStockId,
			POI.Width,
			POI.[Length] AS [Length],
			POI.FacilityId
		FROM StockMaterial SM WITH(NOLOCK)
			INNER JOIN PurchaseOrderItem POI WITH(NOLOCK) ON POI.StockMaterialId = SM.Id
    		INNER JOIN PurchaseOrderMaster PO WITH(NOLOCK) ON PO.Id = POI.PurchaseOrderId
		WHERE PO.IsOpen = 1 AND (@stockid IS NULL OR SM.Id = @stockid)
		GROUP BY POI.StockMaterialId,SM.SourceStockId,POI.Width, POI.[Length],POI.FacilityId
		
		UNION
		
		SELECT 
			TS.StockMaterialId,
			SM.SourceStockId,
			TS.Width,
			TS.[Length] AS [Length],
			SI.FacilityId
		FROM StockMaterial SM WITH(NOLOCK) 
			INNER JOIN TicketStock TS WITH(NOLOCK)  ON SM.Id = TS.StockMaterialId
			INNER JOIN StockInventory SI ON SI.StockMaterialId = TS.StockMaterialId
		WHERE (@stockid IS NULL OR SM.Id = @stockid)
		GROUP BY TS.StockMaterialId,SM.SourceStockId,TS.Width, TS.[Length], SI.FacilityId
		
		UNION 
		
		SELECT DISTINCT
			SIC.StockMaterialId,
			SM.SourceStockId,
			SID.DimWidth AS Width,
			SID.DimLength AS Length,
			SI.FacilityId
		FROM StockInventoryConfigDimensions SID
			INNER JOIN StockInventoryConfiguration SIC ON SID.StockInventoryConfigId = SIC.Id
			INNER JOIN StockMaterial SM ON SM.Id = SIC.StockMaterialId
			LEFT JOIN StockInventory SI ON SM.Id = SI.StockMaterialId
		WHERE SIC.StockMaterialId = @stockid

		UNION
		
		SELECT
			TSO.OverriddenStockMaterialId AS StockMaterialId,
			SM.SourceStockId,
			TSO.OverriddenWidth AS Width,
			TSO.OverriddenLength AS [Length],
			EM.FacilityId
		FROM TicketStockOverride TSO
			INNER JOIN TicketMaster TM ON TSO.TicketId = TM.ID
			INNER JOIN EquipmentMaster EM ON TM.Press = EM.[Name]
			INNER JOIN StockMaterial SM ON TSO.OverriddenStockMaterialId = SM.Id
		WHERE (@stockid IS NULL OR SM.Id = @stockid)
		) 

		SELECT 
			StockMaterialId, 
			SourceStockId, 
			Width,
			[Length],
			FacilityId,
			'tbl_stockMaterialDimension' AS __dataset_tableName   
		FROM StockRecords 
		WHERE ((SELECT Count(1) FROM @temp_facilities) = 0  OR FacilityId  IN (SELECT field FROM @temp_facilities))
		ORDER BY FacilityId, SourceStockId, Width, [Length]
		
END
