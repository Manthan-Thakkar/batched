CREATE PROCEDURE [dbo].[spImportTicketTaskData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100),
	@Since DateTime = NULL
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketTaskData',
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
		SET @blockName = 'GetTaskData_FromTicket'; SET @startTime = GETDATE();

		DECLARE @IsUpdatedLT AS BIT = IIF(EXISTS(SELECT 1 FROM TicketTools_LT), 1, 0);
			---- Check whether the tenant is using LabelTraxx version >= 9.3
			---- "TicketTools_LT" table will be populated for the tenants with LabelTraxx version >= 9.3


		SELECT
			tm.ID                    AS TicketMasterId,
			tm.SourceTicketId        AS TicketNumber,
			v.TaskId,
			v.TaskName,
			IIF(v.TaskName = 'REWINDER' AND @IsUpdatedLT = 0, 5, v.Sequence) AS [Sequence],
			v.EstRunHrs,
			v.EstMakeReadyHrs,
			v.EstWuHours,
			v.EstTotalHrs,
			v.IsComplete
		INTO #StepSequence
		FROM dbo.TicketMaster AS tm WITH (NOLOCK)
		CROSS APPLY (VALUES
		   (tm.Press,   'PRESS',    1, tm.EstRunHrs,        tm.EstMRHrs,            tm.EstWuHrs,          tm.EstTime,        tm.PressDone),
		   (tm.EquipId, 'EQUIP',    2, tm.EquipEstRunHrs,   tm.EquipMakeReadyHours, tm.EquipWashUpHours,  tm.EquipEstTime,   tm.EquipDone),
		   (tm.Equip3Id,'EQUIP3',   3, tm.Equip3EstRunHrs,  tm.Equip3MakeReadyHours,tm.Equip3WashUpHours, tm.Equip3EstTime,  tm.Equip3Done),
		   (tm.Equip4Id,'EQUIP4',   4, tm.Equip4EstRunHrs,  tm.Equip4MakeReadyHours,tm.Equip4WashUpHours, tm.Equip4EstTime,  tm.Equip4Done),
		   (tm.Equip5Id,'EQUIP5',   5, tm.Equip5EstRunHrs,  tm.Equip5MakeReadyHours,tm.Equip5WashUpHours, tm.Equip5EstTime,  tm.Equip5Done),
		   (tm.Equip6Id,'EQUIP6',   6, tm.Equip6EstRunHrs,  tm.Equip6MakeReadyHours,tm.Equip6WashUpHours, tm.Equip6EstTime,  tm.Equip6Done),
		   (tm.Equip7Id,'REWINDER', 7, tm.Equip7EstRunHrs,  tm.Equip7MakeReadyHours,tm.Equip7WashUpHours, tm.Equip7EstTime,  tm.Equip7Done)
		) AS v (TaskId, TaskName, Sequence, EstRunHrs, EstMakeReadyHrs, EstWuHours, EstTotalHrs, IsComplete)
		WHERE v.TaskId IS NOT NULL

		CREATE NONCLUSTERED INDEX IX_StepSequence_TicketMasterId_Sequence ON #StepSequence(TicketMasterId, Sequence) INCLUDE (TaskName)
		CREATE NONCLUSTERED INDEX IX_StepSequence_TaskId ON #StepSequence(TaskId)

		SELECT 
			tci.TicketId AS TicketId,
			tci.TaskName AS TaskName,
			SUM(tci.ActualNetQuantity) AS ActualNetQuantity
		INTO #TicketProducedNetQty
		FROM #StepSequence ss
		INNER JOIN TimecardInfo tci WITH (NOLOCK)
			ON ss.TicketMasterId = tci.TicketId AND ss.TaskName = tci.TaskName
		GROUP BY tci.TicketId, tci.TaskName

	
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END		

	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTicketTaskData'; SET @startTime = GETDATE();

		Begin TRY
		
 			Update
 				TicketTaskData
 			set
 				Sequence = ss.Sequence,
 				OriginalEquipmentId = em.ID,
 				WorkcenterId = em.WorkcenterTypeId,
 				IsComplete = ss.IsComplete,
 				EstTotalHours = ss.EstTotalHrs,
 				EstMakeReadyHours = ss.EstMakeReadyHrs,
 				EstRunHours = ss.EstRunHrs,
				NetQuantityProduced = CASE WHEN tpnq.TicketId IS NOT NULL THEN tpnq.ActualNetQuantity ELSE 0 END, 
 				ModifiedOnUTC = GETUTCDATE()
 			FROM 
 				[TicketTaskData] TTD
				inner join #StepSequence ss on ss.TicketMasterId = ttd.TicketId and ss.Sequence = ttd.Sequence
				INNER JOIN TicketMaster tm WITH (NOLOCK) on ss.TicketMasterId = tm.ID
				INNER JOIN EquipmentMaster em WITH (NOLOCK) on ss.TaskId = em.SourceEquipmentId
				LEFT JOIN #TicketProducedNetQty tpnq on TTD.TicketId = tpnq.TicketId AND TTD.TaskName = tpnq.TaskName
			where @Since IS NULL
				OR tm.ModifiedOn >= @Since


		SET @infoStr ='TotalRowsAffected|'+ CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do NOT change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END		
	


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertTicketTaskData'; SET @startTime = GETDATE();

		Begin TRY
		

		insert into TicketTaskData (
				Id, TicketId, TaskName, Sequence, OriginalEquipmentId, ActualEquipmentId, WorkcenterId, IsComplete, EstTotalHours, EstMaxDueDateTime, CreatedOnUTC, ModifiedOnUTC,  EstMeters, IsProductionReady, EstMakeReadyHours, EstWashupHours, EstRunHours, NetQuantityProduced
			)
		select 
			NEWID(), --ID
			ss.TicketMasterId, --TicketId
			ss.TaskName, --TaskName
			ss.Sequence, --Sequence
			em.ID, --OriginalEquipmentId
			null, --ActualEquipmentId
			em.WorkcenterTypeId, --WorkcenterId
			ss.IsComplete, --IsComplete
			ss.EstTotalHrs, --EstTotalHours needs reviewed
			null, --EstMaxDueTime
			GETUTCDATE(), --CreatedOnUTC
			GETUTCDATE(), --ModifiedOnUtc
			null, --est meters
			0, --is production ready
			ss.EstMakeReadyHrs, --EstMakeReadyHours
			null, --EstWashUpHours
			ss.EstRunHrs, --EstRunHours
			CASE WHEN tpnq.TicketId IS NOT NULL THEN tpnq.ActualNetQuantity ELSE 0 END --NetQuantityProduced

		from #StepSequence ss
		INNER JOIN TicketMaster tm WITH (NOLOCK) on ss.TicketMasterId = tm.ID
		INNER JOIN EquipmentMaster em WITH (NOLOCK) on ss.TaskId = em.SourceEquipmentId
		LEFT JOIN #TicketProducedNetQty tpnq on ss.TicketMasterId = tpnq.TicketId AND ss.TaskName = tpnq.TaskName
		LEFT JOIN TicketTaskData ttd ON ttd.TicketId = ss.TicketMasterId and ttd.TaskName = ss.TaskName
		WHERE ttd.TicketId IS NULL

		SET @infoStr ='TotalRowsAffected|'+ CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do NOT change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END		

				
	-- Delete temporary table
	drop table if exists #StepSequence
	DROP TABLE IF EXISTS #TicketProducedNetQty
					   		
	
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
