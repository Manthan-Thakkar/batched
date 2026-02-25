CREATE PROCEDURE [dbo].[spCalculateScheduleRefreshData]
	@currentLocalDate as Datetime  = null
AS
BEGIN
	--- ScheduleReport base data
	BEGIN
		DROP TABLE IF EXISTS #schedulereportdetail ;
		;WITH
		timecard AS (
			/** Calculate a DateTime value for latest scan **/
		    SELECT
				tc.equipmentid,
		        tc.sourceticketid,
				startedon AS StartDateTime, -- to adjust time stored as integer in DB
				EM.WorkcenterTypeId as Workcenter
		    FROM
				(SELECT distinct(sourceTicketId) from scheduleReport) SrTickets
				inner join 
		        timecardinfo  tc  with (nolock) on tc.SourceTicketId = SrTickets.SourceTicketId
				inner join EquipmentMaster EM with (nolock) on tc.EquipmentId = EM.ID
		), 
		latestruntime AS (
		     /** Find latest scan for each press **/
		     SELECT
				tc.Workcenter, Max(startdatetime) AS MaxStartDateTime
		     FROM
		        timecard  tc with (nolock)
		     GROUP BY
		            tc.Workcenter
		),
		lastrun AS(
			/** Find latest ticket run on each machine, load key attributes to identify possible changeovers **/
		    SELECT
				lrt.Workcenter AS LastRunWorkcenter, Cast(tc.sourceticketid AS NVARCHAR(255)) AS LastRunSourceTicketId
		    FROM
				latestruntime LRT with (nolock)
		    INNER JOIN
				timecard tc   ON LRT.Workcenter = tc.Workcenter   AND LRT.maxstartdatetime = tc.startdatetime
		),
		tasktime AS(
		    SELECT
				tt.EstMaxDueDateTime AS TaskDueTime, ts.shipbydatetime, ts.ticketid, iscomplete, tm.sourceticketid, tt.taskname,
				LAG(tt.IsComplete) OVER (PARTITION BY TT.TicketId ORDER BY tt.Sequence) PreviousIsComplete
		    FROM
				tickettask tt with (nolock)
		        INNER JOIN ticketshipping ts with (nolock)
		        ON ts.ticketid = tt.ticketid
		        INNER JOIN ticketmaster tm with (nolock)
		        ON tm.id = tt.ticketid
		),
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
		                WHEN lr.lastrunsourceticketid IS NOT NULL THEN CAST(1 as bit)
		                ELSE CAST(0 as bit)
		            END AS IsOnPress            
		            FROM schedulereport sr with (nolock)
					inner join EquipmentMaster EM with (nolock) on sr.EquipmentId = EM.ID
		            LEFT join TicketMaster TMM with (nolock) on sr.SourceTicketId = TMM.SourceTicketId
		            LEFT JOIN tasktime tm with (nolock)
		                ON tm.sourceticketid = sr.sourceticketid
		                AND tm.taskname = sr.taskname
		            LEFT JOIN lastrun lr with (nolock)
		                ON lr.lastrunsourceticketid = tm.sourceticketid
		                AND lr.LastRunWorkcenter = EM.WorkcenterTypeId
		),
		schedule AS (
			SELECT
				sr.*,
				TMM.ID as TicketId,
				tss.TaskStatus,
				tss.IsOnPress	,
		        em.NAME AS EquipmentName,
		        em.displayname AS EquipmentDisplayName,
		        em.workcentertypeid            
		    FROM schedulereport sr with (nolock)
				inner join EquipmentMaster EM on sr.EquipmentId = EM.ID
				inner join taskStatuses tss on sr.SourceTicketId = tss.SourceTicketId and sr.TaskName = tss.TaskName 
		        LEFT join TicketMaster TMM on sr.SourceTicketId = TMM.SourceTicketId
		)
		
		SELECT
			s.*,
			CAST(TTT.EstMeters AS decimal(38, 4)) as TaskMeters,
			TTT.TaskName as Task
		INTO #schedulereportdetail
		FROM schedule s
			INNER JOIN TicketMaster TM with (nolock) on s.SourceTicketId = TM.SourceTicketId
			LEFT JOIN TicketTask TTT with (nolock) on Tm.ID = TTT.TicketId and s.TaskName = TTT.TaskName

	END

	--- Section Batched Referesh Data
	BEGIN
		DECLARE @LastScheduleRunDate datetime = null;
		DECLARE @LastImportDate datetime = null;

		-- Last Schedule Run Date
			SELECT @LastScheduleRunDate=  Min(CreatedOn) from #schedulereportdetail

			SELECT @LastImportDate=  Cast(Value as datetime)  
			FROM ConfigurationMaster CM inner join ConfigurationValue CV on CM.Id = CV.ConfigId where CM.Name = 'LastImportDate'

			SELECT @LastScheduleRunDate as LastScheduleRunDate , @LastImportDate as LastImportDate ,'tbl_batchedRefereshData'  AS __dataset_tableName

		--- Next Schedule Run Date and Last import will be reused logic from application side

	END
	--- Drop Temporary tables
	BEGIN
		DROP TABLE IF EXISTS #schedulereportdetail
	END
END