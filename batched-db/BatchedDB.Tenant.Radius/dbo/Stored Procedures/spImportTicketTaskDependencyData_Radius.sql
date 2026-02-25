CREATE PROCEDURE [dbo].[spImportTicketTaskDependencyData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId	VARCHAR(100)
AS		
BEGIN
	SET NOCOUNT ON;
	BEGIN
--	==============================logging variables (do NOT change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportTicketTaskDependencyData_Radius',
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
            , ROW_NUMBER() OVER (Partition by js.CompNum, js.PlantCode, js.JobCode, js.VRType Order by js.JobCmpNum ASC, js.[est-route-seq] ASC) as SortOrder
        INTO #PV_JobSteps
        FROM PV_JobStep js
        Where js.StepType in (3,5) and js.CmpType in (7, 9, 10)
			
		CREATE NONCLUSTERED INDEX [IX_PV_JobStep_TicketNumber] ON #PV_JobSteps
		(
			TicketNumber ASC
		)
	SELECT 
		CompNum,
		PlantCode,
		TicketNumber,
		JobCode,
		WorkcCode AS Equip,
		CASE
			WHEN StepStatus IN (1,2) THEN 1
			ELSE 0
		END AS EquipDone,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,StepNum ASC) AS row_number
		INTO #AllEquipCalc
		FROM #PV_JobSteps js where js.VRType = 2


	select 
		tm.ID AS TicketId, --DependentTicketId
		ECA.TicketNumber As TicketNumber,
		ttd.Id As TicketTaskDataId, --TicketTaskDataId
		ECA.TaskName As TaskName,
		ECA2.TicketNumber as DepTicketNumber,
		ttd2.TicketId as DepTicketId,
		ttd2.Id as DepTicketTaskDataId, --DependentTicketTaskDataId,
		ECA2.TaskName as DepTaskName
	INTO #DependentTicketData
	from #AllEquipCalc eca
	INNER JOIN PV_JobPrevSteps jps on eca.CompNum = jps.CompNum and eca.TaskName = jps.StepNum and eca.JobCode = jps.JobCode --Typically provides make ready step
	INNER JOIN PV_JobPrevSteps jps2 on jps.CompNum = jps2.CompNum and jps.PreviousStep = jps2.StepNum and jps.JobCode = jps2.JobCode --Typically provides labor step
	INNER JOIN TicketMaster tm on eca.TicketNumber = tm.SourceTicketId
	INNER JOIN TicketTaskData ttd on tm.ID = ttd.TicketId and eca.TaskName = ttd.TaskName
	INNER JOIN #AllEquipCalc eca2 on jps2.CompNum = eca2.CompNum and jps2.PreviousStep = eca2.TaskName and jps2.JobCode = eca2.JobCode
	INNER JOIN TicketMaster tm2 on eca2.TicketNumber = tm2.SourceTicketId
	INNER JOIN TicketTaskData ttd2 on tm2.ID = ttd2.TicketId and eca2.TaskName = ttd2.TaskName
	WHERE tm.ID <> tm2.ID --only populate dependencies that have different ticket ids
		

	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertTicketTaskDependency'; SET @startTime = GETDATE();
		Begin TRY
		
		--to be replaced with update statement
		delete from TicketTaskDependency
		insert into TicketTaskDependency(
				Id, DependentTicketId, DependentTicketTaskDataId, TicketTaskDataId, CreatedOnUTC, ModifiedOnUTC
			)
		select 
			NEWID(), --ID
			DepTicketId,
			DepTicketTaskDataId,
			TicketTaskDataId,
			GETUTCDATE(), --CreatedOnUTC
			GETUTCDATE() --ModifiedOnUtc
		from #DependentTicketData dtd
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
	DROP TABLE IF EXISTS #DependentTicketData
	---To Be Replaced---
	
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