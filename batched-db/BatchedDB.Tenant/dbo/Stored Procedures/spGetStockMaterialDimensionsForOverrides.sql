CREATE PROCEDURE [dbo].[spGetStockMaterialDimensionsForOverrides]
	@facilities AS UDT_SINGLEFIELDFILTER READONLY,
	@stockMaterialId AS VARCHAR(36)

AS
BEGIN
	DROP TABLE IF EXISTS #GroupedTicketStockAvailabilities;
    DROP TABLE IF EXISTS #GroupedStockInventory;
    DROP TABLE IF EXISTS #GroupedPurchaseOrderItems;


    SELECT ActualStockMaterialId, ActualWidth, ActualLength, SUM(RequiredQuantity) AS RequiredQuantity
    INTO #GroupedTicketStockAvailabilities
    FROM TicketStockAvailability
    WHERE ((SELECT Count(1) FROM @facilities) = 0 OR FacilityId IN (SELECT field FROM @facilities))
    GROUP BY ActualStockMaterialId, ActualWidth, ActualLength;


    SELECT StockMaterialId, DimWidth, DimLength, SUM([Length]) AS TotalQuantity
    INTO #GroupedStockInventory
    FROM StockInventory
    WHERE ((SELECT Count(1) FROM @facilities) = 0 OR FacilityId IN (SELECT field FROM @facilities))
        AND StockUsed = 0
    GROUP BY StockMaterialId, DimWidth, DimLength;


    SELECT POI.StockMaterialId, POI.Width, POI.[Length], SUM(POI.OpenQty) AS OpenQty
    INTO #GroupedPurchaseOrderItems
    FROM PurchaseOrderItem POI
        INNER JOIN PurchaseOrderMaster POM ON POI.PurchaseOrderId = POM.Id
    WHERE POM.IsOpen = 1 AND
        ((SELECT Count(1) FROM @facilities) = 0 OR FacilityId IN (SELECT field FROM @facilities))
    GROUP BY POI.StockMaterialId, POI.Width, POI.[Length];


	SELECT
        SDV.StockMaterialId,
        SDV.SourceStockId,
        SDV.Width,
        SDV.[Length],
        SDV.FacilityId,
        (ISNULL(GSI.TotalQuantity, 0) - ISNULL(GTS.RequiredQuantity, 0)) AS AvailableQuantity,
        CASE 
            WHEN (ISNULL(GSI.TotalQuantity, 0) - ISNULL(GTS.RequiredQuantity, 0)) >= 0 THEN 'In'
            WHEN (ISNULL(GSI.TotalQuantity, 0) - ISNULL(GTS.RequiredQuantity, 0)) < 0 AND GPOI.OpenQty > 0 THEN 'Ordered'
            ELSE 'Out'
        END AS StockStatus,
        CASE
            WHEN SMS.StockMaterialId IS NOT NULL THEN 1
            ELSE 0
        END AS IsSubstitute,
        CASE
            WHEN SMS.StockMaterialId IS NOT NULL THEN SMS.Sequence
            ELSE NULL
        END AS [Sequence],
        'tbl_stockMaterialDimensionsOverride' AS __dataset_tableName
    
    FROM StockDimensions SDV

        LEFT JOIN #GroupedStockInventory GSI ON
            SDV.StockMaterialId = GSI.StockMaterialId AND 
            SDV.Width = GSI.DimWidth AND 
            (SDV.[Length] IS NULL OR GSI.DimLength IS NULL OR SDV.[Length] = GSI.DimLength)
        
        LEFT JOIN #GroupedTicketStockAvailabilities GTS ON
            SDV.StockMaterialId = GTS.ActualStockMaterialId AND 
            SDV.Width = GTS.ActualWidth AND 
            (SDV.[Length] IS NULL OR GTS.ActualLength IS NULL OR SDV.[Length] = GTS.ActualLength)
        
        LEFT JOIN #GroupedPurchaseOrderItems GPOI ON 
            SDV.StockMaterialId = GPOI.StockMaterialId AND 
            SDV.Width = GPOI.Width AND 
            (SDV.[Length] IS NULL OR GPOI.[Length] IS NULL OR SDV.[Length] = GPOI.[Length])
            
        LEFT JOIN StockMaterialSubstitute SMS ON 
            SDV.StockMaterialId = SMS.AlternateStockMaterialId AND
            SMS.StockMaterialId = @stockMaterialId
    
    WHERE ((SELECT Count(1) FROM @facilities) = 0 OR SDV.FacilityId  IN (SELECT field FROM @facilities))
    ORDER BY SDV.FacilityId, SDV.SourceStockId, SDV.Width, SDV.[Length];
	
    
    DROP TABLE IF EXISTS #GroupedTicketStockAvailabilities;
    DROP TABLE IF EXISTS #GroupedStockInventory;
    DROP TABLE IF EXISTS #GroupedPurchaseOrderItems;
END