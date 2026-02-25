CREATE PROCEDURE [dbo].[spImportPurchaseOrderItem]
    -- Standard parameters for all stored procedures
    @TenantId       nvarchar(36),
    @CorelationId varchar(100),
    @Since DateTime = NULL
AS      
BEGIN

    SET NOCOUNT ON;

    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE 
        @spName                 varchar(100) = 'spImportPurchaseOrderItem',
        @__ErrorInfoLog         __ErrorInfoLog,
        @maxCustomMessageSize   int = 4000, --keep this exactly same as 4000
        @blockName              varchar(100),
        @warningStr             nvarchar(4000),
        @infoStr                nvarchar(4000),
        @errorStr               nvarchar(4000),
        @IsError                bit = 0,
        @startTime              datetime;
--  ======================================================================================================
    END

    BEGIN TRANSACTION;

    DROP TABLE IF EXISTS #PurchaseOrderLineTemp;
    DROP TABLE IF EXISTS #PurchaseOrderLine;
    
    DECLARE @MaxAllowedPromisedDeliveryDate DATETIME = DATEADD(DAY, 150, GETDATE());

    Declare @FacilityId varchar(36) = (SELECT TOP 1 [ID] FROM [dbo].[Facility] WITH(NOLOCK)
            WHERE [IsEnabled] = 1 ORDER BY [CreatedOnUTC]);


    Select pis.ID AS SourcePurchaseOrderItemId, pis.ExactWidths, po.PONumber, po.DateReq, po.OrderStockNum, pis.CutSize, pis.NumberofRollsInCut as NumberOfCuts,pis.CutNumber,pis.OrderedLinearFootage, pis.ReceivedLinearFootage, pis.UpdateTimeDateStamp
        Into #PurchaseOrderLineTemp
        From PurchaseOrder po
        Left Join 
            (Select CONCAT(ID, '_', Cut1) as ID,ExactWidths,PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT1' as CutNumber, CUT1 as CutSize, NUMCUT1 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT1 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT1 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT1*CUT1/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT1*CUT1/1000 as ReceivedMSI, UpdateTimeDateStamp
                From PO_Item_Stock
                Where CUT1 > 0 

            UNION ALL 

            Select CONCAT(ID, '_', Cut2) as ID, ExactWidths,PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT2' as CutNumber, CUT2 as CutSize, NUMCUT2 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT2 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT2 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT2*CUT2/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT2*CUT2/1000 as ReceivedMSI, UpdateTimeDateStamp
                From PO_Item_Stock
                Where CUT2 > 0

            UNION ALL 

            Select CONCAT(ID, '_', Cut3) as ID, ExactWidths,PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT3' as CutNumber, CUT3 as CutSize, NUMCUT3 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT3 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT3 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT3*CUT3/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT3*CUT3/1000 as ReceivedMSI, UpdateTimeDateStamp
                From PO_Item_Stock
                Where CUT3 > 0

            UNION ALL 

            Select CONCAT(ID, '_', Cut4) as ID, ExactWidths,PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT4' as CutNumber, CUT4 as CutSize, NUMCUT4 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT4 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT4 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT4*CUT4/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT4*CUT4/1000 as ReceivedMSI, UpdateTimeDateStamp
                From PO_Item_Stock
                Where CUT4 > 0

            UNION ALL 

            Select CONCAT(ID, '_', Cut5) as ID, ExactWidths,PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT5' as CutNumber, CUT5 as CutSize, NUMCUT5 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT5 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT5 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT5*CUT5/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT5*CUT5/1000 as ReceivedMSI, UpdateTimeDateStamp
                From PO_Item_Stock
                Where CUT5 > 0) pis 
            
            on po.PONumber = pis.PO_NUMBER

        Where po.POType='Stock'
        AND pis.ID IS NOT NULL

        SELECT PT.*, ISNULL(F.ID, @FacilityId) AS FacilityID
        INTO #PurchaseOrderLine
        FROM #PurchaseOrderLineTemp PT
            INNER JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON PT.[PONumber] = PO.[PONumber]
            LEFT JOIN [dbo].[Facility] F ON F.[SourceFacilityId] = PO.[Tag]             


    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'UpdatePurchaseOrderItem'; SET @startTime = GETDATE();
        BEGIN TRY       
        --  INSERT YOUR LOGIC BLOCK HERE
            
            UPDATE POI 
            SET 
                POI.[StockMaterialId] = SM.Id,
                POI.[Width] = PVPO.CutSize,
                POI.[PromisedDeliveryDate] = CASE WHEN PVPO.DateReq > @MaxAllowedPromisedDeliveryDate THEN NULL ELSE PVPO.DateReq END,
                POI.[OrderedQty] = PVPO.OrderedLinearFootage,
                POI.[ReceivedQty] = PVPO.ReceivedLinearFootage,
                POI.[OpenQty] = IIF(
                    (PVPO.OrderedLinearFootage - PVPO.ReceivedLinearFootage) > 0,
                    (PVPO.OrderedLinearFootage - PVPO.ReceivedLinearFootage),
                    0
                ),
                POI.[FacilityID] = PVPO.FacilityID,
                POI.[CutNumber] = PVPO.CutNumber,
                POI.[NumberOfCuts] = PVPO.NumberOfCuts,
                POI.[ExactWidths] = PVPO.ExactWidths,
                POI.[ModifiedOnUTC] = GETUTCDATE()
            FROM
                PurchaseOrderItem POI
                    INNER JOIN #PurchaseOrderLine PVPO ON POI.SourcePurchaseOrderItemId = PVPO.SourcePurchaseOrderItemId AND POI.CutNumber = PVPO.CutNumber
                    INNER JOIN PurchaseOrderMaster POM ON POI.PurchaseOrderId = POM.Id AND POM.SourcePurchaseOrderNo = PVPO.PONumber
                    INNER JOIN StockMaterial SM ON SM.SourceStockId = PVPO.OrderStockNum
            where @Since IS NULL
                OR PVPO.UpdateTimeDateStamp >= @Since
                OR POM.ModifiedOn >= @Since
                OR SM.ModifiedOn >= @Since

            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END


    IF @IsError = 0 
        BEGIN
        SET @blockName = 'InsertPurchaseOrderItem'; SET @startTime = GETDATE();

        BEGIN TRY
            ----Insert the records into PurchaseOrderItem
            INSERT INTO [dbo].[PurchaseOrderItem] ([Id], [FacilityId], [PurchaseOrderId],[ExactWidths],[SourcePurchaseOrderItemId], [StockMaterialId], [Width], [CutNumber], [NumberOfCuts],[PromisedDeliveryDate], [OrderedQty], [ReceivedQty], [OpenQty], [CreatedOnUTC], [ModifiedOnUTC])
                SELECT 
                    NEWID(),
                    PVPO.FacilityID,
                    POM.ID,
                    PVPO.ExactWidths,
                    PVPO.SourcePurchaseOrderItemId,
                    SM.Id,
                    PVPO.CutSize,
                    PVPO.CutNumber,
                    PVPO.NumberOfCuts,
                    CASE WHEN PVPO.DateReq > @MaxAllowedPromisedDeliveryDate THEN NULL ELSE PVPO.DateReq END,
                    PVPO.OrderedLinearFootage,
                    PVPO.ReceivedLinearFootage,
                    IIF(
                        (PVPO.OrderedLinearFootage - PVPO.ReceivedLinearFootage) > 0,
                        (PVPO.OrderedLinearFootage - PVPO.ReceivedLinearFootage),
                        0
                    ),
                    GETUTCDATE(),
                    GETUTCDATE()
                FROM
                 #PurchaseOrderLine PVPO
                        INNER JOIN PurchaseOrderMaster POM  ON POM.SourcePurchaseOrderNo = PVPO.PONumber
                        INNER JOIN StockMaterial SM ON SM.SourceStockId = PVPO.OrderStockNum
                WHERE
                    PVPO.SourcePurchaseOrderItemId NOT IN (SELECT SourcePurchaseOrderItemId FROM PurchaseOrderItem)
                    and PVPO.FacilityID IS NOT NULL

            SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; ROLLBACK;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END
    
    DROP TABLE IF EXISTS #PurchaseOrderLineTemp;
    DROP TABLE IF EXISTS #PurchaseOrderLine;

--      ========================[final commit log (do not change)]=======================================
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================
END