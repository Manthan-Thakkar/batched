CREATE OR ALTER PROCEDURE [dbo].[spCreateUnassignedJobsData]
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
--  ====================================================

	BEGIN TRANSACTION;


			-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Generating Time card scans'; SET @startTime = GETDATE();

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
				TimecardInfo TI Inner join EquipmentMaster EM on TI.EquipmentId = EM.ID
				WHERE 
				TicketId IN (SELECT DISTINCT TicketId from FeasibleRoutes_temp)
				GROUP BY TI.TicketId , EM.WorkCenterName

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
		SET @blockName = 'Generating Task classifications'; SET @startTime = GETDATE();

		Begin TRY	

			

				;with taskGroup as (
				select  FR.ticketId as TicketId, 
				EM.WorkcenterTypeId as WorkcenterTypeId,
				EM.WorkCenterName as WorkCenterName, 
				TAV.Name as Name  ,
				Max(TAV.Value) as Value
				from FeasibleRoutes_temp FR
							Inner Join EQuipmentMaster EM on FR.EquipmentId = EM.ID
							Inner Join TaskClassificationGroup TG on EM.WorkcenterTypeId = TG.WorkcenterTypeId
							INNER join TicketAttribute TA on TG.TicketAttributeId = TA.ID
							inner join TicketAttributeValues_temp TAV on TAV.Name = TA.Name and TAV.TicketId = FR.TicketId
				group by FR.ticketId, EM.WorkcenterTypeId , EM.WorkCenterName ,TAV.Name
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
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


			-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Generating master roll numbers'; SET @startTime = GETDATE();

		Begin TRY
			
		; with currentTaskStatus as (

		Select DISTINCT TCS.*, CASE WHEN firstScan IS NOT NULL THEN 1 ELSE 0 END as TaskStarted 
		from FeasibleRoutes_temp FR
		Inner join EquipmentMaster  EM on FR.EquipmentId =  EM.ID
		Inner join #TimeCardScans TCS on FR.TicketId = TCS.TicketId and EM.WorkCenterName = TCS.WorkCenterName
		
		),
		
		UniqueMasterRolls as (
			Select Distinct sr.MasterRollNumber
			From ScheduleReport sr
			Left JOIN EquipmentMaster em on sr.EquipmentId=em.ID
			Left JOIN TicketMaster tm on sr.SourceTicketId=tm.SourceTicketId
			Left Join TicketTask_temp tt on sr.TaskName=tt.TaskName and tm.ID=tt.TicketId
			Left Join currentTaskStatus cts on tm.ID=cts.TicketId and em.WorkCenterName=cts.WorkCenterName
			Where (tt.IsComplete = 1 OR (CTS.TaskStarted IS NOT NULL AND CTS.TaskStarted = 1) OR sr.MasterRollNumber Like '%printed%') and sr.MasterRollNumber IS NOT NULL
		),

		MasterRolls as (
		
			Select  	case when (SR.masterRollNumber like '%PRINTED%') 
					then sr.masterRollNumber
					else 'PRINTED_' + SR.masterRollNumber + '_' + CAST((select SYSDATETIMEOFFSET() AT TIME ZONE (Select cv.Value
																				From ConfigurationValue cv
																				INNER JOIN ConfigurationMaster cm on cv.ConfigId = cm.Id
																				Where cm.Name = 'Timezone')) as nvarchar)
					end as masterRollNumber,
					FR.TicketId as TicketId,
					EM.WorkCenterName as WorkcenterName
			from 
			FeasibleRoutes_temp FR 
			Inner join TicketMaster TM on FR.TicketId  =  TM.ID
			Inner join ScheduleReport SR on TM.SourceTicketId =  SR.SourceTicketId and SR.EquipmentId = FR.EquipmentId
			Inner join EquipmentMaster EM on EM.Id =  SR.EquipmentId
			Inner join TicketTask_temp TT on FR.TaskId = TT.Id
			left JOIN currentTaskStatus CTS on CTS.TicketId =  TT.TicketId and CTS.WorkCenterName = EM.WorkCenterName
			Where sr.MasterRollNumber in (Select MasterRollNumber From UniqueMasterRolls)
		
		)

		Select TicketId,WorkcenterName, Min(masterRollNumber) as MasterRollNumber into #MasterRollNumbers
		from MasterRolls 
		Group by TicketId, WorkcenterName

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
		SET @blockName = 'Generating Master Roll classifications'; SET @startTime = GETDATE();

		Begin TRY	


		;with masterRollGroup as (
				select  FR.ticketId as TicketId, 
				EM.WorkcenterTypeId as WorkcenterTypeId,
				EM.WorkCenterName as WorkCenterName, 
				TAV.Name as Name  ,
				Max(TAV.Value) as Value
				from FeasibleRoutes_temp FR
							Inner Join EQuipmentMaster EM on FR.EquipmentId = EM.ID
							Inner Join MasterRollClassificationGroup TG on EM.WorkcenterTypeId = TG.WorkcenterTypeId
							INNER join TicketAttribute TA on TG.TicketAttributeId = TA.ID
							inner join TicketAttributeValues_temp TAV on TAV.Name = TA.Name and TAV.TicketId = FR.TicketId
				group by FR.ticketId, EM.WorkcenterTypeId , EM.WorkCenterName ,TAV.Name
				),
				OriginalMasterRollClassification as (
					Select  TicketId, WorkcenterTypeId,WorkcenterName,UPPER( WorkCenterName)+ '_' + STRING_AGG( Value, '_')  within group (order by [Name] asc) as MasterRollClassification
			--	Into #MasterRollClassifications
				from
				masterRollGroup
				group by TicketId,WorkcenterTypeId,WorkCenterName
				) --- Creates actual master roll classification strings
				
				---- Get the Printed master roll number from tickets which have been started already or completed
				select Distinct OMR.TicketId ,MasterRollClassification, MRN.MasterRollNumber ,OMR.WorkcenterName
				Into #TempMasterRollClassification
				from OriginalMasterRollClassification OMR 
				left join #MasterRollNumbers MRN  on  OMR.TicketId = MRN.TicketId AND OMR.WorkCenterName = MRN.WorkcenterName

				--- Group masterrollclassfication with master roll number
				;with MasterRollNumberGroup as (
				
				select MasterRollClassification , MIN(MasterRollNumber) as ActualMasterRollNumber
				from #TempMasterRollClassification where MasterRollNumber Is not null 
				group by MasterRollClassification

				)

				--- Update null values within group of the master roll classification in original data with printed master roll numbers
				update TMRC set TMRC.MasterRollNumber = MRNG.ActualMasterRollNumber
				from #TempMasterRollClassification TMRC
				inner join MasterRollNumberGroup MRNG on TMRC.MasterRollClassification = MRNG.MasterRollClassification

				--select * from #TempMasterRollClassification

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

			delete from UnassignedJobs_temp

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

		INSERT INTO UnassignedJobs_temp ( [ID],[RouteFeasible],[CustomerNum],[TaskName],[TaskDueTime],[Number],[DoublePass_ReinsertionFlag],[TaskEstimatedHours],[Press],[Pass],[Priority],[WorkcenterName],[LastScan],[ShipTime],[TicketPoints],[LinearLengthCalc],[DoublePassJob],[DueDateBucket],[MasterRollNumber],[TaskDueTimeReference],[TaskEstimatedMinutes],[TaskIndex],[PressNumber],[HighPriority],[TaskClassification],[MasterRollClassification],[JobFirstAvailable],[CreatedOn],[ModifiedOn],[IsProductionReady], [Lag],[Delay], [DependentSourceTicketId], [TicketTaskDataId], [EnforceTaskDependency])
		select 
				NEWID(),
				Case WHEN EMroute.SourceEquipmentId In ('5941', '5942', '5943') and TM.SourceCustomerId Like 'W%' and TC2.StockNum2='B7729' and vrl.RecipeLength < 2500 Then 0
						WHEN EMroute.SourceEquipmentId In ('5941', '5942', '5943') and TM.SourceCustomerId Like 'W%' and TC2.StockNum2='79101' and vrl.RecipeLength < 5000 Then 0
						WHEN EMroute.SourceEquipmentId In ('5941') and TM.SourceCustomerId Not Like 'W%' and (TC2.PantoneOrange + TC2.PantoneGreen) < 2 AND NOT (TC2.StockNum2 = 'SA255' and TC2.Stockwidth2 = 12) and  vrl.RecipeLength < 6500 Then 0
						WHEN EMroute.SourceEquipmentId In ('5942', '5943') and TM.SourceCustomerId Not Like 'W%' and (TC2.PantoneOrange + TC2.PantoneGreen) < 2 and  vrl.RecipeLength < 6500 Then 0
						When EMroute.SourceEquipmentId IN ('5911', '5912', '5915') and ((TC2.PrintWidth <= 12.31
                                                                            --AND TC2.CustomerNum not in ('52')
                                                                            AND TC2.Shape Not Like '%flex%'
                                                                            AND ((TC2.HotFoil + TC2.Reinsertion + TC2.Embossing + TC2.[DoublePass_ReinsertionFlag]) <= 0 OR TC2.GeneralDescr = 'KFC169')
                                                                            AND TC2.StockNum2 <> 'SA036'
                                                                            --AND TC2.WizardFlag <= 0
                                                                            AND TC2.PantoneSilver <= 0)
																			OR (TC2.CustomerNum in ('52') AND TC2.GeneralDescr Like '%ATI018%'))
																			AND vrl.RecipeLength >= 6500 Then 0
						When EMroute.SourceEquipmentId IN ('5941', '5942', '5943') and ((TC2.PrintWidth <= 12.31
                                                                            --AND TC2.CustomerNum not in ('52')
                                                                            AND TC2.Shape Not Like '%flex%'
                                                                            AND ((TC2.HotFoil + TC2.Reinsertion + TC2.Embossing + TC2.[DoublePass_ReinsertionFlag]) <= 0 OR TC2.GeneralDescr = 'KFC169')
                                                                            AND TC2.StockNum2 <> 'SA036'
                                                                            --AND TC2.WizardFlag <= 0
                                                                            AND TC2.PantoneSilver <= 0)
																			OR (TC2.CustomerNum in ('52') AND TC2.GeneralDescr Like '%ATI018%'))
																			AND vrl.RecipeLength >= 10000 Then 0
						When EMroute.SourceEquipmentId IN ('6001') AND vrl.RecipeLength < 10000 Then 0
						Else fr.RouteFeasible
				End ,
				TM.SourceCustomerId ,
				TT.TaskName,
				TT.EstMaxDueDateTime ,
				TM.SourceTicketId ,
				ISNULL(TT.DoublePass_ReInsertionFlag,0),
				TT.EstTotalHours,
				EMBase.SourceEquipmentId,
				TT.Pass,
				TM.SourcePriority,
				EMroute.WorkCenterName,
				TCS.lastScan, 
				TS.ShipByDateTime,
				ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) ,
				TD.EsitmatedLength,
				TT.DoublePassJob,
				TDD.DueDateBucket, --- Calculated from rules parameter -- Due Date bucket
				MC.MasterRollNumber,
				MWC.TimeIndex, 
				round (CASE	When EMroute.SourceEquipmentId='5971' and VARNISH.Value Like '%UV%' Then tt.EstMeters*.3048/(100*.75)--/60.0
						When EMroute.SourceEquipmentId='5971' Then tt.EstMeters*.3048/(30*.75)--/60.0
						When EMroute.SourceEquipmentId='5972' and tt.TaskName='EQUIP' and (VARNISH.Value Like '%soft touch%' OR VARNISH.Value Like '%ST%') Then tt.EstMeters*.3048/(50*.75)--/60.0
						When EMroute.SourceEquipmentId='5972' and tt.TaskName='EQUIP3' and (VARNISH.Value Like '%soft touch%' OR VARNISH.Value Like '%ST%') Then tt.EstMeters*.3048/(170*.75)--/60.0
						When EMroute.SourceEquipmentId='5972' and VARNISH.Value Like '%shrink%' Then tt.EstMeters*.3048/(170*.75)--/60.0
						When EMroute.SourceEquipmentId='5972' and VARNISH.Value Like '%flex%' Then tt.EstMeters*.3048/(50*.75)--/60.0
						When EMroute.SourceEquipmentId='5972' Then tt.EstMeters*.3048/(170*.75)--/60.0
						When EMBase.WorkCenterName Like '%wide web rewind%' Then tt.EstMeters/(500*.75)--/60.0
						When EMBase.WorkCenterName Like '%seam%' Then tt.EstMeters*TD.NumAcross*.3048/(170*.75)--/60.0
						When EMBase.WorkCenterName Like '%inspector%' Then tt.EstMeters*TD.NumAcross*.3048/(125*.75)--/60.0
						When EMroute.SourceEquipmentId Like '%594%' and EMBase.SourceEquipmentId Like '%591%' Then tt.EstTotalHours/2*60.0
						When EMroute.SourceEquipmentId Like '%594%' and EMBase.SourceEquipmentId Like '%6001%' Then tt.EstTotalHours*2*60.0
						When EMroute.SourceEquipmentId Like '%591%' and EMBase.SourceEquipmentId  Like '%594%' Then tt.EstTotalHours*2*60.0
						When EMroute.SourceEquipmentId Like '%591%' and EMBase.SourceEquipmentId  Like '%6001%' Then tt.EstTotalHours*4*60.0
						When EMroute.SourceEquipmentId Like '%6001%' and EMBase.SourceEquipmentId  Like '%591%' Then tt.EstTotalHours/4*60.0
						When EMroute.SourceEquipmentId Like '%6001%' and EMBase.SourceEquipmentId  Like '%594%' Then tt.EstTotalHours/2*60.0
						When EMroute.SourceEquipmentId = '5953' and EMBase.SourceEquipmentId  <> '5953' Then tt.EstTotalHours/2*60.0
						When EMroute.SourceEquipmentId <> '5953' and EMBase.SourceEquipmentId  = '5953' Then tt.EstTotalHours*2*60.0
						WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END, 0),
				CASE WHEN TT.TaskName = 'SHEETER' THEN 6 ELSE TT.[Sequence] END ,
				EMroute.SourceEquipmentId ,
				CASE when TM.SourcePriority Like '%Urgent%' OR TM.SourcePriority Like '%High%' OR TM.SourcePriority Like '%Rush%' then 1 else 0 end,--- Standardised implementation for Calculating High priority
				TC.taskClassification ,
				MC.MasterRollClassification,
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
				TT.DependentSourceTicketId,
				TTD.ID,
				TT.EnforceTaskDependency
		from 
		FeasibleRoutes_temp FR
				inner join TicketMaster TM  ON FR.TicketId = TM.ID
				inner join TicketTask_temp TT ON FR.TaskId = TT.Id
				inner Join EquipmentMaster EMBase ON TT.OriginalEquipmentId = EMBase.ID
				inner join EquipmentMaster EMroute ON FR.EquipmentId = EMroute.ID
				inner join TicketDimensions TD on TD.TicketId = TM.ID
				inner join TicketShipping TS on TS.TicketId = TM.ID
				inner join TicketScore TSC on TSC.TicketId = TM.ID
				left join TicketTaskData ttd on tt.TicketId = ttd.TicketId and tt.TaskName = ttd.TaskName
				left join ScheduleOverride SO on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
				left join @TicketsData TDD on TM.ID = TDD.TicketId
				left join MinutewiseCalendar MWC on TT.EstMaxDueDateTime = MWC.TheDateTime
				left join #TaskClassifications TC on EMroute.WorkcenterTypeId = TC.WorkcenterTypeId and FR.TicketId = TC.TicketId
				left join #TempMasterRollClassification MC on EMroute.WorkCenterName = MC.WorkCenterName and FR.TicketId = MC.TicketId
				left join #TimeCardScans TCS on FR.TicketId = TCS.TicketId and TCS.WorkCenterName = EMBase.WorkCenterName
				left join #TicketStockFirstAvailable TSFA ON FR.TicketId = TSFA.TicketId and TT.TaskName = TSFA.TaskName 
				Left Join TicketAttributeValues_temp VARNISH on VARNISH.TicketId=tm.ID and VARNISH.Name = 'Varnish'
				Left Join view_recipelength vrl on TM.SourceTicketId = vrl.Number and vrl.Task = tt.TaskName and fr.EquipmentID = vrl.EquipmentID
				Left Join TicketCharacteristics TC2 on TM.SourceTicketId=TC2.Number
				Where Case WHEN EMroute.SourceEquipmentId In ('5941', '5942', '5943') and TM.SourceCustomerId Like 'W%' and TC2.StockNum2='B7729' and vrl.RecipeLength < 2500 Then 0
						WHEN EMroute.SourceEquipmentId In ('5941', '5942', '5943') and TM.SourceCustomerId Like 'W%' and TC2.StockNum2='79101' and vrl.RecipeLength < 5000 Then 0
						WHEN EMroute.SourceEquipmentId In ('5941') and TM.SourceCustomerId Not Like 'W%' and (TC2.PantoneOrange + TC2.PantoneGreen) < 2 AND NOT (TC2.StockNum2 = 'SA255' and TC2.Stockwidth2 = 12) and  vrl.RecipeLength < 6500 Then 0
						WHEN EMroute.SourceEquipmentId In ('5942', '5943') and TM.SourceCustomerId Not Like 'W%' and (TC2.PantoneOrange + TC2.PantoneGreen) < 2 and  vrl.RecipeLength < 6500 Then 0
						When EMroute.SourceEquipmentId IN ('5911', '5912', '5915') and ((TC2.PrintWidth <= 12.31
                                                                            --AND TC2.CustomerNum not in ('52')
                                                                            AND TC2.Shape Not Like '%flex%'
                                                                            AND ((TC2.HotFoil + TC2.Reinsertion + TC2.Embossing + TC2.[DoublePass_ReinsertionFlag]) <= 0 OR TC2.GeneralDescr = 'KFC169')
                                                                            AND TC2.StockNum2 <> 'SA036'
                                                                            --AND TC2.WizardFlag <= 0
                                                                            AND TC2.PantoneSilver <= 0)
																			OR (TC2.CustomerNum in ('52') AND TC2.GeneralDescr Like '%ATI018%'))
																			AND vrl.RecipeLength >= 6500 Then 0
						When EMroute.SourceEquipmentId IN ('5941', '5942', '5943') and ((TC2.PrintWidth <= 12.31
                                                                            --AND TC2.CustomerNum not in ('52')
                                                                            AND TC2.Shape Not Like '%flex%'
                                                                            AND ((TC2.HotFoil + TC2.Reinsertion + TC2.Embossing + TC2.[DoublePass_ReinsertionFlag]) <= 0 OR TC2.GeneralDescr = 'KFC169')
                                                                            AND TC2.StockNum2 <> 'SA036'
                                                                            --AND TC2.WizardFlag <= 0
                                                                            AND TC2.PantoneSilver <= 0)
																			OR (TC2.CustomerNum in ('52') AND TC2.GeneralDescr Like '%ATI018%'))
																			AND vrl.RecipeLength >= 10000 Then 0
						When EMroute.SourceEquipmentId IN ('6001') AND vrl.RecipeLength < 10000 Then 0
						Else fr.RouteFeasible
				End = 1

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


