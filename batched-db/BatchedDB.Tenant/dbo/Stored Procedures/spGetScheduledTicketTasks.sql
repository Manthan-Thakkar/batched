CREATE PROCEDURE [dbo].[spGetScheduledTicketTasks]
    @sourceTicketNumbers AS udt_singleField readonly,
	@currentLocalDate as Datetime  = null,
	@numberOfTimeCardDays AS INT = 15
AS
BEGIN
	IF(@currentLocalDate = null)
		SET @currentLocalDate = GETDATE()

	;WITH timecard AS (
        /** Calculate a DateTime value for latest scan **/
        SELECT
            tc.equipmentid,
            tc.sourceticketid
            , startedon AS StartDateTime -- to adjust time stored as integer in DB
        FROM
            timecardinfo tc WITH (NOLOCK)
        WHERE
             startedon > Dateadd(day,-@numberOfTimeCardDays,@currentLocalDate)
    )
   , latestruntime AS (
        /** Find latest scan for each press **/
        SELECT
            tc.equipmentid
            , Max(startdatetime) AS MaxStartDateTime
        FROM
            timecard tc
        GROUP BY
            tc.equipmentid
    )
        /** Find latest ticket run on each machine, load key attributes to identify possible changeovers **/
     , lastrun AS(
        SELECT
            lrt.equipmentid AS LastRunEquipmentId
            , Cast(tc.sourceticketid AS NVARCHAR(255)) AS LastRunSourceTicketId
        FROM
            latestruntime LRT
        INNER JOIN
            timecard tc
            ON LRT.equipmentid = tc.equipmentid
            AND LRT.maxstartdatetime = tc.startdatetime
            ),
	    tasktime AS(
	        SELECT
	           tt.EstMaxDueDateTime AS TaskDueTime, ts.shipbydatetime, ts.ticketid, iscomplete, tm.sourceticketid, tt.taskname
	           , LAG(tt.IsComplete) OVER (PARTITION BY TT.TicketId ORDER BY tt.[Sequence]) PreviousIsComplete, tt.OriginalEquipmentId, tt.Sequence
	        FROM
	            TicketTask tt WITH (NOLOCK)
	            INNER JOIN TicketShipping ts WITH (NOLOCK)
	                ON ts.ticketid = tt.ticketid
	            INNER JOIN TicketMaster tm WITH (NOLOCK)
	                ON tm.id = tt.ticketid
	        WHERE
	            ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  tm.sourceticketid IN (SELECT Field FROM @sourceTicketNumbers))
	    ),
		completedTasks AS (
				SELECT
					tm.SourceTicketId,
					tm.ID AS TicketId,
					tt.TaskName,
					CASE WHEN tsk.EstTotalHours = 0 THEN 1 ELSE CEILING(tsk.EstTotalHours  * 60) END as EstMinutes,
					tsk.IsComplete AS IsComplete,
					CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited, 
					CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited, 
					sr.StartsAt AS StartsAt,
					sr.EndsAt AS EndsAt,
					em.Name AS Equipment,
					em.WorkCenterName AS Workcenter,
					em.FacilityId,
					'Complete' AS TaskStatus,
					0 AS IsOnPress,
					tt.Sequence,
					CASE WHEN so.ID IS NOT NULL AND so.IsScheduled = 1 THEN 1 ELSE 0 END AS IsManuallyScheduled,
					EM.ID as EquipmentId
				FROM tasktime tt
				LEFT JOIN TicketMaster TM WITH (NOLOCK) ON TT.ticketid = TM.Id
				LEFT JOIN EquipmentMaster em WITH (NOLOCK)
					ON tt.OriginalEquipmentId = em.ID
				LEFT JOIN ScheduleReport sr WITH (NOLOCK) ON tt.TaskName = sr.TaskName AND sr.SourceTicketId = tm.SourceTicketId
				LEFT JOIN TicketTask TSK WITH (NOLOCK)
					ON tsk.TicketId = tm.ID and tsk.TaskName = sr.TaskName
				LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK)
					ON tm.ID = TTO.TicketId AND sr.TaskName = TTO.TaskName
				LEFT JOIN ScheduleOverride so WITH (NOLOCK) ON so.Number = TM.SourceTicketId AND so.TaskName = tt.TaskName 
				 WHERE TM.SourceTicketId IN (SELECT Field FROM @sourceTicketNumbers) AND tt.IsComplete = 1
			),

	     scheduledTasks AS (
	            SELECT
            tm.SourceTicketId,
			tsk.TicketId AS TicketId,
            sr.TaskName,
			CASE WHEN tsk.EstTotalHours = 0 THEN 1 ELSE CEILING(tsk.EstTotalHours  * 60) END as EstMinutes,
			tsk.IsComplete AS IsComplete,
			CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited, 
			CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited, 
			sr.Startsat,
			sr.EndsAt,
			em.Name AS Equipment,
			em.WorkCenterName AS Workcenter,
			em.FacilityId,
            CASE
                WHEN tt.IsComplete=1 THEN 'Complete' 
                WHEN tt.ShipByDateTime IS NULL THEN 'Late'
                WHEN sr.EndsAt IS NULL THEN 'Unscheduled'
                WHEN @currentLocalDate> tt.taskduetime OR sr.EndsAt > tt.TaskDueTime THEN 'Late'
                WHEN   Datediff(hh, @currentLocalDate, tt.TaskDueTime) < 4
                    OR Datediff(hh, sr.EndsAt, tt.TaskDueTime) < 4 THEN 'At Risk'
                WHEN @currentLocalDate > sr.EndsAt THEN 'Behind'
                ELSE 'On Track'
            END
                AS TaskStatus,
            CASE
                WHEN lr.LastRunSourceTicketId IS NOT NULL THEN CAST(1 as bit)
                ELSE CAST(0 as bit)
            END AS IsOnPress,
			tt.Sequence,
			(CASE WHEN so.ID IS NOT NULL THEN 1 ELSE 0 END) AS IsManuallyScheduled,
			EM.ID as EquipmentId
            FROM ScheduleReport sr
            LEFT join TicketMaster tm WITH (NOLOCK) on sr.SourceTicketId = tm.SourceTicketId
            LEFT JOIN tasktime tt
                ON tt.SourceTicketId = sr.SourceTicketId
                AND tt.TaskName = sr.TaskName
            LEFT JOIN lastrun lr
                ON lr.LastRunSourceTicketId = tt.SourceTicketId
                AND lr.LastRunEquipmentId = sr.EquipmentId
			LEFT JOIN EquipmentMaster em WITH (NOLOCK)
					ON sr.EquipmentId = em.ID
			LEFT JOIN TicketTask TSK WITH (NOLOCK)
				ON tsk.TicketId = tm.ID and tsk.TaskName = sr.TaskName
			LEFT join ScheduleOverride so WITH (NOLOCK)
				ON tm.ID = so.TicketId and sr.TaskName = so.TaskName and so.IsScheduled = 1
			LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK)
				ON tm.ID = TTO.TicketId AND sr.TaskName = TTO.TaskName
            WHERE
                sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers) 
				AND sr.TaskName NOT IN (SELECT TaskName FROM completedTasks WHERE SourceTicketId = sr.SourceTicketId)
	        ),

			manuallyUnscheduledTasks AS (
				SELECT
					so.Number,
					TT.TicketId AS TicketId,
					tt.TaskName,
					CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE CEILING(TT.EstTotalHours  * 60) END as EstMinutes,
					TT.IsComplete AS IsComplete,
					CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited, 
					CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited, 
					so.StartsAt,
					so.EndsAt,
					em.Name AS Equipment,
					em.WorkCenterName AS Workcenter,
					em.FacilityId,
					'Unscheduled' AS TaskStatus,
					0 AS IsOnPress,
					tt.Sequence,
					0 AS IsManuallyScheduled,
					EM.ID as EquipmentId
				FROM TicketTask tt
				LEFT join ScheduleOverride SO WITH (NOLOCK) 
					ON tt.TicketId = SO.TicketId AND tt.TaskName = so.TaskName
				LEFT JOIN EquipmentMaster em WITH (NOLOCK)
					ON tt.OriginalEquipmentId = em.ID
				LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK)
						ON TT.TicketId = TTO.TicketId AND TT.TaskName = TTO.TaskName
				 WHERE SO.Number IN (SELECT Field FROM @sourceTicketNumbers) 
				 AND tt.TaskName NOT IN (select TaskName from scheduledTasks WHERE SourceTicketId = SO.Number)
				 AND tt.TaskName NOT IN (select TaskName from completedTasks WHERE SourceTicketId = SO.Number)
				),

				unscheduledTasks AS (
					SELECT 
						TM.SourceTicketId AS SourceTicketId, 
						TT.TicketId AS TicketId,
						TT.TaskName AS TaskName, 
						CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE CEILING(TT.EstTotalHours  * 60) END as EstMinutes,
						TT.IsComplete AS IsComplete,
						CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited, 
						CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited, 
						NULL AS StartsAt,
						NULL AS EndsAt,
						EM.Name as Equipment, 
						EM.WorkCenterName AS Workcenter, 
						EM.FacilityId AS FacilityId, 
						'Unscheduled' AS TaskStatus,
						0 AS IsOnPress,
						TT.Sequence,
						0 AS IsManuallyScheduled,
						EM.ID as EquipmentId
					FROM TicketTask TT
					INNER JOIN TicketMaster TM WITH (NOLOCK)
						ON TT.TicketId = TM.ID
					INNER JOIN EquipmentMaster EM WITH (NOLOCK) 
						ON TT.OriginalEquipmentId = EM.ID
					LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK)
						ON TT.TicketId = TTO.TicketId AND TT.TaskName = TTO.TaskName
					WHERE TM.Sourceticketid IN (SELECT Field FROM @sourceTicketNumbers)
						AND TT.TaskName NOT IN (select TaskName from scheduledTasks WHERE SourceTicketId = TM.SourceTicketId)
						AND TT.TaskName NOT IN (select TaskName from completedTasks WHERE SourceTicketId = TM.SourceTicketId)
						AND TT.TaskName NOT IN (select TaskName from manuallyUnscheduledTasks WHERE SourceTicketId = TM.SourceTicketId) 
				),


			allTickets AS (
				SELECT * FROM scheduledTasks
				UNION
				SELECT * FROM completedTasks
				UNION
				SELECT * FROM manuallyUnscheduledTasks
				UNION 
				SELECT * FROM unscheduledTasks
			)

	
		SELECT *, 'tbl_scheduledTasks' AS __dataset_tableName 
		FROM allTickets 
		ORDER BY SourceTicketId, Sequence
END