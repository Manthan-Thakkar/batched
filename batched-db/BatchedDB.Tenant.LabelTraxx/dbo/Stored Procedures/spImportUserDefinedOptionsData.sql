CREATE PROCEDURE [dbo].[spImportUserDefinedOptionsData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100),
	@Since DateTime = NULL
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportUserDefinedOptionsData',
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
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0
	BEGIN
	SET @blockName = 'GetNewEquipmentUserDefinedOptions'; 
	SET @startTime = GETDATE();
	BEGIN TRY	
			-- Get only changed rows
			SELECT 
				EU.ID AS SourceEquipUDID,
				EM.Id AS EquipmentId,
				EU.Description,
				EU.SpeedChange
			INTO #UpdatedEquipmentUDO
			FROM Equip_UserDefined EU
			INNER JOIN EquipmentMaster EM ON EU.PRESS_NUMBER = EM.SourceEquipmentId
			WHERE @Since IS NULL OR EU.UpdateTimeDateStamp >= @Since;

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

	END TRY
	Begin CATCH
--	==================================[Do not change]================================================
		SET @IsError = 1; Rollback;
		SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--	=======================[Concate more error strings after this]===================================
       --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
	END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, 
			@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;
	END
	-- BLOCK END

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0
	BEGIN
	SET @blockName = 'UpdateEquipmentUserDefinedOptions'; 
	SET @startTime = GETDATE();
	BEGIN TRY

			UPDATE EUDO
			SET 
				EUDO.Description  = UE.Description,
				EUDO.SpeedChange = UE.SpeedChange,
				EUDO.ModifiedOnUtc = GETUTCDATE()
			FROM EquipmentUserDefinedOptions EUDO
			INNER JOIN #UpdatedEquipmentUDO UE
			ON EUDO.ID = UE.SourceEquipUDID

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

	END TRY
	Begin CATCH
--	==================================[Do not change]================================================
		SET @IsError = 1; Rollback;
		SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--	=======================[Concate more error strings after this]===================================
       --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
	END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, 
			@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;
	END

	-- BLOCK END

	IF @IsError = 0
	BEGIN
		SET @blockName = 'InsertEquipmentUserDefinedOptions'; 
		SET @startTime = GETDATE();
		BEGIN TRY

				INSERT INTO EquipmentUserDefinedOptions
				(
					Id,
					EquipmentId,
					Description,
					SpeedChange,
					CreatedOnUTC,
					ModifiedOnUTC
				)
				SELECT  
					UE.SourceEquipUDID,
					UE.EquipmentId,
					UE.Description,
					UE.SpeedChange,
					GETUTCDATE() AS CreatedOnUTC,
					GETUTCDATE() AS ModifiedOnUTC
				FROM #UpdatedEquipmentUDO UE
				WHERE NOT EXISTS 
				(
					SELECT 1 
					FROM EquipmentUserDefinedOptions EUDO
					WHERE EUDO.ID = UE.SourceEquipUDID
				);

				SET @infoStr = 'TotalRowsAffected-EquipmentUserDefinedOptions|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
	--	==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError-EquipmentUserDefinedOptions|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--	=======================[Concate more error strings after this]===================================
		   --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, 
			@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;
	END

	-- BLOCK END

--	    ========================[final commit log for Import EquipmentUserDefinedOptions (do not change)] =======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit-EquipmentUserDefinedOptions', 'info', 'message|all blocks of  EquipmentUserDefinedOptions completed without any error')
	END
--		=================================================================================================
DROP table IF EXISTS #UpdatedEquipmentUDO

--      ========================  Import TicketUserDefinedOptions Data BEGIN ==============================

	IF @IsError = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @blockName = 'InsertTicketUserDefinedOptions'; 
			SET @startTime = GETDATE();
			BEGIN TRY
	
					TRUNCATE TABLE TicketUserDefinedOptions
					;WITH DistinctPairs AS (
						SELECT DISTINCT
							TM.ID AS TicketId,
							TUD.EQUIPUSERDEFINED_ID AS SourceEquipUDID
						FROM Ticket_UserDefined AS TUD
						INNER JOIN Equip_UserDefined AS EUD
							ON TUD.EQUIPUSERDEFINED_ID = EUD.ID
						INNER JOIN TicketMaster AS TM
							ON TUD.TICKETNUMBER = TM.SourceTicketId
						WHERE TUD.USETHISOPTION = 1
					)
					INSERT INTO TicketUserDefinedOptions
					(
						Id,
						TicketId,
						SourceEquipUDID,
						IsEnabled,
						CreatedOnUTC,
						ModifiedOnUTC
					)
					SELECT
						NEWID(),
						dp.TicketId,
						dp.SourceEquipUDID,
						1,                 -- since filtered by USETHISOPTION = 1
						GETUTCDATE(),
						GETUTCDATE()
					FROM DistinctPairs AS dp;
	
					SET @infoStr = 'TotalRowsAffected-TicketUserDefinedOptions|' +  CONVERT(varchar, @@ROWCOUNT)
	
				END TRY
				Begin CATCH
				--		==================================[Do not change]================================================
					SET @IsError = 1; Rollback;
					SET @ErrorStr = 'systemError-TicketUserDefinedOptions|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
				END CATCH
	
				INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, 
					@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;

			--	    ========================[final commit log for Import TicketUserDefinedOptions (do not change)] =======================================
				IF @IsError = 0
				BEGIN
					COMMIT;
					INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
						@spName, 'final-commit-TicketUserDefinedOptions', 'info', 'message|all blocks of TicketUSerDefinedOptions completed without any error')
				END
				SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
			--		=================================================================================================

		END

--      ========================  Import TicketUserDefinedOptions Data END ==============================

	
END