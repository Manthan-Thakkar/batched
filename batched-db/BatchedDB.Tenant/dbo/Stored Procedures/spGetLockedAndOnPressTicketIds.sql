CREATE PROCEDURE [dbo].[spGetLockedAndOnPressTicketIds]
	@facilityId as varchar(36),
    @currentLocalDate as Datetime = null,
	@numberOfTimeCardDays as int = 15
AS
BEGIN
    IF(@currentLocalDate = null)
		SET @currentLocalDate = GETDATE();
    		
	SELECT 
		tc.EquipmentId, 
		tc.SourceTicketId, 
		tc.StartedOn AS StartDateTime -- to adjust time stored as integer in DB
	INTO #timecard
    FROM TimecardInfo tc
    WHERE 
		tc.StartedOn > Dateadd(day,-@numberOfTimeCardDays, @currentLocalDate)
	
       /** Find latest scan for each press **/
    SELECT 
		tc.EquipmentId, 
		Max(StartDateTime) AS MaxStartDateTime
	INTO #latestruntime
    FROM #timecard tc
    GROUP BY tc.EquipmentId

	SELECT 
		lrt.EquipmentId AS LastRunEquipmentId, 
			CAST(tc.SourceTicketId AS nvarchar(255)) AS LastRunSourceTicketId
	INTO #lastrun
    FROM #latestruntime lrt
	INNER JOIN #timecard tc
	ON lrt.EquipmentId = tc.EquipmentId AND lrt.MaxStartDateTime = tc.StartDateTime


	;WITH LockedAndOnPressTickets AS 
	(
		SELECT sr.SourceTicketId,
		CASE WHEN (sr.IsPinned = 1 AND (sr.PinType = 'sequence' OR sr.PinType = 'time')) THEN 1 ELSE 0 END AS IsLocked,
		CASE WHEN lr.LastRunSourceTicketId IS NOT NULL THEN CAST(1 as bit) ELSE CAST(0 as bit) END AS IsOnPress
		FROM ScheduleReport sr
		LEFT JOIN #lastrun lr
		ON lr.LastRunSourceTicketId = sr.SourceTicketId AND lr.LastRunEquipmentId = sr.EquipmentId
	)

	SELECT 
		tt.TicketId AS TicketId
	FROM TicketTask_temp tt
	INNER JOIN TicketMaster tm
	ON tt.TicketId = tm.ID
	INNER JOIN LockedAndOnPressTickets lop
	ON tm.SourceTicketId = lop.SourceTicketId
	INNER JOIN EquipmentMaster em
	ON tt.WorkcenterId = em.WorkcenterTypeId
	AND em.FacilityId = @facilityId
	WHERE  lop.IsOnPress = 1 OR lop.IsLocked = 1
	GROUP BY tt.TicketId

	DROP TABLE IF EXISTS #timecard;
	DROP TABLE IF EXISTS #latestruntime;
	DROP TABLE IF EXISTS #lastrun;
	DROP TABLE IF EXISTS #tasktime;
END