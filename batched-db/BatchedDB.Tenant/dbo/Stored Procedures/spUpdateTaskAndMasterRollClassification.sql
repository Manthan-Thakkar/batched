CREATE PROCEDURE [dbo].[spUpdateTaskAndMasterRollClassification]
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateTaskAndMasterRollClassification',
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

--  ============= declare local variables ==============
	DECLARE @ticketStockAvailabilityEnabled bit = 0; 
--  ====================================================

	BEGIN TRANSACTION;

	drop table if exists #ScheduleReport
	drop table if exists #MasterRollClassifications
	drop table if exists #TaskClassifications
	drop table if exists #TimeCardScans
	drop table if exists #TempMasterRollClassification
	drop table if exists #MasterRollNumbers
	drop table if exists #TicketStockFirstAvailable


			-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Generating Schedule Report Temp Table'; SET @startTime = GETDATE();

		Begin TRY	

				Select SourceTicketId,EquipmentId,Taskname, MasterRollNumber
				Into #ScheduleReport
				From ScheduleReport WITH(NOLOCK)

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Generating Time card scans'; SET @startTime = GETDATE();

		Select Distinct TicketId
		INTO #Tickets
		From TicketTask_temp WITH(NOLOCK)

		Begin TRY	

				select 
					   TI.TicketId 
					 , EM.WorkCenterName
					 , MIN(StartedOn) as firstScan
					 , CASE 
						  WHEN MAX(CompletedAt) is not null  THEN MAX(CompletedAt)
						  ELSE MAX(StartedOn)
					   END as lastScan
				into #TimeCardScans
				FROM 
				TimecardInfo TI WITH(NOLOCK)
				Inner join EquipmentMaster EM WITH(NOLOCK) on TI.EquipmentId = EM.ID
				INNER JOIN #TICKETS ttt on TI.TicketId = ttt.TicketId 
				GROUP BY TI.TicketId , EM.WorkCenterName

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END

		-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Generating Task classifications'; SET @startTime = GETDATE();

		Begin TRY	

			

				;with taskGroup as (
				select  TTT.ticketId as TicketId, 
				EM.WorkcenterTypeId as WorkcenterTypeId,
				EM.WorkCenterName as WorkCenterName, 
				TAV.Name as Name  ,
				Max(TAV.Value) as Value
				from TicketTask_temp TTT WITH(NOLOCK)
							Inner Join EQuipmentMaster EM WITH(NOLOCK) on TTT.OriginalEquipmentId = EM.ID
							Inner Join TaskClassificationGroup TG WITH(NOLOCK) on EM.WorkcenterTypeId = TG.WorkcenterTypeId
							INNER join TicketAttribute TA WITH(NOLOCK) on TG.TicketAttributeId = TA.ID
							inner join TicketAttributeValues_temp TAV WITH(NOLOCK) on TAV.Name = TA.Name and TAV.TicketId = TTT.ticketId
				Where TTT.IsComplete = 0
				group by TTT.ticketId, EM.WorkcenterTypeId , EM.WorkCenterName ,TAV.Name
				)

				Select  TicketId, WorkcenterTypeId,UPPER( WorkCenterName)+ '_' + STRING_AGG( Value, '_') within group (order by [Name] asc)  as taskClassification
				Into #TaskClassifications
				from
				taskGroup
				group by TicketId,WorkcenterTypeId,WorkCenterName

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


			-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Generating master roll numbers'; SET @startTime = GETDATE();

		Begin TRY
			
		; with currentTaskStatus as (

		Select TCS.*, CASE WHEN firstScan IS NOT NULL THEN 1 ELSE 0 END as TaskStarted 
		from TicketTask_temp TTT WITH(NOLOCK)
		Inner join EquipmentMaster  EM WITH(NOLOCK) on TTT.OriginalEquipmentId =  EM.ID
		Inner join #TimeCardScans TCS on TTT.TicketId = TCS.TicketId and EM.WorkCenterName = TCS.WorkCenterName
		--Where TTT.IsComplete = 0
		
		),
		
		UniqueMasterRolls as (
			Select Distinct sr.MasterRollNumber
			From #ScheduleReport sr
			Left JOIN EquipmentMaster em WITH(NOLOCK) on sr.EquipmentId=em.ID
			Left JOIN TicketMaster tm WITH(NOLOCK) on sr.SourceTicketId=tm.SourceTicketId
			Left Join TicketTask_temp tt WITH(NOLOCK) on sr.TaskName=tt.TaskName and tm.ID=tt.TicketId
			Left Join currentTaskStatus cts on tm.ID=cts.TicketId and em.WorkCenterName=cts.WorkCenterName
			Where (tt.IsComplete = 1 OR (CTS.TaskStarted IS NOT NULL AND CTS.TaskStarted = 1) OR sr.MasterRollNumber Like '%printed%') and sr.MasterRollNumber IS NOT NULL
		),

		MasterRolls as (
		
			Select  	case when (SR.masterRollNumber like '%PRINTED%') 
					then SR.masterRollNumber
					else 'PRINTED_' + SR.masterRollNumber + '_' + CAST((SELECT SYSDATETIMEOFFSET() AT TIME ZONE (SELECT CV.VALUE 
																		FROM ConfigurationValue CV 
																		INNER JOIN ConfigurationMaster CM ON CV.ConfigId = CM.Id
																		WHERE CM.Name = 'Timezone')) AS VARCHAR)
					end as masterRollNo,
					sr.MasterRollNumber as OriginalMasterRollNumber,
					TTT.TicketId as TicketId,
					EM.WorkCenterName as WorkcenterName
			from 
			TicketTask_temp TTT  WITH(NOLOCK)
			Inner join TicketMaster TM WITH(NOLOCK) on TTT.TicketId  =  TM.ID
			Inner join EquipmentMaster EM WITH(NOLOCK) on EM.Id =  ttt.OriginalEquipmentId
			INNER JOIN EquipmentMaster EM2 WITH(NOLOCK) on em.WorkcenterTypeId = em2.WorkcenterTypeId
			Inner join #ScheduleReport SR WITH(NOLOCK) on TM.SourceTicketId =  SR.SourceTicketId and SR.EquipmentId = EM2.ID
			left JOIN currentTaskStatus CTS WITH(NOLOCK) on CTS.TicketId =  TTT.TicketId and CTS.WorkCenterName = EM.WorkCenterName
			Where sr.MasterRollNumber in (Select MasterRollNumber From UniqueMasterRolls)
		
		)

		Select TicketId,WorkcenterName, Min(masterRollNo) as MasterRollNumber, MIN(OriginalMasterRollNumber) as OriginalMasterRollNumber into #MasterRollNumbers
		from MasterRolls 
		Group by TicketId, WorkcenterName

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


		-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Generating Master Roll classifications'; SET @startTime = GETDATE();

		Begin TRY	


		;with masterRollGroup as (
				select  TTT.ticketId as TicketId, 
				EM.WorkcenterTypeId as WorkcenterTypeId,
				EM.WorkCenterName as WorkCenterName, 
				TAV.Name as Name  ,
				Max(TAV.Value) as Value
				from TicketTask_temp TTT WITH(NOLOCK)
							Inner Join EQuipmentMaster EM WITH(NOLOCK) on TTT.OriginalEquipmentId = EM.ID
							Inner Join MasterRollClassificationGroup TG WITH(NOLOCK) on EM.WorkcenterTypeId = TG.WorkcenterTypeId
							INNER join TicketAttribute TA WITH(NOLOCK) on TG.TicketAttributeId = TA.ID
							inner join TicketAttributeValues_temp TAV WITH(NOLOCK) on TAV.Name = TA.Name and TAV.TicketId = TTT.TicketId
				group by TTT.ticketId, EM.WorkcenterTypeId , EM.WorkCenterName ,TAV.Name
				),
				OriginalMasterRollClassification as (
					Select  TicketId, WorkcenterTypeId,WorkcenterName,
					UPPER( WorkCenterName)+ '_' + STRING_AGG( Value, '_')  within group (order by [Name] asc) as MasterRollClassification
			--	Into #MasterRollClassifications
				from
				masterRollGroup
				group by TicketId,WorkcenterTypeId,WorkCenterName
				) --- Creates actual master roll classification strings
				
				---- Get the Printed master roll number from tickets which have been started already or completed
				select Distinct OMR.TicketId ,MasterRollClassification, MRN.MasterRollNumber ,MRN.OriginalMasterRollNumber, OMR.WorkcenterName
				Into #TempMasterRollClassification
				from OriginalMasterRollClassification OMR 
				left join #MasterRollNumbers MRN  on  OMR.TicketId = MRN.TicketId AND OMR.WorkCenterName = MRN.WorkcenterName

				--- Group masterrollclassfication with master roll number
				;with MasterRollNumberGroup as (
					
				select OriginalMasterRollNumber , MIN(MasterRollNumber) as ActualMasterRollNumber
					from #TempMasterRollClassification 
					where MasterRollNumber Is not null 
					 AND OriginalMasterRollNumber IS NOT NULL
					group by OriginalMasterRollNumber  -- Added grouping by master roll number.

				)

				update TMRC set TMRC.MasterRollNumber = MRNG.ActualMasterRollNumber
				from #TempMasterRollClassification TMRC
				inner join MasterRollNumberGroup MRNG 
				on TMRC.OriginalMasterRollNumber = MRNG.OriginalMasterRollNumber  --Join on original master roll

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


		IF @IsError = 0	
	  	BEGIN
		--SET @blockName = 'Update Ticket Task Temp'; SET @startTime = GETDATE();

			BEGIN TRY	

				UPDATE ttt
					SET ttt.taskclassification = tc.TaskClassification,
					ttt.MasterRollNumber = tmc.MasterRollNumber,
					ttt.MasterRollClassification = tmc.MasterRollClassification  
					FROM TicketTask_temp TTT
					Inner Join EQuipmentMaster EM WITH(NOLOCK) on TTT.OriginalEquipmentId = EM.ID
					INNER JOIN TicketMaster TM With(nolock) on ttt.TicketId = tm.ID
					LEFT JOIN #TaskClassifications TC on tc.WorkcenterTypeId = EM.WorkcenterTypeId and tc.TicketId = TTT.TicketId
					LEFT JOIN #TempMasterRollClassification TMC on tmc.WorkCenterName=em.WorkCenterName and tmc.TicketId=ttt.TicketId
			END TRY
				BEGIN CATCH
		--		==================================[Do not change]================================================
					SET @IsError = 1; Rollback;
					SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
				END CATCH
			
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

	drop table if exists #ScheduleReport
	drop table if exists #MasterRollClassifications
	drop table if exists #TaskClassifications
	drop table if exists #TimeCardScans
	drop table if exists #TempMasterRollClassification
	drop table if exists #MasterRollNumbers
	drop table if exists #TicketStockFirstAvailable
	drop table if exists #Tickets
					   		
	
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