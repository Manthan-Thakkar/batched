CREATE PROCEDURE [dbo].[spPerformUnassignedJobsIncrRun]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spPerformUnassignedJobsIncrRun',
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
		SET @blockName = 'Incremental Run UnassignedJobs_temp'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			TRUNCATE TABLE UnassignedJobs_temp;

			INSERT INTO UnassignedJobs_temp(
				ID, RouteFeasible, CustomerNum, TaskName, TaskDueTime, Number, DoublePass_ReinsertionFlag, TaskEstimatedHours, Press, Pass, Priority, WorkcenterName, LastScan, ShipTime, TicketPoints, LinearLengthCalc, DoublePassJob, DueDateBucket, MasterRollNumber, TaskDueTimeReference,TaskEstimatedMinutes, TaskIndex, PressNumber, HighPriority, TaskClassification, MasterRollClassification, JobFirstAvailable, CreatedOn, ModifiedOn, IsProductionReady, Lag, Delay, DependentSourceTicketId, TicketTaskDataId, EnforceTaskDependency
				) 
			SELECT 
				ID, RouteFeasible, CustomerNum, TaskName, TaskDueTime, Number, DoublePass_ReinsertionFlag, TaskEstimatedHours, Press, Pass, Priority, WorkcenterName, LastScan, ShipTime, TicketPoints, LinearLengthCalc, DoublePassJob, DueDateBucket, MasterRollNumber, TaskDueTimeReference,TaskEstimatedMinutes, TaskIndex, PressNumber, HighPriority, TaskClassification, MasterRollClassification, JobFirstAvailable, CreatedOn, ModifiedOn, IsProductionReady, Lag, Delay, DependentSourceTicketId, TicketTaskDataId, EnforceTaskDependency
			FROM UnassignedJobs;

			MERGE INTO UnassignedJobs_temp AS ujt
			USING UnassignedJobs_Incr AS uji
			ON ujt.Number = uji.Number AND ujt.TaskName = uji.TaskName AND ujt.PressNumber = uji.PressNumber
			WHEN MATCHED THEN
			    UPDATE SET
			        ujt.CustomerNum = uji.CustomerNum,
					ujt.TaskDueTime = uji.TaskDueTime,
					ujt.DoublePass_ReinsertionFlag = uji.DoublePass_ReinsertionFlag,
					ujt.TaskEstimatedHours = uji.TaskEstimatedHours,
					ujt.Pass = uji.Pass,
					ujt.Priority = uji.Priority,
					ujt.WorkcenterName = uji.WorkcenterName, 
					ujt.LastScan = uji.LastScan, 
					ujt.ShipTime = uji.ShipTime, 
					ujt.TicketPoints = uji.TicketPoints,
					ujt.LinearLengthCalc = uji.LinearLengthCalc, 
					ujt.DoublePassJob = uji.DoublePassJob,
					ujt.DueDateBucket = uji.DueDateBucket, 
					ujt.MasterRollNumber = uji.MasterRollNumber,
					ujt.TaskDueTimeReference = uji.TaskDueTimeReference,
					ujt.TaskEstimatedMinutes = uji.TaskEstimatedMinutes, 
					ujt.TaskIndex = uji.TaskIndex,
					ujt.Press = uji.Press,
					ujt.HighPriority = uji.HighPriority, 
					ujt.TaskClassification = uji.TaskClassification,
					ujt.MasterRollClassification = uji.MasterRollClassification,
					ujt.JobFirstAvailable = uji.JobFirstAvailable, 
					ujt.ModifiedOn = GETUTCDATE(), 
					ujt.IsProductionReady = uji.IsProductionReady, 
					ujt.Lag = uji.Lag, 
					ujt.Delay = uji.Delay, 
					ujt.DependentSourceTicketId = uji.DependentSourceTicketId, 
					ujt.TicketTaskDataId = uji.TicketTaskDataId, 
					ujt.EnforceTaskDependency = uji.EnforceTaskDependency
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT (ID, RouteFeasible, CustomerNum, TaskName, TaskDueTime, Number, DoublePass_ReinsertionFlag, TaskEstimatedHours, Press, Pass, Priority, WorkcenterName, LastScan, ShipTime, TicketPoints, LinearLengthCalc, DoublePassJob, DueDateBucket, MasterRollNumber, TaskDueTimeReference,TaskEstimatedMinutes, TaskIndex, PressNumber, HighPriority, TaskClassification, MasterRollClassification, JobFirstAvailable, CreatedOn, ModifiedOn, IsProductionReady, Lag, Delay, DependentSourceTicketId, TicketTaskDataId, EnforceTaskDependency)
			    VALUES (uji.ID, uji.RouteFeasible, uji.CustomerNum, uji.TaskName, uji.TaskDueTime, uji.Number, uji.DoublePass_ReinsertionFlag, uji.TaskEstimatedHours, uji.Press, uji.Pass, uji.Priority, uji.WorkcenterName, uji.LastScan, uji.ShipTime, uji.TicketPoints, uji.LinearLengthCalc, uji.DoublePassJob, uji.DueDateBucket, uji.MasterRollNumber, uji.TaskDueTimeReference,uji.TaskEstimatedMinutes, uji.TaskIndex, uji.PressNumber, uji.HighPriority, uji.TaskClassification, uji.MasterRollClassification, uji.JobFirstAvailable, uji.CreatedOn, uji.ModifiedOn, uji.IsProductionReady, uji.Lag, uji.Delay, uji.DependentSourceTicketId, uji.TicketTaskDataId, uji.EnforceTaskDependency);
			

		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		END TRY

		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH

		SET @blockName = 'Delete from UnassignedJobs_Temp'; SET @startTime = GETDATE();
		BEGIN TRY		

		IF EXISTS (select 1 from TicketTask_Temp)
		BEGIN		
			DELETE FROM UnassignedJobs_temp where id in
			(select uj.ID
				from UnassignedJobs_temp uj
				left join (select tt.TaskName, tt.TicketId, tm.SourceTicketId from TicketTask_temp tt inner join ticketmaster tm on tt.TicketId = tm.ID ) tt on uj.TaskName = tt.TaskName and uj.Number = tt.SourceTicketId
				where tt.TaskName is null)	
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