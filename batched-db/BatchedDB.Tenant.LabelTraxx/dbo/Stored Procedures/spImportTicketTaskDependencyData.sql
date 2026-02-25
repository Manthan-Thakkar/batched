CREATE PROCEDURE [dbo].[spImportTicketTaskDependencyData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketTaskDependencyData',
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

	select
	ttd.ID,
	ttd.TaskName,
	ttd.TicketId,
	ttd.sequence,
	ROW_NUMBER() OVER(PARTITION BY ttd.TicketId ORDER BY ttd.sequence Asc) AS row_number,
	tm.SourceTicketId,
	tm.DependentSourceTicketId,
	tm2.ID as DependantTicketId
	into #TicketTaskSequence
	FROM TicketTaskData ttd
	inner join TicketMaster tm on ttd.TicketId = tm.ID
	left join TicketMaster tm2 on tm.DependentSourceTicketId = tm2.SourceTicketId
	ORDER BY ttd.TicketId asc, Sequence Asc

	select TicketId, min(row_number) as firststep,max(row_number) as laststep
	into #FirstAndLastSteps 
	from #TicketTaskSequence
	group by TicketId

	select tts.ID as TicketTaskDataId, tts.TicketId as TicketId, tts.TaskName as TaskName, tts2.ID as PreviousTaskDataId, tts2.TaskName as PreviousTaskName	
	into #TicketTaskPreviousSteps
	from #TicketTaskSequence tts
	inner join #TicketTaskSequence tts2 on tts.DependantTicketId = tts2.TicketId
	where tts2.row_number = (select laststep from #FirstAndLastSteps fls where tts2.TicketId = fls.ticketId)--First step of task is dependant on last step of previous ticket
	and tts.row_number = 1--Ensure only first step of ticket has dependency on last step of previous ticket
	ORDER BY tts.TicketId asc, tts.Sequence Asc

	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTicketTaskDependencyData'; SET @startTime = GETDATE();

		Begin TRY
		
		--to be replaced with update statement
 			Update
 				TicketTaskDependency
 			set
				DependentTicketId = ttps.TicketId,
				DependentTicketTaskDataId = ttps.PreviousTaskDataId,
				TicketTaskDataId = ttps.TicketTaskDataId, 
 				ModifiedOnUTC = GETUTCDATE()
 			FROM 
 				[TicketTaskDependency] TTD
				inner join #TicketTaskPreviousSteps ttps on TTD.TicketTaskDataId = ttps.TicketTaskDataId AND TTD.DependentTicketTaskDataId = ttps.PreviousTaskDataId

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
		SET @blockName = 'InsertTicketTaskDependencyData'; SET @startTime = GETDATE();

		Begin TRY
		
		--to be replaced with update statement

		insert into TicketTaskDependency(
				Id, DependentTicketId, DependentTicketTaskDataId, TicketTaskDataId, CreatedOnUTC, ModifiedOnUTC
			)
		select 
			NEWID(), --ID
			ttps.TicketId, --DependentTicketId
			ttps.PreviousTaskDataId, --DependentTicketTaskDataId
			ttps.TicketTaskDataId, --TicketTaskDataId
			GETUTCDATE(), --CreatedOnUTC
			GETUTCDATE() --ModifiedOnUtc
		from #TicketTaskPreviousSteps ttps
		where ttps.TicketTaskDataId not in (
		SELECT ttd.Id
			FROM TicketTaskData ttd 
			right JOIN TicketTaskDependency ttdep
			ON ttdep.TicketTaskDataId = ttd.Id 
			WHERE ttdep.DependentTicketId is NOT null)

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
	DROP table if exists #TicketTaskSequence
	DROP TABLE IF EXISTS #FirstAndLastSteps			
	DROP table if exists #TicketTaskPreviousSteps	   		
	
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
