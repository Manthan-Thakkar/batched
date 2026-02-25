CREATE PROCEDURE [dbo].[spImportTicketTaskData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId	VARCHAR(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do NOT change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportTicketTaskData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000, --keep this exactly same AS 4000
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME,
--	======================================================================================================
		@totalSecondsPerMinute	FLOAT = 3600.00;
	END
	
	BEGIN TRANSACTION;
	
			
        -- #PV_JobSteps temp table WITH concatenated ticket number
        SELECT 
            *
            , CONCAT( js.CompNum,'_',js.PlantCode,'_',js.JobCode,'_',js.JobCmpNum) AS TicketNumber
            , ROW_NUMBER() OVER (Partition by js.CompNum, js.PlantCode, js.JobCode, js.JobCmpNum, js.VRType Order by js.JobCmpNum ASC, js.[est-route-seq] ASC) as SortOrder
        INTO #PV_JobSteps
        FROM PV_JobStep js
        Where js.StepType in (3,5) and js.CmpType in (7, 9, 10)

		CREATE NONCLUSTERED INDEX [IX_PV_JobStep_TicketNumber] ON #PV_JobSteps
		(
			TicketNumber ASC
		)



	SELECT 
		js.CompNum,
		js.PlantCode,
		js.TicketNumber,
		js.JobCode,
		js.JobCmpNum,
		js.WorkcCode AS Equip,
		CASE
			WHEN js.StepStatus IN (1,2) OR sfp.kstatus = 'C' OR sfec.CompletedSteps IS NOT NULL THEN 1
			ELSE 0
		END AS EquipDone,
		js.StepNum AS TaskName,
		js.VRType AS VRType,
		js.LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY js.CompNum,js.PlantCode,js.JobCode,js.JobCmpNum ORDER BY StepNum Asc) AS row_number
		INTO #AllEquipCalc
		FROM #PV_JobSteps js
		Left Join sfplan sfp on js.CompNum = sfp.kco and js.PlantCode = sfp.PlantCode and js.JobCode = sfp.kjobcode and js.JobCmpNum = sfp.kcompno and js.StepNum = sfp.kprocno
		Left Join (Select sfec.kco, sfec.PlantCode, sfec.kjobcode, sfec.kcompno, sfec.kprocno, count(*) as CompletedSteps
					From sfeventcds sfec
					INNER JOIN PV_Job j on j.CompNum = sfec.kco and j.PlantCode = sfec.PlantCode and j.JobCode = sfec.kjobcode
					Where j.JobStatus in (10, 20) and sfec.[event-type] = 'C'
					Group by sfec.kco, sfec.PlantCode, sfec.kjobcode, sfec.kcompno, sfec.kprocno) sfec on js.CompNum = sfec.kco and js.PlantCode = sfec.PlantCode and js.JobCode = sfec.kjobcode and js.StepNum = sfec.kprocno
		Where js.VRType in (1,2)

		SELECT TicketNumber,row_number, SUM(LabTime) AS EstTime INTO #EstTime FROM #AllEquipCalc group by TicketNumber, row_number
		SELECT TicketNumber,row_number, SUM(LabTime) AS EstRunTime INTO #EstRunTime FROM #AllEquipCalc WHERE VRType =2 group by TicketNumber, row_number
		SELECT TicketNumber,row_number, SUM(LabTime) AS EstMRTime INTO #EstMRTime FROM #AllEquipCalc WHERE VRType =1 group by TicketNumber, row_number

		SELECT
			tm.ID AS TicketId, --TicketId
			eca.TaskName AS TaskName, --TaskName
			eca.row_number AS Sequence, --Sequence
			em.ID AS OriginalEquipmentId, --OriginalEquipmentId
			em.WorkcenterTypeId AS WorkcenterId, --WorkcenterId
			eca.EquipDone AS IsComplete, --IsComplete
			et.EstTime AS EstTotalHours, --EstTotalHours needs reviewed
			emt.EstMRTime AS EstMakeReadyHours, --EstMakeReadyHours
			ert.EstRunTime AS EstRunHours --EstRunHours
		INTO #StepSequence
		from #AllEquipCalc eca
		INNER JOIN TicketMaster tm on eca.TicketNumber = tm.SourceTicketId
		INNER JOIN EquipmentMaster em on eca.Equip = em.SourceEquipmentId
		LEFT JOIN #EstTime et on eca.TicketNumber = et.TicketNumber and eca.row_number = et.row_number
		LEFT JOIN #EstRunTime ert on eca.TicketNumber = ert.TicketNumber and eca.row_number = ert.row_number
		LEFT JOIN #EstMRTime emt on eca.TicketNumber = emt.TicketNumber and eca.row_number = emt.row_number
	
		SELECT 
			tci.TicketId,
			tci.TaskName,
			SUM(tci.ActualNetQuantity) AS ActualNetQuantity
		INTO #TicketProducedNetQty
		FROM #StepSequence ss
		INNER JOIN TimecardInfo tci
			ON ss.TicketId = tci.TicketId AND ss.TaskName = tci.TaskName
		GROUP BY tci.TicketId, tci.TaskName	


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTicketTaskData'; SET @startTime = GETDATE();

		Begin TRY
		
 			Update
 				TicketTaskData
 			set
 				Sequence = ss.Sequence,
 				OriginalEquipmentId = ss.OriginalEquipmentId,
 				WorkcenterId = ss.WorkcenterId,
 				IsComplete = ss.IsComplete,
 				EstTotalHours = ss.EstTotalHours,
 				EstMakeReadyHours = ss.EstMakeReadyHours,
 				EstRunHours = ss.EstRunHours,
				NetQuantityProduced = CASE WHEN tpnq.TicketId IS NOT NULL THEN tpnq.ActualNetQuantity ELSE 0 END,
 				ModifiedOnUTC = GETUTCDATE()
 			FROM 
 				[TicketTaskData] TTD
				inner join #StepSequence ss on ss.TicketId = ttd.TicketId and ss.Sequence = ttd.Sequence
				LEFT JOIN #TicketProducedNetQty tpnq on TTD.TicketId = tpnq.TicketId AND TTD.TaskName = tpnq.TaskName

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
				Id, TicketId, TaskName, Sequence, OriginalEquipmentId, ActualEquipmentId, WorkcenterId, IsComplete, EstTotalHours, EstMaxDueDateTime, CreatedOnUTC, ModifiedOnUTC, EstMeters, IsProductionReady, EstMakeReadyHours, EstWashupHours, EstRunHours, NetQuantityProduced
			)
		select 
			NEWID(), --ID
			ss.TicketId, --TicketId
			ss.TaskName, --TaskName
			ss.Sequence, --Sequence
			ss.OriginalEquipmentId, --OriginalEquipmentId
			null, --ActualEquipmentId
			ss.WorkcenterId, --WorkcenterId
			ss.IsComplete, --IsComplete
			ss.EstTotalHours, --EstTotalHours needs reviewed
			null, --EstMaxDueTime
			GETUTCDATE(), --CreatedOnUTC
			GETUTCDATE(), --ModifiedOnUtc
			null, --est meters
			0, --is production ready
			ss.EstMakeReadyHours, --EstMakeReadyHours
			null, --EstWashUpHours
			ss.EstRunHours, --EstRunHours
			CASE WHEN tpnq.TicketId IS NOT NULL THEN tpnq.ActualNetQuantity ELSE 0 END --NetQuantityProduced
		from #StepSequence ss
		LEFT JOIN #TicketProducedNetQty tpnq ON ss.TicketId = tpnq.TicketId AND ss.TaskName = tpnq.TaskName
		where ss.TicketId not in (
		SELECT ticMaster.Id as TicketId
			FROM TicketMaster ticMaster 
			right JOIN TicketTaskData ttd
			ON ttd.TicketId = ticMaster.Id 
			WHERE ttd.TicketId is NOT null)

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
	DROP TABLE IF EXISTS #PV_Jobs
	DROP TABLE IF EXISTS #PV_JobSteps
	DROP TABLE IF EXISTS #AllEquipCalc
	DROP TABLE IF EXISTS #EstTime
	DROP TABLE IF EXISTS #EstRunTime
	DROP TABLE IF EXISTS #EstMRTime
	DROP TABLE IF EXISTS #StepSequence

	DROP TABLE IF EXISTS #equip
	DROP TABLE IF EXISTS #TicketProducedNetQty

	
--	    ========================[final commit log (do NOT change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END