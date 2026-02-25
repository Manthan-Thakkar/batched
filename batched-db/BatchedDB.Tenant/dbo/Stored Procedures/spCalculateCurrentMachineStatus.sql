CREATE PROCEDURE [dbo].[spCalculateCurrentMachineStatus]
	@currentLocalDate as Datetime  = null,
	@facilities AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN
	BEGIN
		-- Drop temp tables if they exist
		DROP TABLE IF EXISTS #schedulereportdetail ;
		DROP TABLE IF EXISTS #lastscan ;
		--Start by finding the last record for each piece of equipment in the timecardinfo table
		;WITH
		lastscanrow as (Select tci.ID, 
								tci.EquipmentId,
								em.FacilityId,
								em.SourceEquipmentId,
								em.WorkcenterTypeId,
								tci.StartedOn,
								tci.CompletedAt,
								tci.TicketId,
								tm.sourceticketid,
								tci.OperationType,
								tci.Associate,
								tci.ActualCurrentSpeed,
								ROW_NUMBER () over (Partition by em.SourceEquipmentID Order by tci.StartedON Desc) as RowNumber 
						From TimecardInfo tci WITH (NOLOCK)
						INNER JOIN EquipmentMaster em WITH (NOLOCK) on tci.EquipmentId = em.ID
						LEft join TicketMaster tm WITH (NOLOCK) on tci.TicketId = tm.ID
						Where tci.StartedOn >= DATEADD(day, -7, @currentLocalDate) and em.AvailableForScheduling = 1
						AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities)))

		Select *
		Into #lastscan
		From lastscanrow
		Where RowNumber = 1;

		-- Pull in task time information to be used later
		WITH tasktime AS(
			SELECT
				tt.EstMaxDueDateTime AS TaskDueTime, ts.shipbydatetime, ts.ticketid, iscomplete, tm.sourceticketid, tt.taskname, 
				LAG(tt.IsComplete) OVER (PARTITION BY TT.TicketId ORDER BY tt.Sequence) PreviousIsComplete
			FROM
		    tickettask tt with (nolock)
		    INNER JOIN ticketshipping ts with (nolock) ON ts.ticketid = tt.ticketid
		    INNER JOIN ticketmaster tm with (nolock) ON tm.id = tt.ticketid
		),
		-- Pull in task status to be used later
		taskStatuses AS (
			SELECT
				sr.SourceTicketId,
		        sr.TaskName,
				sr.Startsat,
				sr.endsat,
		    CASE
				WHEN iscomplete=1 THEN 'Complete'
		        WHEN tm.shipbydatetime IS NULL THEN 'Late'
		        WHEN sr.endsat IS NULL THEN 'Unscheduled'
		        WHEN @currentLocalDate> tm.taskduetime OR sr.endsat > tm.taskduetime THEN 'Late'
		        WHEN   Datediff(hh, @currentLocalDate, tm.taskduetime) < 4
					OR Datediff(hh, sr.endsat, tm.taskduetime) < 4 THEN 'At Risk'
		        WHEN @currentLocalDate >sr.endsat THEN 'Behind'
		        ELSE 'On Track'
			END
				AS TaskStatus,
		    CASE
				WHEN ls.SourceTicketId IS NOT NULL THEN CAST(1 as bit)
		        ELSE CAST(0 as bit)
			END AS IsOnPress            
				FROM schedulereport sr with (nolock)
				inner join EquipmentMaster EM with (nolock) on sr.EquipmentId = EM.ID
		        LEFT join TicketMaster TMM with (nolock) on sr.SourceTicketId = TMM.SourceTicketId
		        LEFT JOIN tasktime tm with (nolock)
		        ON tm.sourceticketid = sr.sourceticketid
		        AND tm.taskname = sr.taskname
		        LEFT JOIN #lastscan ls on sr.SourceTicketId = ls.SourceTicketId and sr.EquipmentId = ls.EquipmentId
				where ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
		),
		--Pull in schedule date to be used later
		schedule AS (
			SELECT
				sr.*,
				TMM.ID as TicketId,
				tss.TaskStatus,
				tss.IsOnPress,
		        em.NAME AS EquipmentName,
		        em.displayname AS EquipmentDisplayName,
		        em.workcentertypeid,
				em.FacilityId
		    FROM schedulereport sr with (nolock)
				inner join EquipmentMaster EM WITH(NOLOCK) on sr.EquipmentId = EM.ID
				inner join taskStatuses tss WITH(NOLOCK) on sr.SourceTicketId = tss.SourceTicketId and sr.TaskName = tss.TaskName 
		        LEFT join TicketMaster TMM WITH(NOLOCK) on sr.SourceTicketId = TMM.SourceTicketId
		)
		--Create schedule data for reference later
		SELECT
			s.*,
			CAST(TTT.EstMeters AS decimal(38, 4)) as TaskMeters,
			TTT.TaskName as Task
		    INTO #schedulereportdetail
		FROM schedule s
			INNER JOIN TicketMaster TM with (nolock) on s.SourceTicketId = TM.SourceTicketId
			LEFT JOIN TicketTask TTT with (nolock) on Tm.ID = TTT.TicketId and s.TaskName = TTT.TaskName
		
	END

	---- Section : Current Machine status
	BEGIN 
		/** Calculate a DateTime value for latest scan **/
		SELECT
			ls.EquipmentId,
			tc.equipmentid as tcequipmentid,
		    tc.sourceticketid, 
			ls.StartedOn AS StartDateTime, -- to adjust time stored as integer in DB
			EM.WorkcenterTypeId,
			EM.FacilityId,
			ElapsedTime as Elapsed,
			ActualNetQuantity  as ActualQuantity,
			tc.OperationType as Operation,
			tc.Associate as Associate,
			CASE 
				WHEN TRY_CONVERT(REAL, TC.Totalizer) > TC.ActualGrossLength THEN TRY_CONVERT(REAL, TC.Totalizer)
				ELSE TC.ActualGrossLength
			END as GrossLength,
			CASE 
				WHEN TC.FinishedPieces > TC.ActualGrossQuantity THEN TC.FinishedPieces
				ELSE TC.ActualGrossQuantity
			END as GrossQuantity,

			tc.ActualWasteQuantity as ActualWasteQuantity,
			tc.ActualNetQuantity as ActualNetQuantity,
			TD.Quantity as TicketDimensionQuantity,

			TC.Totalizer as Totalizer,
			TC.ActualGrossLength as ActualGrossLength,
			TC.ActualCurrentSpeed as ActualCurrentSpeed,
		
			CAST(DATEPART(second, ElapsedTime) + (DATEPART(minute, ElapsedTime) * 60) + (DATEPART(hour, ElapsedTime) * 3600) AS int) / 60.0  as TimeSpent,
			ROW_NUMBER() OVER(PARTITION BY ls.EquipmentID ORDER BY ls.startedon DESC) AS tci
		INTO #CurrentTimeCards
		FROM  #lastscan ls
		INNER JOIN EquipmentMaster em WITH (NOLOCK) on em.ID = ls.EquipmentId
		INNER JOIN  (Select tci.*, em.WorkcenterTypeId
						From TimecardInfo tci WITH (NOLOCK)
						INNER JOIN EquipmentMaster em WITH (NOLOCK) on tci.EquipmentId = em.ID)   tc on tc.TicketId = ls.TicketId and tc.WorkcenterTypeId = ls.WorkcenterTypeId
		INNER JOIN TicketDimensions TD with (nolock) on TD.TicketId = ls.TicketId
		Where ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))

		
		SELECT
			SourceTicketId, 
			WorkcenterTypeId,
			ROUND(SUM(TimeSpent), 0) as ActualTime ,
			ROUND(SUM(GrossLength), 0) as ActualThroughput,
			SUM(GrossQuantity) as ActualQuantity,
			SUM(ActualWasteQuantity) as ActualWasteQuantity,
			SUM(ActualNetQuantity) as ActualNetQuantity
			--Operation
			into #ActualTimes
		FROM #CurrentTimeCards 
			group by SourceTicketId, WorkcenterTypeId--,Operation

		SELECT
			SourceTicketId, 
			WorkcenterTypeId,
			ROUND(SUM(TimeSpent), 0) as ActualTime
			--Operation
			into #ActualRunTimes
		FROM #CurrentTimeCards
		Where Operation Like '%run%'
			group by SourceTicketId, WorkcenterTypeId--,Operation


		SELECT SourceTicketId , 
			WorkcenterTypeId ,
			STRING_AGG(CONVERT( NVARCHAR(MAX),tcequipmentid),'') as AllDistinctEquipments 
		into #ActualMachineScheduled 
		FROM #CurrentTimeCards group by SourceTicketId , WorkcenterTypeId--, EquipmentId

		SELECT
			a.SourceTicketId, 
			a.WorkcenterTypeId,
			CASE 
				WHEN art.ActualTime = 0 THEN 0 
				ELSE CEILING(a.ActualThroughput/art.ActualTime)
			END AS ActualAverageSpeed
		into #ActualAverageSpeed
		from #ActualTimes a
		Left JOIN #ActualRunTimes art on a.SourceTicketId = art.SourceTicketId and a.WorkcenterTypeId = art.WorkcenterTypeId
				
		    
		;WITH tickettasks as (Select tt.TicketId, tt.TaskName, em.WorkcenterTypeId, tt.Sequence
								From TicketTask tt
								INNER JOIN EquipmentMaster em on tt.OriginalEquipmentId = em.ID
								Where ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
						),
		
		CurrentTaskOnMachineCalc as (Select ls.*, tt.TaskName, ROW_NUMBER() Over (Partition by ls.SourceTicketId, ls.WorkcenterTypeID Order by tt.Sequence ASC) as Row_Number
									From #lastscan ls
									Left Join tickettasks tt on tt.TicketId = ls.TicketId and tt.WorkcenterTypeId = ls.WorkcenterTypeId

		),

		FinalTaskOnMachineCalc as (Select *
									From CurrentTaskOnMachineCalc
									Where Row_Number = 1)

		SELECT 
			FTMC.SourceEquipmentId as Machine,
			FTMC.SourceTicketId as TicketNumber,
			FTMC.FacilityId as FacilityId,
			FTMC.OperationType as Operation,
			srd.TaskStatus,
			srd.IsOnPress,
			FTMC.Associate,
			A.ActualTime, 
			TaskMinutes as ScheduledTime,
			CASE WHEN A.ActualTime > (srd.TaskMinutes + srd.ChangeoverMinutes) THEn cast(1 as bit ) ELSE Cast(0 as bit) End as IsBeyondScheduledMinutes,

			A.ActualThroughput ,
			CEILING(srd.TaskMeters) as ScheduledThroughput,

			FTMC.ActualCurrentSpeed ,
			AAS.ActualAverageSpeed,
			CASE 
				WHEN TaskMinutes = 0  THEN 0 
				ELSE CEILING(srd.TaskMeters/TaskMinutes) 
			END as EstimatedSpeed,
			
			A.ActualWasteQuantity as WasteUnitThroughput,
			A.ActualNetQuantity as GoodUnitThroughput,
			A.ActualQuantity TotalUnitThroughput,
			td.Quantity as ScheduledUnitThroughput,

			CASE WHEN AM.AllDistinctEquipments IS NULL then cast (0 as Bit)
				 WHEN LEN(REPLACE(AM.AllDistinctEquipments,FTMC.EquipmentId,'')) > 0 THEN cast(1 as bit) ELSE 0 
			End AS IsScheduledOnDifferentMachine,
			CASE WHEN FTMC.CompletedAt IS NULL Then 1 Else 0 End as IsCurrentlyRunning,
			'tbl_currentMachineStatus' AS __dataset_tableName
		FROM FinalTaskOnMachineCalc FTMC
			--left join #LastestTimeCardC LC on FTMC.SourceTicketId =  LC.SourceTicketId and FTMC.WorkcenterTypeId = LC.Workcenter
			left join #ActualTimes A  on FTMC.SourceTicketId =  A.SourceTicketId and FTMC.WorkcenterTypeId = A.WorkcenterTypeId
			left join #ActualRunTimes ART  on FTMC.SourceTicketId =  ART.SourceTicketId and FTMC.WorkcenterTypeId = ART.WorkcenterTypeId
			left join #ActualAverageSpeed AAS  on FTMC.SourceTicketId =  AAS.SourceTicketId and FTMC.WorkcenterTypeId = AAS.WorkcenterTypeId
			left join #ActualMachineScheduled AM on FTMC.SourceTicketId =  AM.SourceTicketId and FTMC.WorkcenterTypeId = AM.WorkcenterTypeId
			left join #schedulereportdetail srd on srd.SourceTicketId = FTMC.SourceTicketId and FTMC.TaskName = srd.Task
			left join TicketDimensions td WITH (NOLOCK) on srd.TicketId = td.TicketId
		Where ((SELECT Count(1) FROM @facilities) = 0  OR FTMC.FacilityId IN (SELECT field FROM @facilities))
		ORDER BY FTMC.SourceEquipmentId
	END
	--- Drop Temporary tables
	BEGIN
		DROP TABLE IF EXISTS #schedulereportdetail
		DROP TABLE IF EXISTS #CurrentTimeCards
		DROP TABLE IF EXISTS #LastestTimeCardC
		DROP TABLE IF EXISTS #ActualTimes
		DROP TABLE IF EXISTS #lastscan
		DROP TABLE IF EXISTS #ActualAverageSpeed
		DROP TABLE IF EXISTS #ActualRunTimes
		DROP TABLE IF EXISTS #ActualMachineScheduled
	END
END