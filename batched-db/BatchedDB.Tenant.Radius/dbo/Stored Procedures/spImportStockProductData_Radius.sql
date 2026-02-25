CREATE PROCEDURE [dbo].[spImportStockProductData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportStockProductData_Radius',
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
		SET @blockName = 'DuplicateStockProductCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, ItemCode 
					FROM PM_Item
					WHERE ReqGroupCode LIKE '%-FG'
					GROUP BY ItemCode 
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_StockProduct_ID|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) no_of_recs, ItemCode, InActive 
						FROM PM_Item
						WHERE InActive = 0 AND ReqGroupCode LIKE '%-FG' 
						GROUP BY ItemCode, InActive
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_StockProduct_ID|' +  CONVERT(varchar, @DupeActiveRecs);
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
		SET @blockName = 'NullStockProductCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PM_Item where ItemCode IS NULL
			)
			SET @infoStr = 'TotalNullRecords_StockProduct_ID|' +  CONVERT(varchar, @NullRecs);
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


	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateStockProduct'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE SI
			SET 
				ProductId = PM.ID,
				IsAvailable = 1,
				InventoryQuantity = PMIT.InventoryQty,
				AvailableQuantity = PMIT.FreeQty,
				Location = SI.Location,
				IsEnabled = CASE WHEN PMIT.InActive IN (0, 50) THEN 1 ELSE 0 END,
				SourceCreatedOn = PMIT.createDate,
				SourceModifiedOn = CAST(CONVERT(datetime2, PMIT.LastUpdatedDateTime) AS DATETIME),
				ModifiedOn = GETUTCDATE()
			FROM StockProductMaster SI
			INNER JOIN (
				SELECT PMI.ItemCode, PMI.createDate, PMI.LastUpdatedDateTime, PMI.InActive, SUM(PVI.InventoryQty) AS InventoryQty, SUM(PVI.FreeQty) AS FreeQty
				FROM PM_Item PMI WITH (NOLOCK)
				INNER JOIN PV_Inventory PVI WITH (NOLOCK) ON PMI.ItemCode = PVI.ItemCode
				WHERE PMI.ReqGroupCode LIKE '%-FG'
				GROUP BY PMI.ItemCode, PMI.createDate, PMI.LastUpdatedDateTime, PMI.InActive
			) PMIT 
			ON SI.SourceStockProductId =  PMIT.ItemCode and SI.Source = 'Radius'
			INNER JOIN ProductMaster PM WITH (NOLOCK) ON SI.ProductId = PM.ID

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
		SET @blockName = 'InsertStockProduct'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO StockProductMaster (Id,TenantId,Source,SourceStockProductId,ProductId,IsAvailable,InventoryQuantity,AvailableQuantity,Location,SourceCreatedOn,SourceModifiedOn,IsEnabled,CreatedOn,ModifiedOn)
			SELECT 
				NEWID() ID,
				@TenantId TenantId,
				'Radius' Source,
				PMI.ItemCode SourceStockProductId,
				PM.ID ProductId,
				1 IsAvailable,
				SUM(PVI.InventoryQty) InventoryQuantity,
				SUM(PVI.FreeQty) AvailableQuantity,
				null Location,
				PMI.createDate SourceCreatedOn,
				CAST(CONVERT(datetime2, PMI.LastUpdatedDateTime) AS DATETIME) SourceModifiedOn,
				CASE WHEN PMI.InActive IN (0, 50) THEN 1 ELSE 0 END IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn
			FROM 
				PM_Item PMI WITH (NOLOCK)
			INNER JOIN
				ProductMaster PM WITH (NOLOCK) ON PMI.ItemCode = PM.SourceProductId and PM.Source = 'Radius'
			INNER JOIN 
				PV_Inventory PVI WITH (NOLOCK) ON PMI.ItemCode = PVI.ItemCode AND PMI.ReqGroupCode LIKE '%-FG'
			WHERE 
				PMI.ItemCode NOT IN (SELECT SourceStockProductId FROM StockProductMaster WHERE Source = 'Radius') 
				
			GROUP BY PMI.ItemCode, PM.ID, PMI.createDate, PMI.LastUpdatedDateTime, PMI.InActive
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

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