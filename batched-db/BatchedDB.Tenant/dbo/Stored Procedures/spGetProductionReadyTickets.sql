CREATE PROCEDURE [dbo].[spGetProductionReadyTickets]
    @facilities AS UDT_SINGLEFIELDFILTER READONLY
AS
BEGIN 


   ;WITH InfeasibleProdReadyTasks AS (
			SELECT Tt.TicketId FROM TicketTask TT WITH (NOLOCK) LEFT JOIN FeasibleRoutes FR WITH (NOLOCK)   ON FR.TaskId = TT.Id
			WHERE FR.ID IS NULL AND Tt.IsComplete =0 AND TT.IsProductionReady = 1
			GROUP BY Tt.ticketId
			)

			SELECT 
					SO.Id AS OverrideId,
					TT.TicketId AS TicketId,
					TM.SourceTicketId AS Number,
					TT.TaskName AS TaskName,
					SO.EquipmentName AS EquipmentName,
					SO.EquipmentId AS EquipmentId,
					SO.StartsAt AS StartsAt,
					SO.EndsAt AS EndsAt,
					TS.ShipByDateTime AS ShipByDate,
					TM.CustomerName AS Customer,
					TT.EstMeters AS EstLength,
					TT.WorkcenterId AS Workcenter,
					EM.FacilityId,
					CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END AS TaskMinutes,
					'tbl_ProductionReadyTickets' AS __dataset_tableName
			from TicketTask TT WITH (NOLOCK) 
			INNER JOIN TicketMaster TM WITH (NOLOCK) ON TT.TicketId = TM.Id
			INNER JOIN TicketShipping Ts WITH (NOLOCK) ON  TM.ID = TS.TicketId
			LEFT JOIN ScheduleOverride SO WITH (NOLOCK)  ON TM.Id = SO.TicketId AND SO.TaskName = TT.TaskName
			LEFT JOIN  ScheduleReport SR WITH (NOLOCK) ON TM.SourceTicketId = SR.SourceTicketId AND SR.TaskName = TT.TaskName
			LEFT JOIN Equipmentmaster EM WITH (NOLOCK) ON TT.WorkcenterId = EM.WorkcenterTypeId AND TT.OriginalEquipmentId = EM.id
			WHERE
			((SR.Id IS NULL  AND  TT.IsProductionReady = 0 AND SO.IsScheduled = 1) --- Not part of report / Manually scheduled
			OR (SR.Id IS NULL  AND  TT.IsProductionReady = 1 AND ( SO.IsScheduled IS NULL OR SO.IsScheduled = 1)))--- By Default production ready but not part of scheduled report
			AND tt.IsComplete = 0 -- Manually scheduled OR by default production ready
			AND TT.TicketId not in (select TicketId from InfeasibleProdReadyTasks)
			AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.facilityid  IN (SELECT field FROM @facilities))
			ORDER BY  TT.TicketId , TT.Sequence
			
			
END