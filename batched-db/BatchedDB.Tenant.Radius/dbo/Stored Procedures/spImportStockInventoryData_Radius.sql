CREATE PROCEDURE [dbo].[spImportStockInventoryData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportStockInventoryData_Radius',
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
		SET @blockName = 'DuplicatePV_InventoryCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, InventoryRef 
					FROM PV_Inventory 
					GROUP BY InventoryRef
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_PV_Inventory_InventoryRef|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;
			END
		END TRY
		Begin CATCH
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
		SET @blockName = 'NullPV_InventoryCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PV_Inventory WHERE InventoryRef is null
			)
			SET @infoStr = 'TotalNullRecords_PV_Inventory_InventoryRef|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
				SET @infoStr = NULL;
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


	
	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateStockInventory'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE SI
			SET 
				Width = PVI.DimA,
				DimWidth = PVI.DimA,
				StockedOn = PVI.InventoryDate,  
				LastUsedOn = CONVERT(DATETIME, CONVERT(varchar(19), PVI.LastUpdatedDateTime, 120)),
				StockUsed = (CASE WHEN PVI.InvStatus = 9 THEN 1 ELSE 0 END),
				Location = CONCAT_WS('-', CAST(PVI.WhouseCode AS varchar),  CAST(PVI.RackCode AS varchar) , CAST(PVI.Rowcode AS varchar), CAST(PVI.BinCode as varchar)),
				ModifiedOn = GETUTCDATE(),
				Length = PVI.FreeQty + PVI.ReservedQty,
				FacilityId = F.ID,
				DimLength = PVI.DimB
			FROM StockInventory SI
			INNER JOIN PV_Inventory PVI ON SI.SourceStockInventoryId = PVI.InventoryRef and SI.Source = 'Radius'
			INNER JOIN Facility F on PVI.PlantCode = F.SourceFacilityId

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
		SET @blockName = 'InsertStockInventory'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO StockInventory (Id,StockMaterialId,Source,SourceStockInventoryId,Width,StockedOn,LastUsedOn,StockUsed,Location,SourceCreatedOn,CreatedOn,ModifiedOn, Length, FacilityId, DimLength, DimWidth)
			SELECT 
				NEWID() ID,
				SM.Id StockMaterialId,
				'Radius' Source,
				InventoryRef SourceStockInventoryId,
				PVI.DimA Width,
				PVI.InventoryDate StockedOn,
				CONVERT(DATETIME, CONVERT(varchar(19), PVI.LastUpdatedDateTime, 120)) LastUsedOn,
				(CASE WHEN PVI.InvStatus = 9 THEN 1 ELSE 0 END) StockUsed,
				CONCAT_WS('-', CAST(PVI.WhouseCode AS varchar),  CAST(PVI.RackCode AS varchar) , CAST(PVI.Rowcode AS varchar), CAST(PVI.BinCode as varchar)) Location,
				PVI.InventoryDate SourceCreatedOn,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				FreeQty + ReservedQty Length,
				F.ID FacilityId,
				PVI.DimB DimLength,
				PVI.DimA DimWidth
			FROM 
				PV_Inventory PVI
			INNER JOIN
				StockMaterial SM ON PVI.ItemCode = SM.SourceStockId and SM.Source = 'Radius'
			LEFT JOIN
				StockInventory si on si.SourceStockInventoryId = PVI.InventoryRef
			INNER JOIN Facility F on PVI.PlantCode = F.SourceFacilityId 
			WHERE
				si.SourceStockInventoryId is null
				
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

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
	-- BLOCK END
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END