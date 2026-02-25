CREATE PROCEDURE [dbo].[spImportToolData_Radius]
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportToolData_Radius',
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
		SET @blockName = 'DuplicateToolingCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) no_of_recs, SpecCode 
					FROM PV_ToolSpec 
					GROUP BY SpecCode
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_Tooling_Number|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						SELECT COUNT(1) no_of_recs, SpecCode, ApprovalStatus 
						FROM PV_ToolSpec
						WHERE ApprovalStatus in (0,10)
						GROUP BY SpecCode, ApprovalStatus
						HAVING COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_Tooling_Number|' +  CONVERT(varchar, @DupeActiveRecs);
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

	SELECT t.SpecCode, MAX(t.DeliveryDue) as DeliveryDue, t.PlantCode
	INTO #pv_tools_temp
	FROM PV_Tools t 
	GROUP BY t.SpecCode , t.PlantCode

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateTooling'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE TI 
			SET 
				DieSize				= PTS.MinWidth,
				GearTeeth			= PTS.Teeth,
				Location			= PTS.PlantList,
				FlexoHotStamping	= PTS.DieType,
				LinerCaliper		= PTS.Caliper,
				Shape				= PTS.Shape,
				IsEnabled			= (CASE WHEN PTS.ApprovalStatus in (0,10) THEN 1 ELSE 0 END),
				SourceModifiedOn    = CONVERT(DATETIME, CONVERT(varchar(19), PTS.LastUpdatedDateTime, 120)),
				ModifiedOn			= GETUTCDATE(),
				ToolDeliveryDate	= PVT.DeliveryDue,
				Pitch				= NULL,
				[NoAround]			= [PTS].[NumberDownPrint],
				[NoAcross]			= ROUND([PTS].[NumberAcross], 0),
				[SizeAcross]		= [PTS].[SizeAcross],
				[SizeAround]		= [PTS].[SizeDown],
				[ToolIn]			= NULL
			FROM ToolingInventory TI
			INNER JOIN PV_ToolSpec PTS ON PTS.SpecCode = TI.SourceToolingId AND TI.Source = 'Radius'
			INNER JOIN #pv_tools_temp PVT on PTS.SpecCode = PVT.SpecCode AND PTS.PlantList = PVT.PlantCode
			WHERE TenantId = @TenantId

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
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertTooling'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO ToolingInventory(
				Id, TenantId, Source, SourceToolingId, DieSize, GearTeeth, Location, FlexoHotStamping, SourceCreatedOn, SourceModifiedOn,
				IsEnabled, CreatedOn, ModifiedOn, LinerCaliper, Shape, ToolDeliveryDate, Pitch,
				NoAround, NoAcross, SizeAcross, SizeAround, ToolIn)
			SELECT 
				NEWID() ID,
				@TenantId TenantId,
				'Radius' Source,
				PTS.SpecCode SourceToolingId,
				PTS.MinWidth DieSize,
				PTS.Teeth GearTeeth,
				PTS.PlantList Location,
				PTS.DieType FlexoHotStamping,
				GETUTCDATE() SourceCreatedOn,
				CONVERT(DATETIME, CONVERT(varchar(19), PTS.LastUpdatedDateTime, 120)) SourceModifiedOn,
				(CASE WHEN PTS.ApprovalStatus in (0,10) THEN 1 ELSE 0 END) IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				PTS.Caliper LinerCaliper,
				PTS.Shape Shape,
				PVT.DeliveryDue, --ToolDeliveryDate
				NULL,
				[PTS].[NumberDownPrint] NoAround,
				ROUND([PTS].[NumberAcross], 0) NoAcross,
				[PTS].[SizeAcross] SizeAcross,
				[PTS].[SizeDown] SizeAround,
				NULL ToolIn
			FROM  PV_ToolSpec PTS
			INNER JOIN #pv_tools_temp PVT on PTS.SpecCode = PVT.SpecCode AND PTS.PlantList = PVT.PlantCode
			WHERE PTS.SpecCode NOT IN (SELECT SourceToolingId FROM ToolingInventory WHERE [Source] = 'Radius') AND PTS.SpecCode IS NOT NULL
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (SELECT COUNT(1) FROM PV_ToolSpec WHERE SpecCode NOT IN (SELECT SourceToolingId FROM ToolingInventory WHERE [Source] = 'Radius') AND SpecCode IS NULL)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Tooling_Number|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
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
	-- BLOCK END

	--DELETE Temp Tables
			BEGIN
				DROP TABLE IF EXISTS #UniqueTools

				DROP TABLE IF EXISTS #UniqueToolSpec
				DROP TABLE IF EXISTS #pv_tools_temp
			END
	
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