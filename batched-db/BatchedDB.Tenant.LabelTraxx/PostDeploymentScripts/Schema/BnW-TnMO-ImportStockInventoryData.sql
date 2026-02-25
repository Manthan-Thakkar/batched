CREATE OR ALTER PROCEDURE [dbo].[spImportStockInventoryData]
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
		@spName					varchar(100) = 'spImportStockInventoryData',
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
		SET @blockName = 'DuplicateRollStockCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, PK_UUID 
					from RollStock 
					group by PK_UUID
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_RollStock_PK_UUID|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
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


	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullRollStockCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM RollStock where PK_UUID is null
			)
			SET @infoStr = 'TotalNullRecords_RollStock_PK_UUID|' +  CONVERT(varchar, @NullRecs);
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

	Declare @FacilityId varchar(36) = 
		(SELECT TOP 1 [batched].[dbo].[Facility].[ID]
			FROM [batched].[dbo].[Facility]
			WHERE [batched].[dbo].[Facility].[TenantId] = @TenantId
				AND [batched].[dbo].[Facility].[IsEnabled] = 1
			ORDER BY [batched].[dbo].[Facility].[CreatedOn]);


	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateStockInventory'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update SI
			set 
				Width = RS.Width,
				DimWidth = RS.Width,
				StockedOn = RS.StkDate,
				LastUsedOn = RS.DateRollUsed,
				StockUsed = RS.StkUsed,
				Location = RS.Location,
				ModifiedOn = GETUTCDATE(),
				Length = RS.FootLength,
				FacilityId = Case When RS.StockNum Like '%TN%' Then 'd75f0c05-eb5e-48c5-8e1d-96b017508279' Else @FacilityId End
			from StockInventory SI
			inner join RollStock RS on SI.SourceStockInventoryId = RS.PK_UUID and SI.Source = 'LabelTraxx'

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
		SET @blockName = 'InsertStockInventory'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into StockInventory (Id,StockMaterialId,Source,SourceStockInventoryId,Width,StockedOn,LastUsedOn,StockUsed,Location,SourceCreatedOn,CreatedOn,ModifiedOn, Length, FacilityId, DimWidth)
			select 
				NEWID() ID,
				SM.Id StockMaterialId,
				'LabelTraxx' Source,
				PK_UUID SourceStockInventoryId,
				RS.Width Width,
				StkDate StockedOn,
				DateRollUsed LastUsedOn,
				StkUsed StockUsed,
				RS.Location Location,
				RS.CreatedDate SourceCreatedOn,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				RS.FootLength,
				Case When RS.StockNum Like '%TN%' Then 'd75f0c05-eb5e-48c5-8e1d-96b017508279' Else @FacilityId End,
				RS.Width DimWidth
			from 
				RollStock RS
			inner join
				StockMaterial SM on RS.StockNum = SM.SourceStockId and SM.Source = 'LabelTraxx'
			LEFT JOIN
				StockInventory si on si.SourceStockInventoryId = RS.PK_UUID
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
END;