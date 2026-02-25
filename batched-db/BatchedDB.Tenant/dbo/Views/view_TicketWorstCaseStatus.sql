CREATE VIEW [dbo].[view_TicketWorstCaseStatus]
AS
		--- Remaining task calculation
		WITH remainingTasks as (
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

		SELECT CASE
				WHEN GETDATE()> ts.ShipByDateTime OR (ltt.[LatestTaskTime]> ts.ShipByDateTime and ltt.[LatestTaskTime] IS NOT NULL) 
					THEN 'Late'
				WHEN   datediff(hh, GETDATE(), ts.ShipByDateTime) < 2 OR datediff(hh, ltt.[LatestTaskTime], ts.ShipByDateTime) < 2
					THEN 'At Risk'
				WHEN GETDATE() > ltt.LatestTaskTime 
					THEN 'Behind'
				ELSE 'On Track'
				END as [TicketStatus], TM.Id as TicketId
				--INTO #TicketWorstCaseStatus
				FROM LatestTaskTimes ltt
				inner join TicketMaster TM WITH (NOLOCK) on TM.ID = ltt.TicketId
				inner join TicketShipping TS WITH (NOLOCK) on TS.TicketId = ltt.TicketId
	GO