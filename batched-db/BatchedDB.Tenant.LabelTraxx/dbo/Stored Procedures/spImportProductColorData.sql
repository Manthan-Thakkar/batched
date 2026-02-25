CREATE  PROCEDURE [dbo].[spImportProductColorData]
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
		@spName					varchar(100) = 'spImportProductColorData',
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
		SET @blockName = 'DuplicateProductColorCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, PK_UUID 
					from ProductColor 
					group by PK_UUID
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_ProductColor_PK_UUID|' +  CONVERT(varchar, @duplicateRecs);
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
		SET @blockName = 'NullProductColorCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM ProductColor where PK_UUID is null
			)
			SET @infoStr = 'TotalNullRecords_ProductColor_PK_UUID|' +  CONVERT(varchar, @NullRecs);
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
	

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateProductColors'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update PCI 
			set 
				SourceColor = PC.COLOR,
				PCI.Unit = PC.Unit,
				SourceInkType = PC.INK_TYPE,
				ModifiedOn = GETUTCDATE(),
				SourceNotes = PC.Notes,
				Anilox = PC.ANILOX,
				SourceColorItemType = null
			from ProductColorInfo PCI
			inner join ProductColor PC on PC.PK_UUID = PCI.SourceProductColorId and PCI.Source = 'LabelTraxx'
			where @Since IS NULL OR PC.UpdateTimeDateStamp >= @Since

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
		SET @blockName = 'InsertProductColors'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into ProductColorInfo (Id,ProductId,SourceProductColorId,Source,SourceColor,Unit,SourceInkType,CreatedOn,ModifiedOn,SourceNotes, Anilox,SourceColorItemType)
			select 
				NEWID() ID,
				PM.Id ProductId,
				PK_UUID SourceProductColorId,
				'LabelTraxx' Source,
				PC.COLOR SourceColor,
				PC.Unit,
				PC.INK_TYPE SourceInkType,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				PC.Notes SourceNotes,
				PC.ANILOX Anilox,
				null--SourceColorItemType
			from 
				ProductColor PC
			inner join
				ProductMaster PM on PC.UNIQUEPRODID = PM.SourceProductId and PM.Source = 'LabelTraxx'
			where 
				PK_UUID not in (select SourceProductColorId from ProductColorInfo where Source = 'LabelTraxx') 
				
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