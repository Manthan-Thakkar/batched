CREATE PROCEDURE [dbo].[spImportPurchaseOrderItem_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportPurchaseOrderItem_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly same as 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END

	BEGIN TRANSACTION;

	DECLARE @MaxAllowedPromisedDeliveryDate DATETIME = DATEADD(DAY, 150, GETDATE());
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdatePurchaseOrderItem'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE POI 
			SET
				POI.[FacilityId] = F.ID,
				POI.[SourcePurchaseOrderItemId] = CONCAT(PVPO.CompNum, '_', PVPO.PlantCode, '_', PVPO.POrderNum, '_', PVPO.POrderLineNum),
				POI.[StockMaterialId] = SM.Id,
				POI.[Width] = PVPO.DimA,
				POI.[Length] = PVPO.DimB,
				POI.[PromisedDeliveryDate] = CASE When PVPO.ConfDelivDate > @MaxAllowedPromisedDeliveryDate Then NULL Else PVPO.ConfDelivDate End,
				POI.[OrderedQty] = PVPO.OrderedQty,
				POI.[ReceivedQty] = PVPO.ReceivedQty,
				POI.[OpenQty] = PVPO.OutstandingQty,
				POI.[ModifiedOnUTC] = GETUTCDATE()				
			FROM 
				PurchaseOrderItem POI
					INNER JOIN PV_POrderLine PVPO ON POI.SourcePurchaseOrderItemId = CONCAT(PVPO.CompNum, '_', PVPO.PlantCode, '_', PVPO.POrderNum, '_', PVPO.POrderLineNum)
					INNER JOIN PurchaseOrderMaster POM ON POI.PurchaseOrderId = POM.Id AND POM.SourcePurchaseOrderNo = CONCAT(PVPO.CompNum, '_', PVPO.POrderNum)
					INNER JOIN StockMaterial SM ON SM.SourceStockId = PVPO.ItemCode
					INNER JOIN Facility F on PVPO.PlantCode = F.SourceFacilityId

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertPurchaseOrderItem'; SET @startTime = GETDATE();

		BEGIN TRY
			----Insert the records into PurchaseOrderItem
			INSERT INTO [dbo].[PurchaseOrderItem] ([Id], [FacilityId], [PurchaseOrderId], [SourcePurchaseOrderItemId], [StockMaterialId], [Width], [PromisedDeliveryDate], [OrderedQty], [ReceivedQty], [OpenQty], [CreatedOnUTC], [ModifiedOnUTC])
				SELECT 
					NEWID(),
					F.ID,
					POM.ID,
					CONCAT(PVPO.CompNum, '_', PVPO.PlantCode, '_', PVPO.POrderNum, '_', PVPO.POrderLineNum),
					SM.Id,
					PVPO.DimA,
					CASE When PVPO.ConfDelivDate > @MaxAllowedPromisedDeliveryDate Then NULL Else PVPO.ConfDelivDate End,
					PVPO.OrderedQty,
					PVPO.ReceivedQty,
					PVPO.OutstandingQty,
					GETUTCDATE(),
					GETUTCDATE()
				FROM
				 PV_POrderLine PVPO
					INNER JOIN PurchaseOrderMaster POM  ON POM.SourcePurchaseOrderNo = CONCAT(PVPO.CompNum, '_', PVPO.POrderNum)
					INNER JOIN StockMaterial SM ON SM.SourceStockId = PVPO.ItemCode
					INNER JOIN Facility F on PVPO.PlantCode = F.SourceFacilityId
				WHERE
					CONCAT(PVPO.CompNum, '_', PVPO.PlantCode, '_', PVPO.POrderNum, '_', PVPO.POrderLineNum) NOT IN (SELECT SourcePurchaseOrderItemId FROM PurchaseOrderItem)
					--AND POM.StockMaterialId IS NOT NULL

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
					   		
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END