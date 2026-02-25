CREATE PROCEDURE spImportStockProductData
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
		@spName					varchar(100) = 'spImportStockProductData',
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
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, ID 
					from StockProduct 
					group by ID 
					having COUNT(1) > 1
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
						select COUNT(1) no_of_recs, ID, Inactive 
						from StockProduct
						where Inactive = 0
						group by ID, Inactive
						having COUNT(1) > 1
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
		Begin TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM StockProduct where ID is null
			)
			SET @infoStr = 'TotalNullRecords_StockProduct_ID|' +  CONVERT(varchar, @NullRecs);
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
		SET @blockName = 'UpdateStockProduct'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update SI
			set 
				ProductId = PM.ID,
				IsAvailable = CASE WHEN SP.AVAILABLE > 0 THEN 1 ELSE 0 END,
				InventoryQuantity = SP.PHYSICALINV,
				AvailableQuantity = SP.AVAILABLE,
				BackOrderedQuantity = SP.BACKORDERED,
				Location = SI.Location,
				IsEnabled = CASE WHEN SP.INACTIVE = 1 THEN 0 ELSE 1 END,
				SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
				SourceModifiedOn = CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
				ModifiedOn = GETUTCDATE()
			from StockProductMaster SI
			inner join StockProduct SP on SI.SourceStockProductId = SP.ID and SI.Source = 'LabelTraxx'
			left join ProductMaster PM on SI.ProductId = PM.ID
			where @Since IS NULL
			OR SP.UpdateTimeDateStamp >= @Since

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
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertStockProduct'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into StockProductMaster (Id,TenantId,Source,SourceStockProductId,ProductId,IsAvailable,InventoryQuantity,AvailableQuantity,BackOrderedQuantity,Location,SourceCreatedOn,SourceModifiedOn,IsEnabled,CreatedOn,ModifiedOn)
			select 
				NEWID() ID,
				@TenantId TenantId,
				'LabelTraxx' Source,
				SP.ID SourceStockProductId,
				PM.ID ProductId,
				CASE WHEN SP.AVAILABLE > 0 THEN 1 ELSE 0 END IsAvailable,
				SP.PHYSICALINV InventoryQuantity,
				SP.AVAILABLE AvailableQuantity,
				SP.BACKORDERED BackOrderedQuantity,
				Location Location,
				CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
				CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
				cast(0 as bit) IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn
			from 
				StockProduct SP
			left join
				ProductMaster PM on SP.PRODUCT_UNIQUEPRODID = PM.SourceProductId and PM.Source = 'LabelTraxx'
			where 
				SP.ID not in (select SourceStockProductId from StockProductMaster where Source = 'LabelTraxx') 
				
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
