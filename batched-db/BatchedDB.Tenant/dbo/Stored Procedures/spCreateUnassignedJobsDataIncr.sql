CREATE PROCEDURE [dbo].[spCreateUnassignedJobsDataIncr]
	@TicketsData udt_UnassignedJobs readonly,
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spCreateUnassignedJobsData',
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
	DECLARE @autoUpdateRouteTimeEnabled bit = 0; 
--  ====================================================

	BEGIN TRANSACTION;




	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Generating JobFirstAvailable Index'; SET @startTime = GETDATE();

		Begin TRY

			SET @ticketStockAvailabilityEnabled = CASE WHEN EXISTS(SELECT CV.Value 
																	 FROM ConfigurationMaster CM 
																	 INNER JOIN ConfigurationValue CV 
																	 ON CM.Id = CV.ConfigId 
																	 WHERE CM.Name = 'EnableAutomaticStockAvailability' 
																	 AND CV.Value = 'True')
													   THEN 1 ELSE 0
													END

			SET @autoUpdateRouteTimeEnabled = CASE WHEN EXISTS(SELECT CV.Value 
																	 FROM ConfigurationMaster CM 
																	 INNER JOIN ConfigurationValue CV 
																	 ON CM.Id = CV.ConfigId 
																	 WHERE CM.Name = 'EnableAutoUpdateRouteTime' 
																	 AND CV.Value = 'True')
													   THEN 1 ELSE 0
													END


		;WITH facilityWorkcenterConfig AS 
		(
			SELECT 
				DISTINCT em.FacilityId, em.WorkcenterTypeId,
				CASE 
					WHEN wc.WorkcenterTypeId IS NULL OR wc.IsFirstAvailableTimeEnforced = 1 THEN 1 ELSE 0
				END AS IsFirstAvailableTimeEnforced
			FROM EquipmentMaster em
			INNER JOIN StockAvailabilityConfiguration sac
				ON sac.FacilityId = em.FacilityId
			LEFT JOIN WorkcenterStockAvailabilityConfiguration wc
				ON sac.Id = wc.StockAvailabilityConfigId AND em.WorkcenterTypeId = wc.WorkcenterTypeId
		)

		SELECT 
			DISTINCT tsa.TicketId, 
			CASE fwc.IsFirstAvailableTimeEnforced 
				WHEN 1 THEN mc.TimeIndex 
				WHEN 0 THEN 0
			END AS TimeIndex, 
			tsa.TaskName
			INTO #TicketStockFirstAvailable
			FROM 
			(
				SELECT 
					TicketId, 
					FirstAvailableTime,
					TaskName,
					FacilityId,
					ROW_NUMBER() OVER (PARTITION BY TicketId, TaskName ORDER BY FirstAvailableTime DESC) AS RNO
				FROM TicketStockAvailability_temp
				WHERE FirstAvailableTime IS NOT NULL
			) AS tsa
			INNER JOIN TicketTask_temp tt 
				ON tt.TicketId = tsa.TicketId AND tt.TaskName = tsa.TaskName
			INNER JOIN EquipmentMaster em 
				ON tt.OriginalEquipmentId = em.Id AND em.FacilityId = tsa.FacilityId 
			INNER JOIN facilityWorkcenterConfig fwc 
				ON em.FacilityId = fwc.FacilityId AND em.WorkcenterTypeId = fwc.WorkcenterTypeId
			LEFT JOIN MinutewiseCalendar mc 
				ON tsa.FirstAvailableTime = mc.TheDateTime
			WHERE tsa.RNO = 1
			
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


	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Deleting unassigned jobs table'; SET @startTime = GETDATE();

		Begin TRY	

			truncate table UnassignedJobs_Incr

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

	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Inserting into unassigned jobs'; SET @startTime = GETDATE();

		Begin TRY		

		INSERT INTO UnassignedJobs_Incr ( [ID],[RouteFeasible],[CustomerNum],[TaskName],[TaskDueTime],[Number],[DoublePass_ReinsertionFlag],[TaskEstimatedHours],[Press],[Pass],[Priority],[WorkcenterName],[LastScan],[ShipTime],[TicketPoints],[LinearLengthCalc],[DoublePassJob],[DueDateBucket],[MasterRollNumber],[TaskDueTimeReference],[TaskEstimatedMinutes],[TaskIndex],[PressNumber],[HighPriority],[TaskClassification],[MasterRollClassification],[JobFirstAvailable],[CreatedOn],[ModifiedOn],[IsProductionReady], [Lag],[Delay], [DependentSourceTicketId], [TicketTaskDataId], [EnforceTaskDependency])
		select 
				NEWID(),
				1 ,
				TM.SourceCustomerId ,
				TT.TaskName,
				TT.EstMaxDueDateTime ,
				TM.SourceTicketId ,
				ISNULL(TT.DoublePass_ReInsertionFlag,0),
				--TT.EstTotalHours,
				-- if @autoUpdateRouteTimeEnabled  is true then use value from FeasibleRoutes_Incr table else TicketTask table
				CASE 
                    WHEN @autoUpdateRouteTimeEnabled = 1 AND TTO.TicketId IS NULL AND TTO.TaskName IS NULL
                         THEN CASE 
                                WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN 1 
                                ELSE FR.EstHoursBySpeed 
                              END
                    ELSE CASE 
                                WHEN TT.EstTotalHours = 0 THEN 1 
                                ELSE TT.EstTotalHours 
                         END
                END,
				EMBase.SourceEquipmentId,
				TT.Pass,
				TM.SourcePriority,
				EMroute.WorkCenterName,
				NULL,
				TS.ShipByDateTime,
				ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) ,
				TD.EsitmatedLength,
				TT.DoublePassJob,
				TDD.DueDateBucket, --- Calculated from rules parameter -- Due Date bucket
				TT_Temp.MasterRollNumber,
				MWC.TimeIndex, 
				-- CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END,
				-- if @autoUpdateRouteTimeEnabled  is true then use value from FeasibleRoutes_Incr table else TicketTask table
				CASE 
                    WHEN @autoUpdateRouteTimeEnabled = 1 AND TTO.TicketId IS NULL AND TTO.TicketId.TaskName IS NULL
                         THEN CASE 
                                WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN 1 
                                ELSE CEILING(FR.EstHoursBySpeed * 60) 
                              END
                    ELSE CASE 
                                WHEN TT.EstTotalHours = 0 THEN 1 
                                ELSE CEILING(TT.EstTotalHours * 60) 
                         END
                END as EstTotalMins,
				CASE WHEN TT.TaskName = 'SHEETER' THEN 6 ELSE TT.[Sequence] END ,
				EMroute.SourceEquipmentId ,
				CASE when TM.SourcePriority Like '%Urgent%' OR TM.SourcePriority Like '%High%' OR TM.SourcePriority Like '%Rush%' then 1 else 0 end,--- Standardised implementation for Calculating High priority
				TT_Temp.taskClassification ,
				TT_Temp.MasterRollClassification,
				CASE @ticketStockAvailabilityEnabled
					WHEN 1 THEN (CASE 
									WHEN ISNULL(TSFA.TimeIndex, 0) < 0 
									THEN 0 ELSE ISNULL(TSFA.TimeIndex, 0) 
								 END)
					WHEN 0 THEN 0 -- If ASP is not enabled then select 0 TimeIndex
					END as jobFirstAvailable,
				Getutcdate(),
				getutcdate(),
				CASE 
							WHEN SO.IsScheduled is null then TT_Temp.IsProductionReady
							 WHEN SO.IsScheduled = 1 --- Manually scheduled
							 THEN
								   CASE WHEN TT_Temp.IsProductionReady = 1 THEN 1 
									 WHEN SO.EquipmentId IS NULL THEN 1 
									 WHEN SO.EquipmentId IS NOT NULL and FR.EquipmentId = SO.EquipmentId THEN  1
							 ELSE 0 END
			    ELSE --- Manually unscheduled
		        0 END,
				TT.Lag,
				TT.Delay,
				TT.DependentSourceTicketId,
				TTD.ID,
				TT.EnforceTaskDependency
		from 
		FeasibleRoutes_Incr FR
				inner join TicketMaster TM  ON FR.TicketId = TM.ID
				inner join TicketTask_Incr TT ON FR.TaskId = TT.Id
				inner join TicketTask_Temp TT_Temp on FR.TaskId = TT_Temp.ID --ensure data is pulled from tickettask_temp for master roll, production ready fields
				inner Join EquipmentMaster EMBase ON TT.OriginalEquipmentId = EMBase.ID
				inner join EquipmentMaster EMroute ON FR.EquipmentId = EMroute.ID
				inner join TicketDimensions TD on TD.TicketId = TM.ID
				inner join TicketShipping TS on TS.TicketId = TM.ID
				inner join TicketScore TSC on TSC.TicketId = TM.ID
				left join TicketTaskData ttd on tt.TicketId = ttd.TicketId and tt.TaskName = ttd.TaskName
				left join ScheduleOverride SO on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
				left join @TicketsData TDD on TM.ID = TDD.TicketId
				left join MinutewiseCalendar MWC on TT.EstMaxDueDateTime = MWC.TheDateTime
				left join #TicketStockFirstAvailable TSFA ON FR.TicketId = TSFA.TicketId and TT.TaskName = TSFA.TaskName 
				left join TicketTaskOverride TTO on TT.TicketId = TTO.TicketId and TT.TaskName = TTO.TaskName
				Where FR.RouteFeasible = 1

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


	drop table if exists #MasterRollClassifications
	drop table if exists #TaskClassifications
	drop table if exists #TimeCardScans
	drop table if exists #TempMasterRollClassification
	drop table if exists #MasterRollNumbers
	drop table if exists #TicketStockFirstAvailable
					   		
	
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
