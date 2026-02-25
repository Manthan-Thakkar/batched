CREATE VIEW StockDimensions
AS
		SELECT 
			SI.StockMaterialId,
			SM.SourceStockId,
			SI.Width,
			SI.DimLength AS [Length],
			SI.FacilityId
		FROM StockInventory SI WITH(NOLOCK) 
			INNER JOIN StockMaterial SM WITH(NOLOCK) ON SM.Id = SI.StockMaterialId
		WHERE StockUsed = 0
		GROUP BY StockMaterialId, Width, SM.SourceStockId, SI.DimLength, SI.FacilityId
		HAVING SUM([Length]) > 0
		
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
		WHERE PO.IsOpen = 1
		GROUP BY POI.StockMaterialId,SM.SourceStockId,POI.Width, POI.[Length], POI.FacilityId
		HAVING SUM(POI.OpenQty) > 0
		
		UNION
		
		SELECT 
			TS.StockMaterialId,
			SM.SourceStockId,
			TS.Width,
			TS.[Length] AS [Length],
			SI.FacilityId
		FROM StockMaterial SM WITH(NOLOCK) 
			INNER JOIN TicketStock TS WITH(NOLOCK) ON SM.Id = TS.StockMaterialId
			INNER JOIN StockInventory SI ON SI.StockMaterialId = TS.StockMaterialId
		GROUP BY TS.StockMaterialId, SM.SourceStockId, TS.Width, TS.[Length], SI.FacilityId

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