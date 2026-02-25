CREATE PROCEDURE [dbo].[spImportProductData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportProductData_Radius',
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
		SET @blockName = 'DuplicateProductCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, ItemCode 
					FROM PM_Item 
					GROUP BY ItemCode
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_Product_UniqueProdID|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) no_of_recs, ItemCode, InActive 
						FROM PM_Item
						WHERE InActive = 1
						GROUP BY ItemCode, InActive
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_Product_UniqueProdID|' +  CONVERT(varchar, @DupeActiveRecs);
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
		SET @blockName = 'NullProductCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PM_Item WHERE ItemCode IS NULL
			)
			SET @infoStr = 'TotalNullRecords_Product_UniqueProdID|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
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



	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateProducts'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE PM 
			SET 
				PM.ColorDesc = null, 
				PM.SourceProductGroup = P.ItemGroupCode,
				PM.ToolingNotes = null,
				PM.SlitOnRewind = 0,
				PM.NumColors = (SELECT COUNT(1) FROM [item-coating] WHERE [type] ='Ink' AND [item-code] = P.ItemCode),
				PM.NumFloods = (SELECT COUNT(1) FROM [item-coating] WHERE [type] IN ('Varnish', 'Coating') AND [item-code] = P.ItemCode),
				PM.ProductNum = P.ItemCode,
				PM.PlateId = null,
				PM.CustomField1 = P.CustItemRef2,
				PM.CriticalQuality = null,
				PM.ProdDescr = P.ItemDesc,
				PM.MaterialTrac = 0,
				PM.ColumnPerf = null,
				PM.RowPerf = null,
				PM.ProductGroupId = P.MinorProductGroup,
				PM.IsEnabled = (CASE WHEN P.InActive = 0 THEN 1 ELSE 0 END),
				SourceCreatedOn = P.createDate,
				SourceModifiedOn =CAST(CONVERT(datetime2, P.LastUpdatedDateTime) AS DATETIME),
				ModifiedOn = GETUTCDATE(),
				ProductPopup1 = null,
				ProductPopup2 = null,
				ProductPopup3 = null,
				ProductPopup4 = null,
				ProductPopup5 = null,
				ProductPopup6 = null,
				JobType = null,
				ProductType = P.ItemTypeCode,
				SheetPackType = null,
				CoreWidth = null,
				Notes = null,
				FinishedWidth = P.DimA,
				FinishedLength =  P.DimB,
				EquipNoColors = NULL,
				EquipNoFloods = NULL
			FROM ProductMaster PM
			INNER JOIN PM_Item P ON P.ItemCode = PM.SourceProductId and PM.Source = 'Radius'
			WHERE TenantId = @TenantId

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
		SET @blockName = 'InsertProducts'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
		;WITH SourceProductIds AS (SELECT SourceProductId FROM ProductMaster WHERE Source = 'Radius') 
			
			INSERT INTO ProductMaster (Id,TenantId,Source,SourceProductId,ColorDesc,SourceProductGroup,ToolingNotes,SlitOnRewind,NumColors,NumFloods,ProductNum,PlateId,CustomField1,CriticalQuality,ProdDescr,MaterialTrac,ColumnPerf,RowPerf,SourceCreatedOn,SourceModifiedOn,IsEnabled,CreatedOn,ModifiedOn,ProductGroupId, ProductPopup1, ProductPopup2, ProductPopup3, ProductPopup4, ProductPopup5, ProductPopup6, JobType, ProductType, SheetPackType, CoreWidth, Notes, FinishedWidth, FinishedLength, EquipNoColors, EquipNoFloods)
			SELECT
				NEWID() ID,
				@TenantId TenantId,
				'Radius' Source,
				P.ItemCode SourceProductId,
				null ColorDesc,
				P.ItemGroupCode SourceProductGroup,
				null ToolingNotes,
				0 SlitOnRewind,
				(SELECT COUNT(1) FROM [item-coating] WHERE [type] ='Ink' AND [item-code] = P.ItemCode) NumColors,
				(SELECT COUNT(1) FROM [item-coating] WHERE [type] IN ('Varnish', 'Coating') AND [item-code] = P.ItemCode) NumFloods,
				P.ItemCode ProductNum,
				null PlateId,
				P.CustItemRef2 CustomField1,
				null CriticalQuality,
				P.ItemDesc ProdDescr,
				0 MaterialTrac,
				null ColumnPerf,
				null RowPerf,
				P.createDate SourceCreatedOn,
				CAST(CONVERT(datetime2, P.LastUpdatedDateTime) AS DATETIME) SourceModifiedOn,
				(CASE WHEN P.InActive = 0 THEN 1 ELSE 0 END) IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				P.MinorProductGroup ProductGroupId,
				null ProductPopup1,
				null ProductPopup2,
				null ProductPopup3,
				null ProductPopup4,
				null ProductPopup5,
				null ProductPopup6,
				null JobType,
				P.ItemTypeCode ProductType,
				null SheetPackType,
				null CoreWidth,
				null Notes,
				P.DimA,			-- FinishedWidth
				P.DimB,			-- FinishedLength
				NULL,			-- EquipNoColors
				NULL			-- EquipNoFloods
			FROM 
				PM_Item P
			WHERE 
				P.ItemCode NOT IN (SELECT * FROM SourceProductIds)
				and P.ItemCode IS NOT NULL	
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (SELECT COUNT(1) FROM PM_Item WHERE ItemCode NOT IN (SELECT SourceProductId FROM ProductMaster WHERE Source = 'Radius') AND ItemCode IS NULL)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Product_UniqueProdID|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
				SET @infoStr = null;
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


