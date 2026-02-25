CREATE PROCEDURE [dbo].[spImportPurchaseOrderData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100),
	@Since DateTime = NULL
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportPurchaseOrderData',
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

	
	-- DUPLICATE CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'DuplicatePurchaseOrderCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, PONumber 
					FROM PurchaseOrder 
					GROUP BY PONumber
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_PurchaseOrder_PONumber|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) no_of_recs, PONumber, Closed
						FROM PurchaseOrder 
						WHERE Closed<> 1
						GROUP BY PONumber, Closed
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateOpeneRecords_PurchaseOrder_PONumber|' +  CONVERT(varchar, @DupeActiveRecs);
				END
			END
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullPurchaseOrderCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PurchaseOrder WHERE PONumber IS NULL
			)
			SET @infoStr = 'TotalNullRecords_PurchaseOrder_UniquePONumber|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
				SET @infoStr = NULL;
			END
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



	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdatePurchaseOrderMaster'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE POM 
			SET 
				POM.[SourceTicketId] = PO.[TicketNum],
				POM.[StockMaterialId] = SM.[Id],
				POM.[Description] = PO.[Description],
				POM.[IsOpen] = PO.[Closed]^1,
				POM.[PurchaseOrderDate] = PO.[PODate],
				POM.[PromisedDeliveryDate] = PO.[DateReq],
				POM.[PurchaseOrderType] = PO.[POType],
				POM.[RequestedDeliveryDate] = PO.[RequestedDeliveryDate],
				POM.[Notes] = PO.[Notes],
				POM.[ModifiedOn] = GETUTCDATE(),
				POM.[ToolingId] = TI.Id,
				POM.[Supplier] =  PO.Supplier,
				POM.[TotalCost] = CAST(PO.TotalPO AS DECIMAL(18, 4)),
				POM.[CostMSI] = CAST(PO.CostMSI AS DECIMAL(18, 4)),
				POM.[MasterWidth] = PO.MasterWidth
			FROM PurchaseOrderMaster POM
			INNER JOIN PurchaseOrder PO ON POM.SourcePurchaseOrderNo = PO.PONumber
			LEFT JOIN StockMaterial SM ON PO.OrderStockNum = SM.SourceStockId
			LEFT JOIN ToolingInventory TI ON TI.SourceToolingId = PO.ToolNum
			where @Since IS NULL
			OR PO.UpdateTimeDateStamp >= @Since
			OR SM.ModifiedOn >= @Since
			OR TI.ModifiedOn >= @Since
			
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
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertPurchaseOrder'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO PurchaseOrderMaster ([Id], [SourcePurchaseOrderNo], [SourceTicketId], [Description], [PurchaseOrderDate], [PromisedDeliveryDate], [StockMaterialId], [PurchaseOrderType], [IsOpen], [RequestedDeliveryDate], [Notes], [CreatedOn], [ModifiedOn], [ToolingId], [Supplier], [TotalCost], [CostMSI], [MasterWidth])
			SELECT 
				NEWID() ID,
				PO.PONumber,
				PO.TicketNum, 
				PO.[Description],
				PO.PODate,
				PO.DateReq,
				SM.Id, 
				PO.POType,
				PO.Closed^1,
				PO.RequestedDeliveryDate,
				PO.Notes,
				GETUTCDATE(),
				GETUTCDATE(),
				TI.Id,
				PO.Supplier,
				CAST(PO.TotalPO AS DECIMAL(18, 4)),
				CAST(PO.CostMSI AS DECIMAL(18, 4)),
				PO.MasterWidth
			FROM 
				PurchaseOrder PO
				LEFT JOIN StockMaterial SM ON PO.OrderStockNum = SM.SourceStockId
				LEFT JOIN ToolingInventory TI ON TI.SourceToolingId = PO.ToolNum
			WHERE
				PO.PONumber NOT IN (SELECT SourcePurchaseOrderNo FROM PurchaseOrderMaster) 
				AND PO.PONumber IS NOT NULL		
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
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
