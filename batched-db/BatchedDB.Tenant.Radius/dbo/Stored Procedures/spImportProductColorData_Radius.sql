CREATE  PROCEDURE [dbo].[spImportProductColorData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportProductColorData_Radius',
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
					select COUNT(1) no_of_recs, TableRecId 
					from [item-coating] 
					group by TableRecId
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_ProductColor_TableRecId|' +  CONVERT(varchar, @duplicateRecs);
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
				SELECT COUNT(1) FROM [item-coating] where TableRecId is null
			)
			SET @infoStr = 'TotalNullRecords_ProductColor_TableRecId|' +  CONVERT(varchar, @NullRecs);
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
	
	--TRUNCATE TABLE BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'Truncate Product Color data'; SET @startTime = GETDATE();
		BEGIN TRY		
			
			TRUNCATE TABLE ProductColorInfo

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
		SET @blockName = 'UpdateProductColors'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update PCI 
			set 
				SourceColor = IC.[coat-mat-code],
				PCI.Unit = IC.[coat-seq],
				SourceInkType = IC.[type],
				ModifiedOn = GETUTCDATE(),
				SourceNotes = NULL,
				Anilox = NULL,
				SourceColorItemType = PMI.ItemTypeCode,
				ColorSide = IC.[coat-side]
			from ProductColorInfo PCI
			inner join [item-coating] IC on IC.TableRecId = PCI.SourceProductColorId and PCI.Source = 'Radius'
			inner join PM_Item PMI on PMI.CompNum = IC.kco and IC.[coat-mat-code]=PMI.ItemCode

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
			
			insert into ProductColorInfo (Id,ProductId,SourceProductColorId,Source,SourceColor,Unit,SourceInkType,CreatedOn,ModifiedOn,SourceNotes, Anilox, SourceColorItemType, ColorSide)
			select 
				NEWID() ID,
				PM.Id ProductId,
				IC.TableRecId SourceProductColorId,
				'Radius' Source,
				IC.[coat-mat-code] SourceColor,
				IC.[coat-seq],
				IC.type SourceInkType,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				NULL SourceNotes,
				NULL Anilox,
				PMI.ItemTypeCode,
				IC.[coat-side]
			from 
				[item-coating] IC
			inner join ProductMaster PM on IC.[item-code] = PM.SourceProductId and PM.Source = 'Radius'
			inner join PM_Item PMI on PMI.CompNum = IC.kco and IC.[coat-mat-code]=PMI.ItemCode
			where 
				IC.TableRecId not in (select SourceProductColorId from ProductColorInfo where Source = 'Radius') 
				
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