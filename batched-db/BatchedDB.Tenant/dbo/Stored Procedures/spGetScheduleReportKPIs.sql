CREATE PROCEDURE [dbo].[spGetScheduleReportKPIs]
    @numberOfTimeCardDays AS INT = 15,
    @facilities AS UDT_SINGLEFIELDFILTER READONLY,
	@workcenters AS UDT_SINGLEFIELDFILTER READONLY,
	@tickets AS UDT_SINGLEFIELDFILTER READONLY,
	@equipments AS UDT_SINGLEFIELDFILTER READONLY,
	@valueStreams AS UDT_SINGLEFIELDFILTER READONLY
AS
BEGIN
   
   select SourceTicketId , MAX(EndsAt) as MaxEnd
   Into #MaxDateRecords
   from ScheduleReport SR
   LEFT JOIN EquipmentMaster EM ON EM.ID = SR.EquipmentId
   LEFT JOIN EquipmentValueStream EVS ON EVS.EquipmentId = SR.EquipmentId
   WHERE 
   ((SELECT Count(1) FROM @facilities) = 0  OR EM.facilityid  IN (SELECT field FROM @facilities))
   AND ((SELECT Count(1) FROM @tickets) = 0  OR SR.SourceTicketId  IN (SELECT field FROM @tickets))
   AND ((SELECT Count(1) FROM @workcenters) = 0  OR EM.WorkcenterTypeId  IN (SELECT field FROM @workcenters))
   AND ((SELECT Count(1) FROM @valueStreams) = 0  OR EVS.ValueStreamId  IN (SELECT field FROM @valueStreams))
   AND ((SELECT COUNT(1) FROM @equipments) = 0 OR SR.EquipmentId IN (SELECT field FROM @equipments ))
   group by SourceTicketId
   
   -- Late Tickets
   Select count(distinct MX.SourceTicketId) AS LateTickets ,'tbl_TotalLateTickets' AS __dataset_tableName 
   from #MaxDateRecords MX
   Inner join TicketMaster TM on MX.SourceTicketId =  TM.SourceTicketId
   Inner join TicketShipping TS on TM.ID = TS.TicketId
   Where MX.MaxEnd > Ts.ShipByDateTime
   
    SELECT SourceTicketId, ChangeoverMinutes, ChangeoverCount INTO #FacilityFilteredScheduleReport
    FROM ScheduleReport SR
	LEFT JOIN EquipmentMaster EM ON EM.ID = SR.EquipmentId
    LEFT JOIN EquipmentValueStream EVS ON EVS.EquipmentId = SR.EquipmentId
	WHERE ((SELECT Count(1) FROM @facilities) = 0  OR EM.facilityid  IN (SELECT field FROM @facilities))
    AND ((SELECT Count(1) FROM @tickets) = 0  OR SR.SourceTicketId  IN (SELECT field FROM @tickets))
    AND ((SELECT Count(1) FROM @workcenters) = 0  OR EM.WorkcenterTypeId  IN (SELECT field FROM @workcenters))
    AND ((SELECT Count(1) FROM @valueStreams) = 0  OR EVS.ValueStreamId  IN (SELECT field FROM @valueStreams))
    AND ((SELECT COUNT(1) FROM @equipments) = 0 OR SR.EquipmentId IN (SELECT field FROM @equipments ))

   -- Total changeover time
    Select ISNULL(SUM(ChangeoverMinutes),0)AS TotalChangeoverMinutes, 'tbl_TotalChangeoverMinutes' AS __dataset_tableName FROM #FacilityFilteredScheduleReport

	-- Total Number of changeovers
	Select ISNULL(SUM(ChangeoverCount),0)AS TotalChangeovers, 'tbl_TotalChangeovers' AS __dataset_tableName FROM #FacilityFilteredScheduleReport

	-- Total tickets count
	Select count(distinct(SourceTicketId)) as TotalTickets,'tbl_TotalTicketCount' AS __dataset_tableName FROM #FacilityFilteredScheduleReport

	--- Total Production ready tickets
	;with InfeasibleProdReadyTasks as (
			select Tt.TicketId from TicketTask TT
			left join FeasibleRoutes FR   on FR.TaskId = TT.Id
			Where FR.ID is null and Tt.IsComplete =0 and TT.IsProductionReady = 1
			group by Tt.ticketId
			)

			select count(distinct(TT.TicketId))  as TotalProductionReadyTickets,'tbl_TotalProdReadyTickets' AS __dataset_tableName
			from TicketTask TT 
			inner join TicketMaster TM on TT.TicketId = TM.Id
			inner join TicketShipping Ts on  TM.ID = TS.TicketId
			left join ScheduleOverride SO  on TM.Id = SO.TicketId and SO.TaskName = TT.TaskName
			left join  ScheduleReport SR on TM.SourceTicketId = SR.SourceTicketId and SR.TaskName = TT.TaskName
			LEFT JOIN EquipmentMaster EM ON TT.WorkcenterId = EM.WorkcenterTypeId AND TT.OriginalEquipmentId = EM.id
			where
			
			((SR.Id is null  and  TT.IsProductionReady = 0 and SO.IsScheduled = 1) --- Not part of report / Manually scheduled
			Or (SR.Id is null  and  TT.IsProductionReady = 1 and ( SO.IsScheduled is null OR SO.IsScheduled = 1)))--- By Default production ready but not part of scheduled report
			and tt.IsComplete = 0 -- Manually scheduled or by default production ready
		
			and TT.TicketId not in (select TicketId from InfeasibleProdReadyTasks)
			AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.facilityid  IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @workcenters) = 0  OR EM.WorkcenterTypeId  IN (SELECT field FROM @workcenters))
			-- BD-4780 - removed some filter to get actual prod ready ticket KPI as per Production ready ticket tray data
	DROP TABLE IF EXISTS #MaxDateRecords
    DROP TABLE IF EXISTS #FacilityFilteredScheduleReport
END
