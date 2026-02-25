CREATE PROCEDURE [dbo].[spImportPurchaseOrderData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportPurchaseOrderData_Radius',
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
		SET @blockName = 'DuplicatePV_POrderCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, CONCAT(CompNum, '_', POrderNum) as POrderNum
					FROM PV_POrder 
					GROUP BY CONCAT(CompNum, '_', POrderNum)
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_PV_POrder_POrderNum|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) no_of_recs, CONCAT(CompNum, '_', POrderNum) as POrderNum, POrderStat
						FROM PV_POrder 
						WHERE POrderStat NOT IN (8, 9)
						GROUP BY CONCAT(CompNum, '_', POrderNum), POrderStat
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateOpeneRecords_PV_POrder_POrderNum|' +  CONVERT(varchar, @DupeActiveRecs);
				END
			END
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

	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullPV_POrderCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PV_POrder where POrderNum IS NULL
			)
			SET @infoStr = 'TotalNullRecords_PV_POrder_POrderNum|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
				SET @infoStr = NULL;
			END
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



	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdatePurchaseOrderMaster'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE POM 
			SET 
				POM.[Description] = PO.POrderText,
				POM.[IsOpen] = CASE WHEN PO.POrderStat NOT IN (8, 9) THEN 1 ELSE 0 END,
				POM.[PurchaseOrderDate] = PO.POrderDate,
				POM.[PurchaseOrderType] = NULL,
				POM.[RequestedDeliveryDate] = PO.ReqDate,
				POM.[ModifiedOn] = GETUTCDATE(),
				POM.[Supplier] = PVS.SUPPNAME
			FROM PurchaseOrderMaster POM
			INNER JOIN PV_POrder PO ON POM.SourcePurchaseOrderNo = CONCAT(PO.CompNum, '_', PO.POrderNum)
			LEFT JOIN PV_Supplier PVS On PO.Suppcode = PVS.SuppCode

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
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertPurchaseOrder'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO PurchaseOrderMaster ([Id], [SourcePurchaseOrderNo], [SourceTicketId], [Description], [PurchaseOrderDate], [PromisedDeliveryDate], [StockMaterialId], [PurchaseOrderType], [IsOpen], [RequestedDeliveryDate], [Notes], [CreatedOn], [ModifiedOn],[Supplier])
			SELECT 
				NEWID() ID,
				CONCAT(PO.CompNum, '_', PO.POrderNum),
				NULL,
				PO.POrderText,
				PO.POrderDate,
				NULL, --SM_POL.ConfDelivDate,
				NULL, --SM_POL.Id,
				NULL,
				CASE WHEN PO.POrderStat NOT IN (8, 9) THEN 1 ELSE 0 END,
				PO.ReqDate,
				PO.PORDERTEXT,--SM_POL.POrderLineText,
				GETUTCDATE(),
				GETUTCDATE(),
				PVS.SUPPNAME -- supplier
			FROM 
				PV_POrder PO
				JOIN PV_Supplier PVS ON PVS.SuppCode =  PO.Suppcode
			WHERE
				CONCAT(PO.CompNum, '_', PO.POrderNum) NOT IN (SELECT SourcePurchaseOrderNo FROM PurchaseOrderMaster) 
				AND PO.POrderNum IS NOT NULL	
				
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