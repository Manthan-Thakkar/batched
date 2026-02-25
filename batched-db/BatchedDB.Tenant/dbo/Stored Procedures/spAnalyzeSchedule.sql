CREATE PROCEDURE [dbo].[spAnalyzeSchedule]
@AnalysisDate AS datetime,
@facilities AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN

	DECLARE @Today datetime = @AnalysisDate;
	DECLARE @Yesterday datetime; 
	DECLARE @Tomorrow datetime;
	DECLARE @CalendarTomorrow datetime;
	DECLARE @CalendarYesterday datetime; 
	DECLARE @CalendarToday datetime;

	DECLARE @ScheduledAnalysisDate date;
	
	DECLARE @ActualAnalysisDate date;

	-- Result data
	DECLARE @ScheduledAnalysisInsertCount int;
	DECLARE @ActualAnalysisUpdateCount int;
	DECLARE @ScheduledEquipmentWiseInsertCount int;
	DECLARE @ActualEquipmentWiseUpdateCount int;


	SET @Yesterday = DATEADD(HOUR, -24, @Today)
	SET @Tomorrow = DATEADD(HOUR, 24, @Today)
	SET @CalendarToday = cast(@Today as Date)
	Set @CalendarYesterday = cast(@Yesterday as DATE)
	Set @CalendarTomorrow = cast(@Tomorrow as DATE)
	SET @ScheduledAnalysisDate = CAST(@Today AS DATE)
	SET @ActualAnalysisDate = CAST(@Yesterday AS DATE)

	SELECT 
		SourceTicketId,
		EquipmentId,
		TaskName,
		StartsAt,
		EndsAt,
		TaskMinutes,
		ChangeoverMinutes,
		ShipByDateTime,
		ArchivedOn,
		EM.FacilityId
	INTO #TodaysScheduleArchive
	FROM ScheduleArchive sa
	INNER JOIN EquipmentMaster em ON sa.EquipmentId = em.ID
	WHERE ArchivedOn >= @Today AND ArchivedOn < @Tomorrow AND ShipByDateTime IS NOT NULL
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))

	SELECT 
		EquipmentId,
		COUNT(TaskName) AS ScheduledTasksToBeCompleted
	INTO #ScheduledTasksToBeCompleted
	FROM #TodaysScheduleArchive
	WHERE EndsAt >= @Today AND EndsAt < @Tomorrow
	GROUP BY EquipmentId


	CREATE TABLE #FacilityWiseActualAnalysis (FacilityId varchar(36), ActualTicketsCompleted int, ActualMinutesCompleted int, ActualTicketsShippedOnTime int, ScheduledTicketsToBeShipped int)

	IF ((SELECT COUNT(1) FROM @facilities) > 0)
	BEGIN
		INSERT INTO #FacilityWiseActualAnalysis (FacilityId)
		SELECT Field FROM @facilities
	END
	ELSE
	BEGIN
		INSERT INTO #FacilityWiseActualAnalysis (FacilityId)
		SELECT Distinct FacilityId FROM EquipmentMaster WHERE IsEnabled = 1 AND AvailableForScheduling = 1
	END
	
	-- Schedule Equipmentwise Analysis
	IF NOT EXISTS(SELECT TOP 1 * FROM EquipmentScheduleAnalysis esa INNER JOIN EquipmentMaster em ON esa.EquipmentId = em.ID WHERE AnalysisDate = @ScheduledAnalysisDate AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities)))
	BEGIN

		INSERT INTO EquipmentScheduleAnalysis (Id, EquipmentId, SourceEquipmentId, ScheduledTasksToBeCompleted, 
			AnalysisDate, CreatedOn, ModifiedOn)
		SELECT 
			NEWID(),
			EM.Id AS EquipmentId,
			EM.SourceEquipmentId,
			ISNULL(STC.ScheduledTasksToBeCompleted, 0) AS ScheduledTasksToBeCompleted,
			@ScheduledAnalysisDate AS AnalysisDate,
			GETDATE(),
			GETDATE()
		FROM EquipmentMaster EM
		LEFT JOIN #ScheduledTasksToBeCompleted STC ON EM.ID = STC.EquipmentId
		WHERE EM.IsEnabled = 1 AND EM.AvailableForScheduling = 1
			AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))

		SET @ScheduledEquipmentWiseInsertCount = @@ROWCOUNT;
	END
	
	ELSE

	BEGIN
		UPDATE ESA
		SET 
			ScheduledTasksToBeCompleted = ISNULL(STC.ScheduledTasksToBeCompleted, 0),
			ModifiedOn = GETDATE()
		FROM EquipmentScheduleAnalysis ESA
		INNER JOIN EquipmentMaster EM
			ON ESA.EquipmentId = EM.ID
		LEFT JOIN #ScheduledTasksToBeCompleted STC
			ON EM.ID = STC.EquipmentId
		WHERE EM.IsEnabled = 1 AND AvailableForScheduling = 1 AND AnalysisDate = @ScheduledAnalysisDate
			AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities))

		SET @ScheduledEquipmentWiseInsertCount = @@ROWCOUNT;
	END

	-- Schedule Analysis

	SELECT 
		SUM((CASE WHEN TaskMinutes IS NULL THEN 0 ELSE TaskMinutes END) 
				+ (CASE WHEN ChangeoverMinutes IS NULL THEN 0 ELSE ChangeoverMinutes END)) AS ScheduledMinutesToBeCompleted,
				FacilityId
	INTO #ScheduledMinutesToBeCompleted
	FROM #TodaysScheduleArchive
	WHERE EndsAt >= @Today AND EndsAt < @Tomorrow
	GROUP BY FacilityId
	
	SELECT COUNT(DISTINCT SourceTicketId) AS ScheduledTicketsToBeCompleted, FacilityId
	INTO #ScheduledTicketsToBeCompleted
	FROM 
	(
		SELECT 
			SourceTicketId,
			FacilityId,
			MAX(EndsAt) as EndsAt
		FROM #TodaysScheduleArchive
		Group by SourceTicketId, FacilityId
	) AS SA
	WHERE SA.EndsAt >= @Today AND SA.EndsAt < @Tomorrow
	GROUP BY FacilityId

	IF NOT EXISTS(SELECT TOP 1 * FROM ScheduleAnalysis sa INNER JOIN #ScheduledTicketsToBeCompleted st ON sa.FacilityId = st.FacilityId WHERE AnalysisDate = @ScheduledAnalysisDate)
	BEGIN

		INSERT INTO ScheduleAnalysis (Id, ScheduledTicketsToBeCompleted, ScheduledMinutesToBeCompleted, AnalysisDate,  CreatedOn, ModifiedOn, FacilityId)
		SELECT NEWID(), st.ScheduledTicketsToBeCompleted, sm.ScheduledMinutesToBeCompleted, @ScheduledAnalysisDate, GETDATE(), GETDATE(), st.FacilityId
		FROM #ScheduledMinutesToBeCompleted sm
		INNER JOIN #ScheduledTicketsToBeCompleted st
		ON sm.FacilityId = st.FacilityId

		SET @ScheduledAnalysisInsertCount = @@ROWCOUNT;
	END
	
	ELSE

	BEGIN
		UPDATE sa
		SET 
			ScheduledTicketsToBeCompleted = st.ScheduledTicketsToBeCompleted,
			ScheduledMinutesToBeCompleted = sm.ScheduledMinutesToBeCompleted,
			ModifiedOn = GETDATE()
		FROM ScheduleAnalysis sa
		INNER JOIN #ScheduledTicketsToBeCompleted st ON sa.FacilityId = st.FacilityId
		INNER JOIN #ScheduledMinutesToBeCompleted sm ON sa.FacilityId = sm.FacilityId
		WHERE AnalysisDate = @ScheduledAnalysisDate
	END

	--Actual Analysis

	SELECT 
		EquipmentId,
		TicketId,
		SourceTicketId, 
		ElapsedTime, 
		StartedOn,
		CompletedAt,
		em.FacilityId AS FacilityId
	INTO #TodaysTimecardInfo
	FROM TimecardInfo tci
	INNER JOIN EquipmentMaster em on tci.EquipmentId = em.ID
	WHERE StartedOn >= @Yesterday AND StartedOn < @Today and em.AvailableForScheduling = 1 AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))

	SELECT 
		EquipmentId,  
		COUNT (distinct TicketId) AS ActualTasksCompleted
	INTO #ActualTasksCompleted
	FROM #TodaysTimecardInfo 
	GROUP BY EquipmentId

	--Actual Equipmentwise Analysis

	IF EXISTS(SELECT TOP 1 * FROM EquipmentScheduleAnalysis esa INNER JOIN #ActualTasksCompleted atc ON atc.EquipmentId = esa.EquipmentId WHERE AnalysisDate = @ActualAnalysisDate)
	BEGIN		
		UPDATE ESA
		SET 
			ActualTasksCompleted = ISNULL(ATD.ActualTasksCompleted, 0),
			ModifiedOn = GETDATE()
		FROM EquipmentScheduleAnalysis ESA
		INNER JOIN EquipmentMaster EM
			ON ESA.EquipmentId = EM.ID
		LEFT JOIN #ActualTasksCompleted ATD
			ON EM.ID = ATD.EquipmentId
		WHERE EM.IsEnabled = 1 AND EM.AvailableForScheduling = 1 AND AnalysisDate = @ActualAnalysisDate
			AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities))

		SET @ActualEquipmentWiseUpdateCount = @@ROWCOUNT;
	END

	ELSE

	BEGIN
		INSERT INTO EquipmentScheduleAnalysis (Id, EquipmentId, SourceEquipmentId, ActualTasksCompleted, 
			AnalysisDate, CreatedOn, ModifiedOn)
		SELECT 
			NEWID(),
			EM.Id AS EquipmentId,
			EM.SourceEquipmentId,
			ISNULL(ATC.ActualTasksCompleted, 0) AS ActualTasksCompleted,
			@ActualAnalysisDate AS AnalysisDate,
			GETDATE(),
			GETDATE()
		FROM EquipmentMaster EM
		LEFT JOIN #ActualTasksCompleted ATC ON EM.ID = ATC.EquipmentId
		WHERE EM.IsEnabled = 1 AND EM.AvailableForScheduling = 1
			AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId IN (SELECT field FROM @facilities))

		SET @ActualEquipmentWiseUpdateCount = @@ROWCOUNT;
	END

	--Actual Analysis

	--Actual Analysis
	;WITH ScheduledTicketsToBeShipped AS 
	( 
	SELECT 
		COUNT(DISTINCT tm.SourceTicketId) AS ScheduledTicketsToBeShipped,
		em.FacilityId AS FacilityId
	FROM TicketMaster tm
	INNER JOIN TicketShipping ts on tm.ID = ts.TicketId
	INNER JOIN EquipmentMaster em on TM.Press = EM.Name
	WHERE tm.SourceTicketType IN (0, 1, 2, 3, 4)
	AND ts.ShipByDateTime >= @CalendarYesterday AND ShipByDateTime < @CalendarToday
	AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
	GROUP BY em.FacilityId
	),

	ActualTicketsCompleted AS
	(
	SELECT  
		COUNT(DISTINCT tm.SourceTicketId) AS ActualTicketsCompleted,
		em.FacilityId AS FacilityId
	--INTO #ActualTicketsCompleted 
	FROM TicketMaster tm
	INNER JOIN TicketShipping TS ON Tm.ID = TS.TicketId
	INNER JOIN EquipmentMaster em on TM.Press = EM.Name
	WHERE TS.ShippedOnDate  >= @CalendarYesterday AND TS.ShippedOnDate < @CalendarToday and tm.SourceTicketType in (1,2,3,4)
	AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
	GROUP BY em.FacilityId
	),
	
	ActualMinutesCompleted AS
	(
	SELECT  
		SUM(CAST(DATEPART(second, ElapsedTime) 
		+ (DATEPART(minute, ElapsedTime) * 60) 
		+ (DATEPART(hour, ElapsedTime) * 3600) AS int) / 60.0) AS ActualMinutesCompleted,
		FacilityId
	FROM #TodaysTimecardInfo
	GROUP BY FacilityId
	),

	ActualTicketsShippedOnTime AS
	(
		SELECT
		 COUNT (DISTINCT tm.SourceTicketId) AS ActualTicketsShippedOnTime,
		 em.FacilityId
	FROM TicketMaster tm
	INNER JOIN TicketShipping ts on tm.ID = ts.TicketId
	INNER JOIN EquipmentMaster em on TM.Press = EM.Name
	WHERE ts.ShippedOnDate <= ts.ShipByDateTime
		AND ts.ShippedOnDate IS NOT NULL
		AND ts.ShipByDateTime >= @CalendarYesterday
		AND ts.ShipByDateTime < @CalendarToday
		AND tm.SourceTicketType IN (0,1,2,3,4)
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
	GROUP BY em.FacilityId
	)

	UPDATE fwaa
	SET 
		ActualTicketsCompleted = atc.ActualTicketsCompleted,
		ActualTicketsShippedOnTime = ats.ActualTicketsShippedOnTime,
		ActualMinutesCompleted = amc.ActualMinutesCompleted,
		ScheduledTicketsToBeShipped = st.ScheduledTicketsToBeShipped
	FROM #FacilityWiseActualAnalysis fwaa
	LEFT JOIN ScheduledTicketsToBeShipped st ON fwaa.FacilityId = st.FacilityId
	LEFT JOIN ActualTicketsCompleted atc ON fwaa.FacilityId = atc.FacilityId
	LEFT JOIN ActualMinutesCompleted amc ON  fwaa.FacilityId = amc.FacilityId
	LEFT JOIN ActualTicketsShippedOnTime ats ON fwaa.FacilityId = ats.FacilityId

	IF EXISTS (SELECT TOP 1 * FROM ScheduleAnalysis sa INNER JOIN #FacilityWiseActualAnalysis fwa ON sa.FacilityId = fwa.FacilityId WHERE AnalysisDate = @ScheduledAnalysisDate)
	BEGIN
		UPDATE sa
		SET 
			ActualTicketsCompleted = fwa.ActualTicketsCompleted,
			ActualMinutesCompleted = fwa.ActualMinutesCompleted,
			ActualTicketsShippedOnTime = fwa.ActualTicketsShippedOnTime,
			ScheduledTicketsToBeShipped = fwa.ScheduledTicketsToBeShipped,
			ModifiedOn = GETDATE()
		FROM ScheduleAnalysis sa
		INNER JOIN #FacilityWiseActualAnalysis fwa ON sa.FacilityId = fwa.FacilityId
		WHERE AnalysisDate = @ActualAnalysisDate

		SET @ActualAnalysisUpdateCount = @@ROWCOUNT;
	END

	ELSE

	BEGIN
		INSERT INTO ScheduleAnalysis (Id, ActualTicketsCompleted, ActualMinutesCompleted, ScheduledTicketsToBeShipped, ActualTicketsShippedOnTime, AnalysisDate,  CreatedOn, ModifiedOn, FacilityId)
		SELECT NEWID(), fwa.ActualTicketsCompleted, fwa.ActualMinutesCompleted, fwa.ScheduledTicketsToBeShipped, fwa.ActualTicketsShippedOnTime, @ActualAnalysisDate, GETDATE(), GETDATE(), fwa.FacilityId
		FROM #FacilityWiseActualAnalysis fwa

		SET @ActualAnalysisUpdateCount = @@ROWCOUNT;
	END

	-- result set
	SELECT 
		@ScheduledAnalysisInsertCount AS ScheduledAnalysisInsertCount,
		@ActualAnalysisUpdateCount AS ActualAnalysisUpdateCount,
		@ScheduledEquipmentWiseInsertCount AS ScheduledEquipmentWiseInsertCount,
		@ActualEquipmentWiseUpdateCount AS ActualEquipmentWiseUpdateCount,
		'tbl_analyzeScheduleResult' AS __dataset_tableName
	
	-- Drop temp tables
	BEGIN
		DROP TABLE IF EXISTS #TodaysScheduleArchive;
		DROP TABLE IF EXISTS #TodaysTimecardInfo;
		DROP TABLE IF EXISTS #ActualTasksCompleted;
		DROP TABLE IF EXISTS #ScheduledTasksToBeCompleted;
		DROP TABLE IF EXISTS #ScheduledTicketsToBeShipped;
		DROP TABLE IF EXISTS #ScheduledTicketsToBeCompleted;
		DROP TABLE IF EXISTS #ScheduledMinutesToBeCompleted;
		DROP TABLE IF EXISTS #FacilityWiseActualAnalysis;
	END

END