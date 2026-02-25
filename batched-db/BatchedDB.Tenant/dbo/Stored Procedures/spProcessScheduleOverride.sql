CREATE PROCEDURE [dbo].[spProcessScheduleOverride]
	@overrides udt_ScheduleOverride ReadOnly,
	@isUpdated bit  = 0,
	@isScheduled bit = 0,
	@isDeleted bit = 0,
	@ModifiedDate datetime,
	@ModifiedBy nvarchar(100)
AS
BEGIN

BEGIN TRY
    BEGIN TRANSACTION
			
			DECLARE @TicketId varchar(36)
			DECLARE @SourceTicketId varchar(510)
			DECLARE @ForcedGroupName varchar(510)
			DECLARE @TotalSourceTicketForcedGroupCount int
			DECLARE @RemainingForcedGroupTicketCount int
			DECLARE @TotalOverrideTicketCount int
			DECLARE @autoUpdateRouteTimeEnabled bit = 0


			select Top 1 @TicketId=TicketId from @overrides
			select @SourceTicketId = SourceTicketId from TicketMaster where ID = @TicketId
			select Top 1 @ForcedGroupName = ForcedGroup from ScheduleReport where SourceTicketId = @SourceTicketId

			select @TotalSourceTicketForcedGroupCount = COUNT(distinct SourceTicketId) from ScheduleReport where ForcedGroup=@ForcedGroupName
			select @TotalOverrideTicketCount = COUNT(distinct TicketId) from @overrides
			set @RemainingForcedGroupTicketCount = @TotalSourceTicketForcedGroupCount - @TotalOverrideTicketCount

			IF(@isScheduled=0 AND @RemainingForcedGroupTicketCount=1)
			BEGIN
				update ScheduleReport
				set ForcedGroup=null,ModifiedOn =@ModifiedDate
				where ForcedGroup=@ForcedGroupName
			END

			SET @autoUpdateRouteTimeEnabled = CASE WHEN EXISTS(SELECT CV.Value 
																	 FROM ConfigurationMaster CM 
																	 INNER JOIN ConfigurationValue CV 
																	 ON CM.Id = CV.ConfigId 
																	 WHERE CM.Name = 'EnableAutoUpdateRouteTime' 
																	 AND CV.Value = 'True')
													   THEN 1 ELSE 0
													END

			if(@isUpdated = 1) ---- In case ticket movement is done between production ready tickets and scheduled list
			Begin
				UPDATE SO 
					set
						SO.EquipmentId = OS.EquipmentId,
						SO.StartsAt = OS.StartsAt,
						SO.EndsAt = OS.EndsAt,
						SO.EquipmentName = EM.Name
					from ScheduleOverride SO 
					inner join @overrides OS on SO.TicketId = OS.TicketId and SO.TaskName = OS.TaskName
					left join EquipmentMaster EM on EM.id = OS.EquipmentId
					 
					----- Update unassigned jobs
			   Update UA Set
				 IsProductionReady = 
			
						 CASE
						 
						 WHEN @isScheduled = 1 --- Manually scheduled
						 THEN
												   CASE WHEN UA.IsProductionReady = 1 THEN 1 
												   WHEN EM.SourceEquipmentId IS NULL THEN 1 
												   WHEN EM.SourceEquipmentId IS NOT NULL and UA.PressNumber = EM.SourceEquipmentId THEN 1
												   ELSE 0 END
						  ELSE					 --- Manually unscheduled
						  
											      0 END
			
			   from 
					@overrides SO 
					inner join TicketMaster TM on SO.TicketId = TM.ID 
					INNER JOIN UnassignedJobs UA on TM.SourceTicketId =  UA.Number and SO.TaskName = UA.TaskName
					left join EquipmentMaster EM on SO.EquipmentId = EM.Id
			End
			
			
			if(@isUpdated = 0) --- Means this is created 1) Either ticket is scheduled or unscheduled
			Begin
			
			    ---- Ticket is unscheduled manually and again rescheduled for unscheduled list - Fresh data required
			    delete from ScheduleOverride where TicketId in (select distinct TicketId from @overrides) 
			
			---- Insert into overrides table
			    INSERT INTO [dbo].[ScheduleOverride] ([ID],[TicketId],[Number],[TaskName],[EquipmentId],[EquipmentName],[StartsAt],[EndsAt],[WorkcenterId],[IsScheduled],[Notes],[CreatedOn],[ModifiedOn])
				SELECT 
				NEWID(),
				SO.TicketId,
				TM.SourceTicketId,
				SO.TaskName,
				EM.ID,
				EM.SourceEquipmentId,
				SO.StartsAt,
				-- DATEADD(MINUTE,CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END,SO.StartsAt),
				CASE
						WHEN @autoUpdateRouteTimeEnabled = 1 AND FR.TicketId IS NOT NULL AND FR.TaskId IS NOT NULL
							THEN CASE 
									WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN DATEADD(MINUTE, 1, SO.StartsAt) 
									ELSE DATEADD(MINUTE, ceiling(FR.EstHoursBySpeed * 60), SO.StartsAt)
								  END
							  
						ELSE CASE
								WHEN ISNULL(TT.EstTotalHours, 0) = 0 THEN DATEADD(MINUTE, 1, SO.StartsAt) 
								ELSE DATEADD(MINUTE, ceiling(TT.EstTotalHours * 60), SO.StartsAt)
							 END
				END,
				EM.WorkcenterTypeId,
				@isScheduled,---- 0 or 1 has to be inserted in this table
				SO.Notes,
				GETUTCDATE(),
				GETUTCDATE()
				FROM 
				@overrides SO 
				INNER JOIN TicketMaster TM on SO.TicketId = TM.ID
				INNER JOIN TicketTask TT on SO.TicketId = TT.TicketId and SO.TaskName = TT.TaskName
				LEFT JOIN EquipmentMaster EM on SO.EquipmentId = EM.Id
				LEFT JOIN FeasibleRoutes FR on FR.TicketId = TT.TicketId AND FR.TaskId = TT.Id AND FR.EquipmentId = SO.EquipmentId
			
			
			
			----- Update unassigned jobs
			    Update UA Set
					 IsProductionReady = 
			
					 CASE
					 
					 WHEN @isScheduled = 1 --- Manually scheduled
					 THEN
											   CASE WHEN UA.IsProductionReady = 1 THEN 1 
											   WHEN EM.SourceEquipmentId IS NULL THEN 1 
											   WHEN EM.SourceEquipmentId IS NOT NULL and UA.PressNumber = EM.SourceEquipmentId THEN 1
											   ELSE 0 END
					  ELSE					 --- Manually unscheduled
					  
										      0 END
			
			    from 
				@overrides SO 
				inner join TicketMaster TM on SO.TicketId = TM.ID 
				INNER JOIN UnassignedJobs UA on TM.SourceTicketId =  UA.Number and SO.TaskName = UA.TaskName
				left join EquipmentMaster EM on SO.EquipmentId = EM.Id
			
			-- Insert the tickets which have Start time mentioned directly into Schedule Report - Assumption validations are taken care by the consuming application
			-- Subject to what allan says about inserting these tasks post adjustments / validations
			-- In case this logic stays here Inserting into Schedule report while ticket movement is also something wht we are looking at
				
			if(@isScheduled = 0)
				Begin
				
					Delete from ScheduleReport where SourceTicketId = (select distinct TM.SourceTicketId from @overrides o inner join TicketMaster TM on o.TicketId = TM.ID)
				
				End
			
			if(@isScheduled = 1) --- Insert records in scheduled report table which have start times populated
				Begin
				
					INSERT INTO [dbo].[ScheduleReport] ([ID],[EquipmentId],[SourceTicketId],[TaskName],[StartsAt],[EndsAt],[ChangeoverMinutes],[TaskMinutes],[IsPinned],[FeasibilityOverride],[IsUpdated],[IsCalculated],[MasterRollNumber],[PinType],[ChangeoverCount],[ChangeoverDescription],[CreatedOn],[ModifiedOn])
					Select 
					NEWID(),
					EM.ID,
					TM.SourceTicketId,
					SO.TaskName,
					SO.StartsAt,
					--CASE
					--	WHEN UA.TaskEstimatedMinutes IS NOT NULL THEN DATEADD(MINUTE, UA.TaskEstimatedMinutes, SO.StartsAt)
					--	ELSE DATEADD(MINUTE, (TT.EstTotalHours*60), SO.StartsAt)
					--END,
					-- if  @autoUpdateRouteTimeEnabled is enable then use EstHoursBySpeed from feasible route else use existing logic
					CASE
						WHEN @autoUpdateRouteTimeEnabled = 1 
							THEN CASE 
									WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN DATEADD(MINUTE, 1, SO.StartsAt) 
									ELSE DATEADD(MINUTE, FR.EstHoursBySpeed * 60, SO.StartsAt)
								  END
							  
						ELSE CASE
								WHEN UA.TaskEstimatedMinutes IS NOT NULL THEN DATEADD(MINUTE, UA.TaskEstimatedMinutes, SO.StartsAt)
								ELSE DATEADD(MINUTE, (TT.EstTotalHours * 60), SO.StartsAt)
							 END
					END,
					0,
					--CASE
					--	WHEN UA.TaskEstimatedMinutes IS NOT NULL THEN UA.TaskEstimatedMinutes
					--	ELSE (TT.EstTotalHours*60)
					--END,

					-- if  @autoUpdateRouteTimeEnabled is enable then use EstHoursBySpeed from feasible route else use existing logic
					CASE
						  WHEN @autoUpdateRouteTimeEnabled = 1
							   THEN CASE 
										WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN 1 
										ELSE (FR.EstHoursBySpeed * 60)
									END
							   ELSE CASE
									WHEN UA.TaskEstimatedMinutes IS NOT NULL THEN UA.TaskEstimatedMinutes
									ELSE (TT.EstTotalHours * 60)
							   END	
					END,
					1,
					CASE
						WHEN FR.RouteFeasible = 0 THEN 1
						ELSE 0
					END,
					1,
					null,
					CASE
						WHEN UA.MasterRollNumber IS NOT NULL THEN UA.MasterRollNumber
						ELSE NULL
					END,
					'time',
					null,
					null,
					@ModifiedDate,
					@ModifiedDate
					from 
					@overrides SO 
					inner join TicketMaster TM on SO.TicketId = TM.ID
					inner join EquipmentMaster EM on SO.EquipmentId = EM.Id
					LEFT JOIN UnassignedJobs UA on TM.SourceTicketId =  UA.Number and SO.TaskName = UA.TaskName and EM.SourceEquipmentId = UA.PressNumber
					LEFT JOIN TicketTask TT on TM.ID = TT.TicketId and SO.TaskName = TT.TaskName
					LEFT JOIN FeasibleRoutes FR on FR.TicketId = SO.TicketId and FR.EquipmentId = SO.EquipmentId and FR.TaskId = TT.Id

					Where SO.StartsAt IS NOT NULL

					--Identify overriden task for which route was infeasible
					SELECT 
							SO.ticketId,
							TT.Id as TaskId,
							SO.EquipmentId,
							FR.EstHoursBySpeed
					into #infeasibleRoutesOverride
					from @overrides SO 
					INNER JOIN tickettask TT on SO.TicketId = TT.TicketId and TT.TaskName = so.TaskName 
					INNER JOIN EQUIPMENTMASTER EM ON EM.ID = SO.EquipmentId
					INNER JOIN FeasibleRoutes FR on so.TicketId =  FR.TicketId and tt.id = fr.TaskId AND FR.EquipmentId = SO.EquipmentId
					WHERE FR.RouteFeasible = 0


					--Insert into unassinged jobs an entry for the recently updated feasible route

					--Identifying Last Time Card Scan
					SELECT 
						   TI.TicketId 
						 , EM.WorkCenterName
						 , MIN(StartedOn) as firstScan
						 , CASE 
							  WHEN MAX(CompletedAt) is not null  THEN MAX(CompletedAt)
							  ELSE MAX(StartedOn)
						   END as lastScan
					INTO #TimeCardScans
					FROM TimecardInfo TI
					INNER JOIN EquipmentMaster EM on TI.EquipmentId = EM.ID
					WHERE 
					TicketId IN (SELECT DISTINCT TicketId from #infeasibleRoutesOverride)
					GROUP BY TI.TicketId , EM.WorkCenterName

					--Identifying Task classification
					;WITH taskGroup as (
						select  FR.ticketId as TicketId, 
						EM.WorkcenterTypeId as WorkcenterTypeId,
						EM.WorkCenterName as WorkCenterName, 
						TAV.Name as Name  ,
						Max(TAV.Value) as Value
						from #infeasibleRoutesOverride FR
									Inner Join EQuipmentMaster EM on FR.EquipmentId = EM.ID
									Inner Join TaskClassificationGroup TG on EM.WorkcenterTypeId = TG.WorkcenterTypeId
									INNER join TicketAttribute TA on TG.TicketAttributeId = TA.ID
									INNER JOIN TicketAttributeValues TAV on TAV.Name = TA.Name and TAV.TicketId = FR.TicketId
						group by FR.ticketId, EM.WorkcenterTypeId , EM.WorkCenterName ,TAV.Name
						)

						Select  TicketId, WorkcenterTypeId,UPPER( WorkCenterName)+ '_' + STRING_AGG( Value, '_')
						within group (order by [Name] asc)  as taskClassification
						Into #TaskClassifications
						from taskGroup
						group by TicketId,WorkcenterTypeId,WorkCenterName

					DECLARE @HoursToAdd int = 0

					 Select 
						@HoursToAdd = ISNULL( CV.Value,0) 
					 from ConfigurationMaster CM 
						LEFT JOIN ConfigurationValue CV on CM.Id = CV.ConfigId
					 where Name = 'StockArrivalHours'

					Select TS.TicketId , DATEADD(hour,@HoursToAdd, cast(min(POM.PromisedDeliveryDate) as datetime))as MinStartTime
						into #StockArrivalTimes
					from TicketStock TS
					INNER JOIN #infeasibleRoutesOverride IFR ON IFR.TicketId = TS.ticketid 
			        INNER JOIN TicketPreProcess TPP on TS.TicketId = TPP.TicketId
					INNER JOIN StockMaterial SM on SM.Id = TS.StockMaterialId and TS.Sequence = 2
					INNER JOIN PurchaseOrderMaster POM on SM.Id = POM.StockMaterialId AND 
								POM.PurchaseOrderType = 'Stock' and POM.IsOpen=1 and 
								PromisedDeliveryDate<>'1970-01-01' 
								and PromisedDeliveryDate IS NOT NULL 
								and PromisedDeliveryDate >= DATEADD(DAY, -180, getdate())
					Where TPP.StockReceived in ('Ord')
					group by TS.TicketId
					
					INSERT INTO UnassignedJobs ( [ID],[RouteFeasible],[CustomerNum],[TaskName],[TaskDueTime],[Number],[DoublePass_ReinsertionFlag],[TaskEstimatedHours],[Press],[Pass],[Priority],[WorkcenterName],[LastScan],[ShipTime],[TicketPoints],[LinearLengthCalc],[DoublePassJob],[DueDateBucket],[MasterRollNumber],[TaskDueTimeReference],[TaskEstimatedMinutes],[TaskIndex],[PressNumber],[HighPriority],[TaskClassification],[MasterRollClassification],[JobFirstAvailable],[CreatedOn],[ModifiedOn],[IsProductionReady], [Lag],[Delay], [DependentSourceTicketId])
						SELECT 
							NEWID(),
							1 ,
							TM.SourceCustomerId ,
							TT.TaskName,
							TT.EstMaxDueDateTime ,
							TM.SourceTicketId ,
							ISNULL(TT.DoublePass_ReInsertionFlag,0),
							-- TT.EstTotalHours,
							-- if @autoUpdateRouteTimeEnabled  is true then use value from FeasibleRoutes_Incr table else TicketTask table
							CASE 
								WHEN @autoUpdateRouteTimeEnabled = 1 
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
							TCS.lastScan, 
							TS.ShipByDateTime,
							ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) ,
							TD.EsitmatedLength,
							TT.DoublePassJob,
							NULL, --- DueDate -- Since we dont have this value keeping it as null
							NULL,-- MasterRollNumber Since we dont have this value keeping it as null
							MWC.TimeIndex, 
							-- CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END,
							-- if @autoUpdateRouteTimeEnabled  is true then use value from FeasibleRoutes_Incr table else TicketTask table
							CASE 
								WHEN @autoUpdateRouteTimeEnabled = 1 
									 THEN CASE 
											WHEN ISNULL(FR.EstHoursBySpeed, 0) = 0 THEN 1 
											ELSE CEILING(FR.EstHoursBySpeed * 60) 
										  END
								ELSE CASE 
											WHEN TT.EstTotalHours = 0 THEN 1 
											ELSE CEILING(TT.EstTotalHours * 60) 
									 END
							END,
							CASE WHEN TT.TaskName = 'SHEETER' THEN 6 ELSE TT.[Sequence] END ,
							EMroute.SourceEquipmentId ,
							CASE when TM.SourcePriority Like '%Urgent%' OR TM.SourcePriority Like '%High%' OR TM.SourcePriority Like '%Rush%' then 1 else 0 end,--- Standardised implementation for Calculating High priority
							TC.taskClassification ,
							NULL,-- MasterRollClassification Since we dont have this value keeping it as null
							Case When ISNULL(MWC2.TimeIndex, 0) < 0 Then 0 Else ISNULL(MWC2.TimeIndex, 0) End as jobFirstAvailable,
							Getutcdate(),
							getutcdate(),
							CASE 
										WHEN SO.IsScheduled is null then TT.IsProductionReady
											WHEN SO.IsScheduled = 1 --- Manually scheduled
											THEN
												CASE WHEN TT.IsProductionReady = 1 THEN 1 
													WHEN SO.EquipmentId IS NULL THEN 1 
													WHEN SO.EquipmentId IS NOT NULL and FR.EquipmentId = SO.EquipmentId THEN  1
											ELSE 0 END
							ELSE --- Manually unscheduled
							0 END,
							TT.Lag,
							TT.Delay,
							TT.DependentSourceTicketId
						from 
						#infeasibleRoutesOverride FR
						inner join TicketMaster TM  ON FR.TicketId = TM.ID
						inner join TicketTask TT ON FR.TaskId = TT.Id
						inner Join EquipmentMaster EMBase ON TT.OriginalEquipmentId = EMBase.ID
						inner join EquipmentMaster EMroute ON FR.EquipmentId = EMroute.ID
						inner join TicketDimensions TD on TD.TicketId = TM.ID
						inner join TicketShipping TS on TS.TicketId = TM.ID
						inner join TicketScore TSC on TSC.TicketId = TM.ID
						left join ScheduleOverride SO on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
						left join #StockArrivalTimes SAT on TM.ID = SAT.TicketId
						left join MinutewiseCalendar MWC on TT.EstMaxDueDateTime = MWC.TheDateTime
						left join MinutewiseCalendar MWC2 on MWC2.TheDateTime = SAT.MinStartTime
						left join #TaskClassifications TC on EMroute.WorkcenterTypeId = TC.WorkcenterTypeId and FR.TicketId = TC.TicketId
						left join #TimeCardScans TCS on FR.TicketId = TCS.TicketId and TCS.WorkCenterName = EMBase.WorkCenterName

				END
			End


			IF EXISTS(SELECT TOP 1 * FROM @overrides WHERE TicketId IS NOT NULL AND Notes IS NOT NULL)
			BEGIN
				DECLARE @currentUtcDateTime datetime = GETUTCDATE();

				INSERT INTO [dbo].[TicketGeneralNotes] ([ID], [TicketId], [Notes], [CreatedOnUTC], [ModifiedOnUTC], [CreatedBy])
					SELECT TOP 1 NEWID(), TicketId, Notes, @currentUtcDateTime, @currentUtcDateTime, @ModifiedBy
					FROM @overrides
			END


select 1 AS IsSuccessfull ,  'tbl_status' AS __dataset_tableName
COMMIT TRANSACTION;

END TRY
BEGIN CATCH 

ROLLBACK TRANSACTION;

 select 0 AS IsSuccessfull ,  'tbl_status' AS __dataset_tableName

END CATCH

DROP TABLE IF EXISTS #infeasibleRoutesOverride;
DROP TABLE IF EXISTS #StockArrivalTimes
DROP TABLE IF EXISTS #TaskClassifications
DROP TABLE IF EXISTS  #TimeCardScans

END
