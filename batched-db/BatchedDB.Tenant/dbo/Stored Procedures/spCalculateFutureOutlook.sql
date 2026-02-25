CREATE PROCEDURE [dbo].[spCalculateFutureOutlook]
    @numberOfTimeCardDays AS INT = 15,
	@currentLocalDate as Datetime  = null,
	@futureDate as Datetime,
    @facilities AS UDT_SINGLEFIELDFILTER READONLY
AS
BEGIN

	--- ScheduleReport base data
	BEGIN
		-- Set necessary variables
		DECLARE @Tomorrow datetime;
		SET @Tomorrow = DATEADD(HOUR, 24, @futureDate)

		-- Drop temp tables if they exist
		DROP TABLE IF EXISTS #schedulereportdetail;
		DROP TABLE IF EXISTS #lastscan;
		DROP TABLE IF EXISTS #scheduleReport;

		--Start by finding the last record for each piece of equipment in the timecardinfo table
		;WITH
		lastscanrow as (Select tci.ID, 
								tci.EquipmentId,
								em.SourceEquipmentId,
								em.WorkcenterTypeId,
								tci.StartedOn,
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
						AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities)))


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
		-- Pull in task statues to be used later
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
		WHERE
			((SELECT Count(1) FROM @facilities) = 0  OR S.FacilityId IN (SELECT field FROM @facilities))

	END
	------ Open Jobs Base Data
	BEGIN
		SELECT tm.ID, tm.SourceTicketType INTO #OpenTicketsData 
		FROM TicketMaster tm WITH(NOLOCK)
		INNER JOIN TicketShipping ts WITH(NOLOCK) on tm.ID = ts.TicketId
		LEFT JOIN TicketTask TT ON TT.TicketId = TM.ID
		LEFT JOIN EquipmentMaster EM ON EM.ID = TT.OriginalEquipmentId
		Where tm.IsOpen = 1 
		and ((tm.SourceTicketType = 0 and ts.ShipByDateTime >= DATEADD(DAY, -30, @currentLocalDate)) OR tm.ID in (Select Distinct TicketId From TicketTask with (NOLOCK))) 
		and ts.ShipByDateTime < @Tomorrow --- All the tickets which have generated Ticket tasks pass the applicability rule by default
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
	End

	---- Unscheduled Tickets base data
	BEGIN 
		WITH 
		TicketTaskRaw AS (
		 SELECT 
			 TT.TicketId,
			 CASE WHEN  MAX(FR.ID) is null THEN 0 ELSE 1 END AS FeasibleRoutesString,
			 CASE 
				WHEN ( MAX(SR.Id) is null and Max(SO.id) is null and Max(cast( TT.IsProductionReady as int)) = 1 )
					OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 0)
					OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 1)
				THEN 1 ELSE 0 END as ProductionReady
				FROM TicketTask TT WITH (nolock)
				INNER JOIN #OpenTicketsData OTD on TT.TicketId = OTD.ID
		     inner join TicketMaster TM with (nolock) on TT.TicketId = TM.ID
			 INNER JOIN TicketShipping TS WITH (NOLOCK) on TM.ID = TS.TicketId
			 inner join EquipmentMaster EmPress with (nolock) on TM.Press = EmPress.SourceEquipmentId
			 left join FeasibleRoutes FR with (nolock) on TT.Id = FR.TaskId and FR.RouteFeasible = 1
			 left join ScheduleOverride SO with (nolock) on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
			 left join scheduleReport SR with (nolock) on SR.SourceTicketId = TM.SourceTicketId and SR.TaskName = TT.TaskName
		  WHERE 
			 ((IsProductionReady = 0 and  Sr.Id is null)
			 OR (IsProductionReady = 1 and(  SO.IsScheduled = 0 or Sr.Id is null)))
			 and TT.IsComplete = 0
			 AND ((SELECT Count(1) FROM @facilities) = 0  OR EmPress.FacilityId IN (SELECT field FROM @facilities))
			 group by TT.TicketId , TT.TaskName
		),
		TicketTaskFeasiblility AS (
			SELECT TicketId,  
			CASE WHEN MIN(FeasibleRoutesString) = 0 THEN 0 ELSE 1 END As TaskFeasible, Max(ProductionReady) 
			AS ProductionReadyTicket FROM TicketTaskRaw  GROUP BY TicketId
		)

		SELECT * into #TicketTaskRaw FROM TicketTaskFeasiblility
	END

	-- Waiting to be shipped calculation
	BEGIN
		SELECT TicketId INTO #WaitingForShipping  
		FROM (Select tt.TicketId  From TicketTask tt WITH (nolock)
								INNER JOIN #OpenTicketsData otd on tt.TicketId = otd.ID
								INNER JOIN EquipmentMaster EM ON TT.OriginalEquipmentId = EM.ID
								WHERE ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities))
								GROUP BY TicketId HAVING count(1) = sum(cast( iscomplete as int))
				UNION ALL

				Select otd.ID as TicketID
				From #OpenTicketsData otd
				Where otd.SourceTicketType = 0) tmp
	End

	-- Scheduled Tickets calculation
	Select OTD.ID
	Into #scheduledtickets
	From #OpenTicketsData OTD
	Left Join #TicketTaskRaw ttr on OTd.ID = ttr.TicketId
	Left Join #WaitingForShipping wfs on OTD.ID = wfs.TicketId
	Where ttr.TicketId IS NULL and wfs.TicketId IS NULL

	----Ticket Worst case status calculation
	BEGIN
		-- Latest task times calculation
			SELECT st.ID, (MAX(SRD.EndsAt))  AS LatestTaskTime
			Into #TicketLatestTaskTimes
			FROM #scheduledtickets st
			inner join TicketMaster TM  WITH(NOLOCK) on st.ID = TM.ID
			INNER JOIN TicketTask TT WITH(NOLOCK) on tm.ID = tt.TicketId
			inner JOIN #schedulereportdetail SRD  WITH(NOLOCK) on Tm.ID = SRD.TicketId and TT.TaskName = SRD.TaskName
			GROUP BY st.ID
		
		SELECT 
			ltt.ID,
			CASE
				WHEN @currentLocalDate> ts.ShipByDateTime
					 OR (ltt.[LatestTaskTime]> ts.ShipByDateTime and ltt.[LatestTaskTime] IS NOT NULL) Then 'Late'
				WHEN datediff(hh, @currentLocalDate, ts.ShipByDateTime) < 2 
					 OR datediff(hh, ltt.[LatestTaskTime], ts.ShipByDateTime) < 2 Then 'At Risk'
				WHEN @currentLocalDate > ltt.LatestTaskTime Then 'Behind'
				Else 'On Track' 
			END as [TicketStatus]
				INTO #TicketWorstCaseStatus
				FROM #TicketLatestTaskTimes ltt
				inner join TicketShipping TS WITH(NOLOCK) ON TS.TicketId = ltt.ID
	End

	----- Section todays outlook
	BEGIN
		Declare @TotalTickets real = 0;
		Declare @UnscheduledTickets real = 0;
		Declare @ScheduledTickets real = 0;
		Declare @TotalWaitingToBeShippedTickets real = 0;
		Declare @LateTickets int = 0;
		Declare @AtRiskTickets int = 0;
		Declare @OnTrackTickets  int = 0;
		Declare @BehindTickets int = 0
		Declare @ScheduledHours real = 0;
		Declare @TotalOpenTickets int = 0
		Declare @TotalOnPressTickets int = 0;
		Declare @ScheduledTasks int = 0;

		SELECT @currentLocalDate

		--- Scheduled Tasks
			SELECT @ScheduledTickets =  count(1) From #scheduledtickets
		
		--- Unscheduled tasks
			SELECT @UnscheduledTickets = count(1) FROM #TicketTaskRaw

		--- Waiting for shipping
			SELECT @TotalWaitingToBeShippedTickets = count(*) from #WaitingForShipping

		---- Total Tickets
			SELECT @TotalTickets = @UnscheduledTickets + @ScheduledTickets + @TotalWaitingToBeShippedTickets

		--- Late Tickets
			SELECT @LateTickets = count(1) From #scheduledtickets  ST 
			inner join #TicketWorstCaseStatus TW on ST.ID = TW.ID
			WHERE TW.TicketStatus = 'Late' 

		--- At Risk Tickets
			SELECT @AtRiskTickets = count(1) From #scheduledtickets  ST 
			inner join #TicketWorstCaseStatus TW on ST.ID = TW.ID
			WHERE TW.TicketStatus = 'At Risk' 

		--- Behind Tickets
			SELECT @BehindTickets = count(1) From #scheduledtickets  ST 
			inner join #TicketWorstCaseStatus TW on ST.ID = TW.ID
			WHERE TW.TicketStatus = 'Behind' 

		--- On track
			SELECT @OnTrackTickets = count(1) From #scheduledtickets  ST 
			inner join #TicketWorstCaseStatus TW on ST.ID = TW.ID
			WHERE TW.TicketStatus = 'On Track' 

		--- On Press
			SELECT @TotalOnPressTickets = count(distinct(Sr.TicketId))  from #schedulereportdetail SR
			INNER JOIN #OpenTicketsData OTD on Sr.TicketId = OTD.ID
			WHERE SR.IsOnPress= 1

		--- Scheduled hours
			SELECT @ScheduledHours = ceiling( sum(TaskMinutes) / 60)  from #schedulereportdetail Where EndsAt < @Tomorrow

		--- Scheduled Tasks
			SELECT @ScheduledTasks = count(1)  from #schedulereportdetail Where EndsAt < @Tomorrow
		
		--- TotalOpenTickets
			SELECT @TotalOpenTickets =  count(1) from #OpenTicketsData

		SELECT 
			@TotalTickets as TotalTickets,
			CASE
				WHEN @TotalTickets = 0 THEN 0
				ELSE ROUND(((@UnscheduledTickets/@TotalTickets) * 100), 1)
			END as UnscheduledPercentage,
			CASE
				WHEN @TotalTickets = 0 THEN 0
				ELSE ROUND(((@ScheduledTickets/@TotalTickets) * 100), 1)
			END as ScheduledPercentage,
			CASE
				WHEN @TotalTickets = 0 THEN 0
				ELSE ROUND(FLOOR((@TotalWaitingToBeShippedTickets/@TotalTickets)*100), 1)
			END as WaitingToBeShippedPercentage,
			@LateTickets as LateTickets,
			@AtRiskTickets as AtRiskTickets,
			@BehindTickets as BehindTickets,
			@OnTrackTickets as OnTrackTickets,
			@TotalOnPressTickets as OnPressTickets,
			@ScheduledHours as ScheduledHours,
			@TotalOpenTickets as OpenTickets,
			@TotalWaitingToBeShippedTickets as ScheduledToShip,
			@ScheduledTasks as ScheduledTasks,
			@UnscheduledTickets as UnscheduledTickets,
			@ScheduledTickets as ScheduledTickets,
			'tbl_todaysOutlook' AS __dataset_tableName
		END

		--- Drop Temporary tables
		BEGIN
			DROP TABLE IF EXISTS #schedulereportdetail
			DROP TABLE IF EXISTS #scheduleReport
			DROP TABLE IF EXISTS #TicketTaskRaw
			DROP TABLE IF EXISTS #waitingForShipping
			DROP TABLE IF EXISTS #OpenTicketsData
			DROP TABLE IF EXISTS #TicketWorstCaseStatus
			DROP TABLE IF EXISTS #TicketLatestTaskTimes
			DROP TABLE IF EXISTS #lastscan
			DROP TABLE IF EXISTS #scheduledtickets
		END
END