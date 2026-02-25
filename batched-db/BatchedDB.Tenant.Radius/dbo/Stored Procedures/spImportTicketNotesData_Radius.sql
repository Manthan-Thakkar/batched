CREATE PROCEDURE [dbo].[spImportTicketNotesData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketNotesData',
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

	-- #PV_Jobs temp table WITH concatenated ticket number
	SELECT 
		J.*,JC.JobCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
	INTO #PV_Jobs
	FROM PV_job J
		INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
	where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

	SELECT 
		wco.OptionName,
		j.JobCode,
		j.TableRecId,
		wcc.WorkcCode,
		j.TicketNumber as TicketNumber
	into #TicketNotesPreData
	From PV_WorkcConfigOption wco
	INNER JOIN PV_WorkcConfig wcc on wcc.CompNum = wco.CompNum and wcc.WorkcCode = wco.WorkcCode and wcc.ConfigNum = wco.ConfigNum
	INNER JOIN [wi-roption] ro ON wcc.CompNum = ro.kco and wcc.WorkcCode  = ro.kwcsn and wcc.ConfigNum = ro.kconfig and wco.OptionNum = ro.[wi-ro-option]
	INNER JOIN #PV_Jobs j ON ro.kco = j.CompNum and ro.PlantCode = j.PlantCode and ro.korder = j.JobCode
	
	
	IF @IsError = 0	
	  	BEGIN
		DECLARE @UpdateTicketNumberMappingMissingCount int
		DECLARE @UpdatePressNumberMappingMissingCount int
		

		SET @blockName = 'Delete Ticket Notes'; SET @startTime = GETDATE();

		Begin TRY		


			Truncate Table TicketNote

			------
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
	  	BEGIN
		DECLARE @InsertMappingMissingEquipmentMasterCount int
		DECLARE @InsertMappingMissingTicketMasterCount int
		SET @blockName = 'InsertTicketNotes'; SET @startTime = GETDATE();

		Begin TRY
		-- Insert the new records
		INSERT INTO [dbo].[TicketNote]([ID] ,[TicketId],[SourceTicketNoteId],[SourceTicketId],[EquipmentId],[SourceEquipmentId],[Description],[Notes],[IsEnabled],[CreatedOn],[ModifiedOn])
		SELECT 
				NEWID(),
				ticMstr.ID,
				ticUsr.TableRecId,
				ticUsr.TICKETNUMBER,
				equipMstr.ID,
				ticUsr.WorkcCode,
				ticUsr.OptionName,
				null,
				1,
				GETUTCDATE(),
				GETUTCDATE()
			FROM #TicketNotesPreData ticUsr INNER JOIN EquipmentMaster equipMstr
			ON ticUsr.WorkcCode = equipMstr.SourceEquipmentId 
			INNER JOIN TicketMaster ticMstr ON ticMstr.SourceTicketId = ticUsr.Ticketnumber
			Where  ticUsr.TableRecId IS NOT NULL
		------
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
		
		
		drop table if exists #PV_Jobs;
		drop table if exists #TicketNotesPreData;
	
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

