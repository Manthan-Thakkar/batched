CREATE PROCEDURE [dbo].[spCalculateConstraintTaskDslValuesIncr]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN

	;WITH scheduledTasks as (
		SELECT DISTINCT
			tm.Id AS ticketId,	
			tt.Id AS taskId,
			sr.EquipmentId AS CurrentScheduledEquipmentId, 
			LAG(sr.EquipmentId) OVER(PARTITION BY tt.TicketId ORDER BY tt.Sequence ASC) AS PreviousTaskScheduledEquipmentId,
			LAG(tt.IsComplete) OVER(PARTITION BY tt.TicketId ORDER BY tt.Sequence ASC) AS PreviousTaskIsComplete
		FROM TicketTask_Incr tt WITH (NOLOCK)
		INNER JOIN TicketMaster tm WITH (NOLOCK)
			ON tt.TicketId = tm.Id
		LEFT JOIN ScheduleReport sr WITH (NOLOCK)
			ON sr.TaskName = tt.TaskName AND sr.SourceTicketId = tm.SourceTicketId
		WHERE tt.TicketId IN (SELECT ticketId FROM @tickets)
	)
 
	SELECT DISTINCT 
		tt.Id				as __ticketId,
		tt.Id				as __contextId,
		tt.TaskName			AS TaskName_dsl,
		tt.Sequence			AS TaskSequence_dsl,
		em.Name				AS EquipmentName_dsl,
		tt.WorkcenterId		AS WorkcenterId_dsl,
		em.FacilityName		AS TaskFacilityName_dsl,
		em2.Name			AS CurrentScheduledMachine_dsl, 
		em3.Name			AS PreviousTaskScheduledMachine_dsl,
		sr.PreviousTaskIsComplete AS PreviousTaskIsComplete_dsl
	FROM TicketTask_Incr tt WITH (NOLOCK)
	INNER JOIN EquipmentMaster em WITH (NOLOCK)
		ON tt.OriginalEquipmentId = em.ID
	INNER JOIN TicketMaster tm WITH (NOLOCK)
		ON tt.TicketId = tm.Id
	LEFT JOIN scheduledTasks sr WITH (NOLOCK)
		ON sr.taskId = tt.Id AND sr.ticketId = tm.Id
	LEFT JOIN EquipmentMaster em2 WITH (NOLOCK)
		ON sr.CurrentScheduledEquipmentId = em2.Id
	LEFT JOIN EquipmentMaster em3 WITH (NOLOCK)
		ON sr.PreviousTaskScheduledEquipmentId = em3.Id
 
END