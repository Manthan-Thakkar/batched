CREATE PROCEDURE [dbo].[spPerformFeasibleRouteIncrRun]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spPerformFeasibleRouteIncrRun',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END
	
	
	IF @IsError = 0	
	BEGIN
		BEGIN TRANSACTION
		SET @blockName = 'Incremental Run FeasibleRoute_temp'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			TRUNCATE TABLE FeasibleRoutes_temp;

			INSERT INTO FeasibleRoutes_temp(
				ID, TicketId, TaskId, EquipmentId, RouteFeasible, ConstraintDescription, CreatedOn, ModifiedOn
				) 
			SELECT 
				ID, TicketId, TaskId, EquipmentId, RouteFeasible, ConstraintDescription, CreatedOn, ModifiedOn
			FROM FeasibleRoutes;

			MERGE INTO FeasibleRoutes_temp AS frt
			USING FeasibleRoutes_Incr AS fri
			ON frt.TicketId = fri.TicketId AND frt.TaskId = fri.TaskId AND frt.EquipmentId = fri.EquipmentId
			WHEN MATCHED THEN
			    UPDATE SET
			        frt.ModifiedOn = GETUTCDATE(),
			        frt.RouteFeasible = fri.RouteFeasible,
			        frt.ConstraintDescription = fri.ConstraintDescription
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT (ID, TicketId, TaskId, EquipmentId, CreatedOn, ModifiedOn, RouteFeasible, ConstraintDescription)
			    VALUES (fri.ID, fri.TicketId, fri.TaskId, fri.EquipmentId, fri.CreatedOn, fri.ModifiedOn, fri.RouteFeasible, fri.ConstraintDescription);
			
		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		END TRY

		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH

		SET @blockName = 'Delete from FeasibleRoute_temp'; SET @startTime = GETDATE();
		BEGIN TRY	
		IF EXISTS (select 1 from TicketTask_Temp)
		BEGIN			
			DELETE FROM FeasibleRoutes_temp where id in (select uj.ID
					from FeasibleRoutes_temp uj
					left join TicketTask_temp tt
					on uj.TaskId = tt.Id
					where tt.id is null)	
		END

		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		END TRY
		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH


		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

		IF @IsError = 0
		BEGIN
			COMMIT TRANSACTION;
		END

		IF @IsError = 0
		BEGIN
			INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
				@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
		END
		
		SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
	END
END