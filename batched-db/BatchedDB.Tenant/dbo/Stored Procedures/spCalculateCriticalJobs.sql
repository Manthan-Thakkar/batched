CREATE PROCEDURE [dbo].[spCalculateCriticalJobs]
	@facilities AS UDT_SINGLEFIELDFILTER READONLY 
AS
BEGIN

	DECLARE
		@Yesterday				DATETIME = DATEADD(DAY, -1, GETUTCDATE()),
		@DayBeforeYesterday		DATETIME = DATEADD(DAY, -2, GETUTCDATE());

	------ Open Jobs Base Data
	BEGIN
		SELECT distinct TicketId into #OpenTicketsData 
		FROM TicketTask TT WITH (NOLOCK)--- All the tickets which have generated Ticket tasks pass the applicability rule by default
		INNER JOIN EquipmentMaster EM WITH (NOLOCK) ON TT.OriginalEquipmentId = EM.Id
		WHERE ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities))
	END

	
	------ Latest schedule archives for each ticket between last 24 to 48 hours.
	SELECT
		Id,
		SourceTicketId,
		ArchivedOnUTC,
        ROW_NUMBER() OVER (PARTITION BY SourceTicketId ORDER BY ArchivedOnUTC DESC) AS RowNum
	INTO #RecentSchedules
    FROM ScheduleArchive
    WHERE ArchivedOnUTC < @Yesterday AND ArchivedOnUTC > @DayBeforeYesterday


	------ Distict tickets present in schedule report.
	SELECT DISTINCT SourceTicketId
	INTO #DistinctScheduledTickets
	FROM ScheduleReport SR


	------ WorkCenterRawMaterialStatus
	BEGIN
		SELECT est.TicketId, 
			CASE 
				WHEN est.EstTimeOfArrival > est.FirstTaskDueDateTime THEN 0 
				ELSE 1 
			END AS IsCompletingOnTime
		INTO #WorkcenterMaterialConsumingTickets
		FROM
			(
				SELECT 
					DISTINCT tsa.TicketId, 
					tsa.FirstAvailableTime AS EstTimeOfArrival,
					ROW_NUMBER() OVER(PARTITION BY tsa.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
					tt.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM TicketStockAvailability tsa
				INNER JOIN TicketStockAvailabilityRawMaterialTickets tsarmt
					ON tsa.Id = tsarmt.TicketStockAvailabilityId
				INNER JOIN TicketTask tt
					ON tsa.TicketId = tt.TicketId
			) est
		WHERE est.Rno = 1
		

		SELECT TicketId, EstTimeOfArrival 
		INTO #WcmPTArrivalTime
		FROM 
			(
				SELECT
					tti.TicketId AS TicketId,
					ROW_NUMBER() OVER(PARTITION BY tti.TicketId ORDER BY tsa.FirstAvailableTime DESC) AS Rno,
					tsa.FirstAvailableTime AS EstTimeOfArrival
				FROM TicketStockAvailabilityRawMaterialTickets rmt
				INNER JOIN TicketItemInfo tti 
					ON rmt.TicketItemInfoId = tti.Id
				INNER JOIN TicketStockAvailability tsa
					ON rmt.TicketStockAvailabilityId = tsa.Id
			) t
		WHERE  t.Rno = 1

		
		SELECT 
			DISTINCT TicketId,  
			CASE 
				WHEN t.EstTimeOfArrival > t.FirstTaskDueDateTime THEN 0 
				ELSE 1 
			END AS IsCompletingOnTime
		INTO #WorkcenterMaterialProducingTickets
		FROM
			(
				SELECT 
					pt.TicketId, 
					pt.EstTimeOfArrival,  
					ROW_NUMBER() OVER(PARTITION BY pt.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
					tt.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM #WcmPTArrivalTime pt
				INNER JOIN TicketItemInfo tii
					ON pt.TicketId = tii.TicketId
				INNER JOIN TicketStockAvailabilityRawMaterialTickets rmt
					ON tii.Id = rmt.TicketItemInfoId
				INNER JOIN TicketStockAvailability tsa
					ON rmt.TicketStockAvailabilityId = tsa.Id
				INNER JOIN TicketTask tt
					ON tsa.TicketId = tt.TicketId
			) t
		WHERE t.Rno = 1
	END


	----Ticket Worst case status calculation
	BEGIN
		--- Remaining task calculation
		;WITH remainingTasks as (
			SELECT TM.SourceTicketId,TM.ID as TicketId, TaskName 
			FROM TicketTask TT WITH (NOLOCK) inner join TicketMaster TM WITH (NOLOCK) on TT.TicketId = TM.ID where TT.IsComplete = 0
		),
		-- Latest task times calculation
		LatestTaskTimes as (
			SELECT RT.TicketId, (MAX(SR.EndsAt))  AS LatestTaskTime
			FROM remainingTasks RT 
			inner join TicketMaster TM WITH (NOLOCK) on RT.TicketId = TM.ID
			inner join TicketShipping Ts WITH (NOLOCK) on TM.ID = TS.TicketId
			inner JOIN ScheduleReport SR WITH (NOLOCK) on Tm.SourceTicketId = SR.SourceTicketId and RT.TaskName = Sr.TaskName
			GROUP BY RT.TicketId
		)

		SELECT * into  #TicketLatestTaskTimes FROM LatestTaskTimes

		SELECT CASE
				WHEN GETDATE()> ts.ShipByDateTime OR (ltt.[LatestTaskTime]> ts.ShipByDateTime and ltt.[LatestTaskTime] IS NOT NULL) 
					THEN 'Late'
				WHEN   datediff(hh, GETDATE(), ts.ShipByDateTime) < 2 OR datediff(hh, ltt.[LatestTaskTime], ts.ShipByDateTime) < 2
					THEN 'At Risk'
				WHEN GETDATE() > ltt.LatestTaskTime 
					THEN 'Behind'
				ELSE 'On Track'
				END as [TicketStatus], TM.Id as TicketId
				INTO #TicketWorstCaseStatus
				FROM #TicketLatestTaskTimes ltt
				inner join TicketMaster TM WITH (NOLOCK) on TM.ID = ltt.TicketId
				inner join TicketShipping TS WITH (NOLOCK) on TS.TicketId = ltt.TicketId
	END

	---- Unscheduled Tickets base data
	BEGIN
		WITH TicketTaskRaw as (
		  SELECT TT.TicketId,
		  CASE WHEN  MAX(FR.ID) is null THEN 0 ELSE 1 END as FeasibleRoutesString,
		  CASE 
			WHEN ( MAX(SR.Id) is null and Max(SO.id) is null and Max(cast( TT.IsProductionReady as int)) = 1 )
				OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 0)
				OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 1)
			THEN 1 ELSE 0 END as ProductionReady,
		 Case When (Max(cast( SR.IsPinned as int))= 1) Then  'Locked' Else 'Unlocked' END as LockStatus,
         Case When (Max(cast( SR.IsPinned as int))= 1) Then  MAX(SR.PinType) Else NULL END as LockType
			FROM TicketTask TT WITH (nolock)
				INNER JOIN TicketMaster TM with (nolock) on TT.TicketId = TM.ID
				INNER JOIN EquipmentMaster EmPress with (nolock) on EmPress.SourceEquipmentId = COALESCE(TM.Press, TM.EquipId, TM.Equip2Id, TM.Equip3Id, TM.Equip4Id, TM.RewindEquipNum, TM.Equip6Id, Equip7Id)
				LEFT JOIN FeasibleRoutes FR with (nolock) on TT.Id = FR.TaskId and FR.RouteFeasible = 1
				LEFT JOIN ScheduleOverride SO with (nolock) on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
				LEFT JOIN ScheduleReport SR with (nolock) on SR.SourceTicketId = TM.SourceTicketId and SR.TaskName = TT.TaskName
		  WHERE 
				((IsProductionReady = 0 and  Sr.Id is null)
				OR (IsProductionReady = 1 and(  SO.IsScheduled = 0 or Sr.Id is null)))
				AND TT.IsComplete = 0
				GROUP BY TT.TicketId , TT.TaskName
		),
		TicketTaskFeasiblility as (
			SELECT TicketId ,  CASE WHEN MIN(FeasibleRoutesString) = 0 THEN 0 ELSE 1 END As TaskFeasible , Max(ProductionReady) as ProductionReadyTicket , Max(LockStatus) as LockStatus,Max(LockType) as LockType
			FROM TicketTaskRaw  GROUP BY TicketId
		)
		SELECT * into #TicketTaskRaw FROM TicketTaskFeasiblility

	END

	-- Wiating to be shipped calculation
	BEGIN
		SELECT  TicketId into #WaitingForShipping  
		FROM TicketTask with (nolock) group by TicketId having count(1) = sum(cast( iscomplete as int))
	END

	BEGIN
		 ;WITH completed_ticket_tasks AS (
        	 SELECT
           		*,
           		ROW_NUMBER() OVER(PARTITION BY ticketId ORDER BY sequence DESC) AS row_number
           		FROM TicketTask
           		where IsComplete = 1
           		)             
			 SELECT
           		ticketid, Sequence, IsComplete,em.SourceEquipmentId as LastStep
           		into #LastMachineRanOn
           		FROM completed_ticket_tasks ct
           		inner join equipmentmaster em on em.id = ct.OriginalEquipmentId
           		WHERE row_number = 1

		;WITH scheduled_Tickets AS (
            SELECT
           		*,
           		ROW_NUMBER() OVER(PARTITION BY sourceticketid ORDER BY startsAt asc) AS row_number
           		FROM ScheduleReport  WITH (NOLOCK)
           		)            
			SELECT
           		tm.ID, em.SourceEquipmentId as NextStep
           		into #NextMachineScheduled
           		FROM scheduled_Tickets st
				inner join TicketMaster tm WITH (NOLOCK) on tm.SourceTicketId = st.SourceTicketId
           		inner join equipmentmaster em  WITH (NOLOCK)on em.id = st.EquipmentId
           		WHERE row_number = 1
	END

	BEGIN
		SELECT 
			OT.TicketId,
			TM.SourceTicketId as TicketNumber,
			TM.CustomerName as Customer,
			TS.ShipByDateTime as ShipByDate,
			TL.LatestTaskTime as EstCompletionDate,
			Tm.GeneralDescription as GeneralDescription,
			TD.Quantity  as TicketQuantity,
			TM.OTSName as SalesPerson,
			TM.ITSName as Csr,
			TM.TicketCategory as TicketCategory,
			US.LockStatus,
			US.LockType,
			LM.LastStep,
			NM.NextStep,
			CASE
				WHEN US.TicketId is not null then 'Unscheduled'  --- Unscheduled
				WHEN TW.TicketId is not null then TW.TicketStatus  --- Scheduled worst case status
				WHEN WS.TicketId is not null then 'Waiting to Ship' --- Done but waiting for shipping
				ELSE Tm.SourceStatus 
			END as TicketStatus,
			CASE 
				WHEN CT.TicketId IS NOT NULL THEN CT.IsCompletingOnTime
				WHEN PT.TicketId IS NOT NULL THEN PT.IsCompletingOnTime
				ELSE NULL
			END AS IsCompletingOnTime,
			CASE 
				WHEN PT.TicketId IS NOT NULL THEN 1
				WHEN CT.TicketId IS NOT NULL THEN 2
				ELSE 0
			END AS WorkcenterMaterialTicketCategory,
			CASE
				WHEN US.TicketId IS NOT NULL AND RS.SourceTicketId IS NOT NULL AND DST.SourceTicketId IS NULL THEN 1
				WHEN WS.TicketId IS NOT NULL AND DST.SourceTicketId IS NOT NULL THEN 1
				WHEN US.TicketId IS NULL AND WS.TicketId IS NULL AND RS.Id IS NULL THEN 1
				ELSE 0
			END AS IsFirstDay,	
			'tbl_openJobsBoard' AS __dataset_tableName

			from #OpenTicketsData OT 
			INNER JOIN TicketMaster TM with(nolock) on OT.TicketId = TM.ID
			INNER JOIN TicketShipping TS with(nolock) on OT.TicketId = TS.TicketId
			INNER JOIN TicketScore TSC with(nolock) on OT.TicketId = TSC.TicketId
			LEFT JOIN  #TicketLatestTaskTimes TL on OT.TicketId =  TL.TicketId
			LEFT JOIN #TicketWorstCaseStatus TW on Ot.TicketId = TW.TicketId
			LEFT JOIN #TicketTaskRaw US on OT.TicketId = US.TicketId -- Unscheduled tickets
			LEFT JOIN #WaitingForShipping WS on OT.TicketId = WS.TicketId
			LEFT JOIN TicketDimensions TD on OT.TicketId = TD.TicketId
			LEFT JOIN #LastMachineRanOn LM on OT.TicketId = LM.TicketId
			LEFT JOIN #NextMachineScheduled NM on OT.TicketId = NM.ID
			LEFT JOIN #WorkcenterMaterialConsumingTickets CT ON CT.TicketId = TM.ID
			LEFT JOIN #WorkcenterMaterialProducingTickets PT ON PT.TicketId = TM.ID
			LEFT JOIN #RecentSchedules RS ON RS.SourceTicketId = TM.SourceTicketId AND RS.RowNum = 1
			LEFT JOIN #DistinctScheduledTickets DST ON TM.SourceTicketId = DST.SourceTicketId

			order by TS.ShipByDateTime asc, ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) asc


		SELECT (CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END) AS IsTicketDependencyEnabled, 'tbl_ticketDependency' AS __dataset_tableName    
			FROM TaskRules TR INNER JOIN TaskInfo TI  ON TR.TaskInfoId = TI.Id    
			WHERE TI.IsEnabled = 1 AND TR.RuleName = 'TicketDependency' AND TR.RuleText <> '' AND TR.RuleText <> N'NULL'


	END	
	--- Drop Temporary tables
	BEGIN
		DROP TABLE IF EXISTS #OpenTicketsData
		DROP TABLE IF EXISTS #TicketLatestTaskTimes
		DROP TABLE IF EXISTS #TicketWorstCaseStatus
		DROP TABLE IF EXISTS #TicketTaskRaw
		DROP TABLE IF EXISTS #WaitingForShipping
		DROP TABLE IF EXISTS #LastMachineRanOn
		DROP TABLE IF EXISTS #NextMachineScheduled
		DROP TABLE IF EXISTS #WorkcenterMaterialConsumingTickets
		DROP TABLE IF EXISTS #WcmPTArrivalTime
		DROP TABLE IF EXISTS #WorkcenterMaterialProducingTickets
		DROP TABLE IF EXISTS #DistinctScheduledTickets
		DROP TABLE IF EXISTS #RecentSchedules
	END
END