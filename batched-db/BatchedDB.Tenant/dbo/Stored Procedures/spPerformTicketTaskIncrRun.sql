CREATE PROCEDURE [dbo].[spPerformTicketTaskIncrRun]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spPerformTicketTaskIncrRun',
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
		SET @blockName = 'Incremental Run TicketTask_temp'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			TRUNCATE TABLE TicketTask_temp;

			INSERT INTO TicketTask_temp(
				ID, TicketId, TaskName, Sequence, OriginalEquipmentId, ActualEquipmentId, WorkcenterId, IsComplete, EstMakeReadyHours, EstWashupHours, EstRunHours, EstTotalHours, EstMaxDueDateTime, CreatedOn, ModifiedOn, Pass, DoublePassJob, DoublePass_ReInsertionFlag, EstMeters, IsProductionReady, Lag, Delay, DependentSourceTicketId, EnforceTaskDependency, TaskStockStatus, MasterRollNumber, TaskClassification, MasterRollClassification, ActualEstTotalHours
				) 
			SELECT 
				ID, TicketId, TaskName, Sequence, OriginalEquipmentId, ActualEquipmentId, WorkcenterId, IsComplete, EstMakeReadyHours, EstWashupHours, EstRunHours, EstTotalHours, EstMaxDueDateTime, CreatedOn, ModifiedOn, Pass, DoublePassJob, DoublePass_ReInsertionFlag, EstMeters, IsProductionReady, Lag, Delay, DependentSourceTicketId, EnforceTaskDependency, TaskStockStatus, MasterRollNumber, TaskClassification, MasterRollClassification, ActualEstTotalHours
			FROM TicketTask;

			MERGE INTO TicketTask_temp AS ttt
			USING TicketTask_Incr AS tti
			ON ttt.TicketId = tti.TicketId AND ttt.TaskName = tti.TaskName
			WHEN MATCHED THEN
			    UPDATE SET
			        ttt.Sequence = tti.Sequence,
					ttt.OriginalEquipmentId = tti.OriginalEquipmentId,
					ttt.ActualEquipmentId = tti.ActualEquipmentId,
					ttt.WorkcenterId = tti.WorkcenterId,
					ttt.IsComplete = tti.IsComplete,
					ttt.EstMakeReadyHours = tti.EstMakeReadyHours,
					ttt.EstWashupHours = tti.EstWashupHours,
					ttt.EstRunHours = tti.EstRunHours,
					ttt.EstTotalHours = tti.EstTotalHours,
					ttt.EstMaxDueDateTime = tti.EstMaxDueDateTime, 
					ttt.ModifiedOn = GETUTCDATE(),
					ttt.Pass = tti.Pass,
					ttt.DoublePassJob = tti.DoublePassJob,
					ttt.DoublePass_ReInsertionFlag = tti.DoublePass_ReInsertionFlag,
					ttt.EstMeters = tti.EstMeters,
					ttt.IsProductionReady = tti.IsProductionReady,
					ttt.Lag = tti.Lag,
					ttt.Delay = tti.Delay,
					ttt.DependentSourceTicketId = tti.DependentSourceTicketId,
					ttt.EnforceTaskDependency = tti.EnforceTaskDependency,
					ttt.TaskStockStatus = tti.TaskStockStatus,
					ttt.MasterRollNumber = tti.MasterRollNumber,
					ttt.TaskClassification = tti.TaskClassification,
					ttt.MasterRollClassification = tti.MasterRollClassification,
					ttt.ActualEstTotalHours = tti.ActualEstTotalHours
					WHEN NOT MATCHED BY TARGET THEN
			    INSERT (ID, TicketId, TaskName, Sequence, OriginalEquipmentId, ActualEquipmentId, WorkcenterId, IsComplete, EstMakeReadyHours, EstWashupHours, EstRunHours, EstTotalHours, EstMaxDueDateTime, CreatedOn, ModifiedOn, Pass, DoublePassJob, DoublePass_ReInsertionFlag, EstMeters, IsProductionReady, Lag, Delay, DependentSourceTicketId, EnforceTaskDependency, TaskStockStatus, MasterRollNumber, TaskClassification, MasterRollClassification, ActualEstTotalHours)
			    VALUES (tti.ID, tti.TicketId, tti.TaskName, tti.Sequence, tti.OriginalEquipmentId, tti.ActualEquipmentId, tti.WorkcenterId, tti.IsComplete, tti.EstMakeReadyHours, tti.EstWashupHours, tti.EstRunHours, tti.EstTotalHours, tti.EstMaxDueDateTime, tti.CreatedOn, tti.ModifiedOn, tti.Pass, tti.DoublePassJob, tti.DoublePass_ReInsertionFlag, tti.EstMeters, tti.IsProductionReady, tti.Lag, tti.Delay, tti.DependentSourceTicketId, tti.EnforceTaskDependency, tti.TaskStockStatus, tti.MasterRollNumber, tti.TaskClassification, tti.MasterRollClassification, tti.ActualEstTotalHours);
			
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