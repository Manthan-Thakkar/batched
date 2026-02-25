CREATE PROCEDURE [dbo].[spImportEquipmentData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId   VARCHAR(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportEquipmentData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000, --keep this exactly same as 4000
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;
--	======================================================================================================
	END

	BEGIN TRANSACTION;

	IF @IsError = 0	
	BEGIN
		SET @blockName = 'GenerateTemporaryEquipmentData'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			SELECT WorkCentre.* 
			INTO #FilteredEquipments
			FROM PV_WorkCentre WorkCentre

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateEquipment'; SET @startTime = GETDATE();
		BEGIN TRY		

		--	INSERT YOUR LOGIC BLOCK HERE
			UPDATE EM 
			SET 
				EM.Name = E.WorkcCode, 
				EM.DisplayName = E.WorkcCode,
				EM.Description = E.WorkcName,
				EM.IsEnabled = (case when E.Active = 0 then 0 else 1 end),
				SourceCreatedOn = GETUTCDATE(),
				SourceModifiedOn =GETUTCDATE(),
				ModifiedOn = GETUTCDATE()
			FROM EquipmentMaster EM
			INNER JOIN #FilteredEquipments E on E.WorkcCode = EM.SourceEquipmentId and EM.Source = 'Radius'
			WHERE TenantId = @TenantId

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
		SET @blockName = 'InsertEquipment'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO EquipmentMaster (ID, TenantId, Source, SourceEquipmentId, Name, DisplayName, Description, SourceCreatedOn, SourceModifiedOn, CreatedOn, ModifiedOn)
			SELECT 
				NEWID() ID,
				@TenantId TenantId,
				'Radius' Source,
				WorkcCode SourceEquipmentId,
				WorkcCode Name,
				WorkcCode DisplayName,
				WorkcName Description,
				GETUTCDATE(),
				GETUTCDATE(),
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn
			FROM 
				#FilteredEquipments
			WHERE 
				WorkcCode not in (SELECT SourceEquipmentId FROM EquipmentMaster WHERE Source = 'Radius')
				
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
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================


	DROP TABLE IF EXISTS #FilteredEquipments


END