CREATE PROCEDURE [dbo].[spGetUnscheduledTicketTasks]
    @sourceTicketNumbers AS udt_singleField readonly
AS
BEGIN

	SELECT 
		TM.SourceTicketId AS SourceTicketId, 
		TT.TaskName AS TaskName, 
		TT.Id AS TaskId,
		CASE WHEN SR.Id IS NOT NULL THEN AE.Name ELSE OE.Name END AS Equipment, 
		CASE WHEN SR.Id IS NOT NULL THEN AE.WorkCenterName ELSE OE.WorkCenterName END AS Workcenter, 
		CASE WHEN SR.Id IS NOT NULL THEN AE.FacilityId ELSE OE.FacilityId END AS FacilityId, 
		CASE WHEN SO.IsScheduled IS NOT NULL AND SO.IsScheduled = 0 THEN 1 ELSE 0 END AS IsManuallyUnscheduled,
		CASE WHEN SR.Id IS NOT NULL OR TT.IsComplete = 1 THEN 1 ELSE 0 END AS CurrentlyScheduled,
		CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE CEILING(TT.EstTotalHours  * 60) END as EstMinutes,
		TT.IsComplete as IsComplete,
		CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited, 
		CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited, 
		TT.EstMeters AS EstMeters,
		TT.Sequence,
		'tbl_unscheduledTasks' AS __dataset_tableName
	FROM TicketTask TT WITH (NOLOCK)
	INNER JOIN TicketMaster TM WITH (NOLOCK)
		ON TT.TicketId = TM.ID
	INNER JOIN EquipmentMaster OE WITH (NOLOCK) 
		ON TT.OriginalEquipmentId = OE.ID
	LEFT JOIN ScheduleOverride SO WITH (NOLOCK) 
		ON TT.TicketId = SO.TicketId AND TT.TaskName = SO.TaskName 
	LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK)
		ON TT.TicketId = TTO.TicketId AND TT.TaskName = TTO.TaskName
	LEFT JOIN ScheduleReport SR WITH (NOLOCK) 
		ON SR.SourceTicketId = TM.SourceTicketId AND SO.TaskName = SR.TaskName
	LEFT JOIN EquipmentMaster AE WITH (NOLOCK) ON SR.EquipmentId = AE.ID

	WHERE TM.Sourceticketid IN (SELECT Field FROM @sourceTicketNumbers)
	ORDER BY TM.SourceTicketId, TT.Sequence

	SELECT
			FR.TicketId  TicketId,
			TaskId AS TaskId,
			TT.TaskName AS TaskName,
			EM.ID AS EquipmentId,
			EM.Name AS EquipmentName ,
			FR.RouteFeasible AS RouteFeasible ,
			FR.ConstraintDescription AS ConstraintDescription,
			TT.Sequence AS Sequence,
			EM.FacilityId AS FacilityId,
			'tbl_openRoutes' AS __dataset_tableName 
		FROM FeasibleRoutes FR   with (nolock)
		INNER JOIN ticketmaster tm WITH (NOLOCK) on fr.TicketId = tm.ID
		INNER JOIN TicketTask TT  with (nolock) on FR.TaskId = TT.Id
		LEFT JOIN EquipmentMaster EM  with (nolock) on EM.ID = FR.EquipmentId 
		WHERE TM.SourceticketId IN (SELECT Field FROM @sourceTicketNumbers)
		ORDER BY TT.Sequence
END