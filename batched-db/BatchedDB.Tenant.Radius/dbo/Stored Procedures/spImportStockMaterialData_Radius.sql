CREATE PROCEDURE [dbo].[spImportStockMaterialData_Radius]
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportStockMaterialData_Radius',
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
	
	
	SELECT SM.ID StockMaterialId, PMI.ItemCode StockId, PMI.Caliper LinerCaliper 
	INTO #MatchingStocks
	FROM StockMaterial SM
	INNER JOIN PM_Item PMI on PMI.ItemCode = SM.SourceStockId AND PMI.ItemCode IS NOT NULL
	where SM.Source='Radius' AND SM.TenantId = @TenantId;

	

	-- DUPLICATE CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'DuplicateStockCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) AS no_of_recs, ItemCode
					FROM PM_Item
					GROUP BY ItemCode 
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_PM_Item_ItemCode|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) AS no_of_recs, ItemCode, Inactive 
						FROM PM_Item
						WHERE Inactive = 0
						GROUP BY ItemCode, Inactive
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_PM_Item_ItemCode|' +  CONVERT(varchar, @DupeActiveRecs);
				END
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

	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullStockCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PM_Item WHERE ItemCode IS NULL
			)
			SET @infoStr = 'TotalNullRecords_PM_Item_ItemCode|' +  CONVERT(varchar, @NullRecs);
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
	   	 			
	--Identify the matching records in the StockMaterial table based upon matching Stock.StockNum and StockMaterial.SourceStockId with additional conditions of Source='LabelTraxx' and TenantId = @tenantId
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateStockProduct'; SET @startTime = GETDATE();
		BEGIN TRY	
	
			--update StockMaterial
			UPDATE SM 
			SET 
				FaceColor =	'', 
				FaceStock =	ISNULL(PVU_FS.UDValue,''),
				Classification = ISNULL(PVC.ClassName,''),
				AdhesiveClass = PVU_AC.UDValue,
				IsEnabled = IIF(PMI.InActive=0, 1, 0),
				ModifiedOn = GETUTCDATE(),
				SourceCreatedOn = createDate,
				SourceModifiedOn = CAST(CONVERT(datetime2, PMI.LastUpdatedDateTime) AS DATETIME),
				MFGSpecNum = null,
				[Type] = ISNULL(PVC.ClassName,'')
			FROM StockMaterial SM
			INNER JOIN #MatchingStocks MS ON SM.Id = MS.StockMaterialId
			INNER JOIN PM_Item PMI ON PMI.ItemCode = SM.SourceStockId AND PMI.ItemCode IS NOT NULL
			INNER JOIN PV_Class PVC ON PVC.ClassID = PMI.ClassID
			LEFT JOIN PV_UDElementData PVU_FS ON PMI.TableRecId = PVU_FS.UDLinkRecId AND PVU_FS.LinkPoint=3 AND PVU_FS.UDElement = 'Face Stock'
			LEFT JOIN PV_UDElementData PVU_AC ON PMI.TableRecId = PVU_AC.UDLinkRecId AND PVU_AC.LinkPoint=3 AND PVU_AC.UDElement = 'Adhesive - 1'
		
		
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

-- Skip mapping for StockMaterialSubstitute for Radius


	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertStockProduct'; SET @startTime = GETDATE();
		BEGIN TRY		
			--insert StockMaterial

			INSERT INTO StockMaterial(Id,TenantId,Source,SourceStockId,FaceColor,FaceStock,LinerCaliper,Classification,AdhesiveClass,IsEnabled,SourceCreatedOn,SourceModifiedOn,CreatedOn,ModifiedOn, MFGSpecNum, [Type])
			SELECT 
				NEWID(), 
				@TenantId,
				'Radius',
				PMI.ItemCode,
				'', 
				ISNULL(PVU_FS.UDValue,''),
				PMI.Caliper,
				ISNULL(PVC.ClassName ,''),
				PVU_AC.UDValue,
				IIF(PMI.Inactive=0, 1, 0),
				PMI.createDate,
				CAST(CONVERT(datetime2, PMI.LastUpdatedDateTime) AS DATETIME),
				GETUTCDATE(),
				GETUTCDATE(),
				null,
				'Roll'
			FROM PM_Item PMI
			INNER JOIN PV_Class PVC ON PVC.ClassID = PMI.ClassID
			LEFT JOIN PV_UDElementData PVU_FS ON PMI.TableRecId = PVU_FS.UDLinkRecId AND PVU_FS.LinkPoint=3 AND PVU_FS.UDElement = 'Face Stock'
			LEFT JOIN PV_UDElementData PVU_AC ON PMI.TableRecId = PVU_AC.UDLinkRecId AND PVU_AC.LinkPoint=3 AND PVU_AC.UDElement = 'Adhesive - 1'
			WHERE PMI.ItemCode NOT IN (SELECT StockId FROM #MatchingStocks) 
				AND PMI.ItemCode IS NOT NULL 
				AND PMI.AutoRequisition = 1

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
				
-- Skip mapping for StockMaterialSubstitute for Radius
	
	DROP TABLE IF EXISTS #MatchingStocks

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