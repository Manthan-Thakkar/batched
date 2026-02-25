CREATE PROCEDURE [dbo].[spUpdateDailyEquipmentCapacity]
	@TenantId	as	nvarchar(36) = null,
	@CorelationId  as varchar(100) = null
AS
BEGIN

	SET NOCOUNT ON;
	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateDailyEquipmentCapacity',
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
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'Truncate DailyEquipmentCapacity'; SET @startTime = GETDATE();

			Begin TRY	
				TRUNCATE TABLE DailyEquipmentCapacity;
				
				SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
					
			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END
	IF @IsError = 0	
	SET @blockName = 'InsertDailyEquipmentCapacity'; SET @startTime = GETDATE();
	Begin TRY
	  	BEGIN
			WITH TenantId_CTE
			AS (
					SELECT TOP 1 tenantID
					FROM EquipmentMaster
				)
				,SysTimeOffSet_CTE
			AS (
					SELECT SYSDATETIMEOFFSET() AT TIME ZONE(value) AS TenantTimeZoneTime FROM
					ConfigurationValue CV
					JOIN ConfigurationMaster CM on CV.ConfigId = CM.Id
					AND  Name = 'TimeZone'
				)
				,DailyMachineCapacity_CTE
			AS (
					SELECT SourceEquipmentId AS SourceEquipmentId
						,CAST(TheDateTime AS DATE) AS DATE
						,COUNT(*) / 60.0 AS AvailableHours
					FROM EquipmentCalendar
					WHERE Available = 1
						AND TheDateTime >= (
							SELECT TOP 1 TenantTimeZoneTime
							FROM SysTimeOffSet_CTE
							)
					GROUP BY SourceEquipmentId
						,CAST(TheDateTime AS DATE)
				) 
			INSERT INTO DailyEquipmentCapacity(SourceEquipmentId, Date, PlannedHours)
			SELECT SourceEquipmentId, DATE, AvailableHours from DailyMachineCapacity_CTE

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		END
	END TRY
	Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	END CATCH
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

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