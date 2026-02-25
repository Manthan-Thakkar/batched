CREATE VIEW [dbo].[view_LatestTaskTimes]
AS				
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

		SELECT * FROM LatestTaskTimes
GO