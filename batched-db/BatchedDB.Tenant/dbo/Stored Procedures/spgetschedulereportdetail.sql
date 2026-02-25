CREATE PROCEDURE [dbo].[spGetScheduleReportDetail]
    @startDate              AS DATETIME = NULL,
    @endDate                AS DATETIME = NULL,
    @equipments             AS [UDT_SINGLEFIELD] readonly,
    @facilities             AS UDT_SINGLEFIELD readonly,
    @sourceTicketNumbers    AS UDT_SINGLEFIELD readonly,
	@workcenters            AS UDT_SINGLEFIELD readonly,
    @valueStreams           AS UDT_SINGLEFIELDFILTER READONLY,
    @numberOfTimeCardDays   AS INT = 15
AS
BEGIN
    DECLARE 
        @IsMultiFacilitySchedulingEnabled   BIT = 0,
		@Yesterday							DATETIME = DATEADD(DAY, -1, GETUTCDATE()),
		@DayBeforeYesterday					DATETIME = DATEADD(DAY, -2, GETUTCDATE()),
        @Columns                            NVARCHAR(MAX),
        @StagingColumns                     NVARCHAR(MAX),
        @StagingQuery                       NVARCHAR(MAX);


	DROP TABLE IF EXISTS #schedulereportdetail;
    DROP TABLE IF EXISTS #RecentSchedules;
    DROP TABLE IF EXISTS #WMConsumingTickets;
    DROP TABLE IF EXISTS #WMProducingTickets;
    DROP TABLE IF EXISTS #wcmPTArrivalTime;
    DROP TABLE IF EXISTS #TempWorkcenterStagingRequirement;
    DROP TABLE IF EXISTS #TempStagingData;
	DROP TABLE IF EXISTS #TempStagingStatusData;

    
    SELECT @IsMultiFacilitySchedulingEnabled = CV.Value  
	FROM ConfigurationValue CV with (nolock)
	INNER JOIN ConfigurationMaster CM with (nolock) on CM.Id = CV.ConfigId
	Where CM.Name = 'EnableMultiFacilityScheduling';


    /** Get material consuming ticketIds **/
    SELECT 
        est.TicketId, 
		CASE 
			WHEN est.EstTimeOfArrival > est.FirstTaskDueDateTime THEN 0 
			ELSE 1 
		END AS IsCompletingOnTime	
    INTO #WMConsumingTickets	
    FROM (
        SELECT 
			DISTINCT tsa.TicketId, 
			tsa.FirstAvailableTime AS EstTimeOfArrival,
			ROW_NUMBER() OVER(PARTITION BY tsa.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
			tt.EstMaxDueDateTime AS FirstTaskDueDateTime		
        FROM TicketStockAvailability tsa with (nolock)		
        INNER JOIN TicketStockAvailabilityRawMaterialTickets tsarmt with (nolock) 
            ON tsa.Id = tsarmt.TicketStockAvailabilityId		
        INNER JOIN TicketTask tt with (nolock) 
            ON tsa.TicketId = tt.TicketId
		) AS est	
    WHERE est.Rno = 1;


    /** Get material producing ticketIds **/
    SELECT
        TicketId,
        EstTimeOfArrival	
    INTO #wcmPTArrivalTime	
    FROM (
        SELECT
			tti.TicketId AS TicketId,
			ROW_NUMBER() OVER(PARTITION BY tti.TicketId ORDER BY tsa.FirstAvailableTime DESC) AS Rno,
			tsa.FirstAvailableTime AS EstTimeOfArrival		
        FROM TicketStockAvailabilityRawMaterialTickets rmt with (nolock)		
        INNER JOIN TicketItemInfo tti  with (nolock)
				ON rmt.TicketItemInfoId = tti.Id		
        INNER JOIN TicketStockAvailability tsa with (nolock)
			ON rmt.TicketStockAvailabilityId = tsa.Id
		) AS t	
    WHERE  t.Rno = 1;
		
		
	SELECT 
		DISTINCT TicketId,  
		CASE 
			WHEN t.EstTimeOfArrival > t.FirstTaskDueDateTime THEN 0 
			ELSE 1 
		END AS IsCompletingOnTime
	INTO #WMProducingTickets
	FROM (
		SELECT 
			pt.TicketId, 
			pt.EstTimeOfArrival,  
			ROW_NUMBER() OVER(PARTITION BY pt.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
			tt.EstMaxDueDateTime AS FirstTaskDueDateTime
		FROM #wcmPTArrivalTime pt
		INNER JOIN TicketItemInfo tii with (nolock)
			ON pt.TicketId = tii.TicketId
		INNER JOIN TicketStockAvailabilityRawMaterialTickets rmt with (nolock)
			ON tii.Id = rmt.TicketItemInfoId
		INNER JOIN TicketStockAvailability tsa with (nolock)
			ON rmt.TicketStockAvailabilityId = tsa.Id
		INNER JOIN TicketTask tt with (nolock)
			ON tsa.TicketId = tt.TicketId
		) AS t
	WHERE t.Rno = 1;



    /* Get Staging status */
	-- Create a temp table to store the staging status data
	CREATE TABLE #TempStagingStatusData
	(
		[ScheduleId]    VARCHAR(36),
		[StagingStatus] VARCHAR(36)
	);

	-- Create a temp table to store the staging requirements wrt workcenters
	SELECT
        SRG.WorkcenterTypeId,
        STRING_AGG(CONCAT('Is', REPLACE(SRQ.Name, ' ', ''), 'Staged'), ',') AS StagingReq
    INTO #TempWorkcenterStagingRequirement
    FROM StagingRequirementGroup SRG
        INNER JOIN StagingRequirement SRQ ON SRG.StagingRequirementId = SRQ.Id
    GROUP BY SRG.WorkcenterTypeId;

	-- Get comma separated names of boolean columns 
    SELECT @Columns = STRING_AGG(COLUMN_NAME , ',')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

	-- Get comma separated names of boolean columns with status conditions
    SELECT @StagingColumns = STRING_AGG(CONCAT('CASE WHEN WSR.StagingReq IS NULL THEN NULL WHEN WSR.StagingReq LIKE ''%', COLUMN_NAME, '%'' THEN COALESCE(', COLUMN_NAME, ', 0) ELSE NULL END AS ', COLUMN_NAME), ',')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

	-- Create a dynamic query to populate the temp table of staging status
    SET @StagingQuery =
        'SELECT
            SR.Id AS ScheduleId,
            WSR.StagingReq,
            '+@StagingColumns+'
        INTO #TempStagingData
        FROM ScheduleReport SR
            INNER JOIN TicketMaster TM ON SR.SourceTicketId = TM.SourceTicketId
            INNER JOIN EquipmentMaster EM ON SR.EquipmentId = EM.ID
            LEFT JOIN #TempWorkcenterStagingRequirement WSR ON EM.WorkcenterTypeId = WSR.WorkcenterTypeId
            LEFT JOIN TicketTaskStagingInfo TTS ON TM.ID = TTS.TicketId AND SR.TaskName = TTS.Taskname;
            
        INSERT INTO #TempStagingStatusData
        SELECT 
            ScheduleId,
            CASE
                WHEN ' + REPLACE(@Columns, ',', ' IS NULL AND ') + ' IS NULL THEN ''Staged''
                WHEN COALESCE(' + REPLACE(@Columns, ',', ', 1) = 1 AND COALESCE(') + ', 1) = 1 THEN ''Staged''
                WHEN COALESCE(' + REPLACE(@Columns, ',', ', 0) = 0 AND COALESCE(') + ', 0) = 0 THEN ''Unstaged''
                ELSE ''Partially Staged''
            END AS StagingStatus
        FROM #TempStagingData;'

    -- Execute the dynamic query to populate temp table of staging status
    EXEC sp_executesql @StagingQuery;



    ;WITH
    timecard AS (
        /** Calculate a DateTime value for latest scan **/
        SELECT
            tc.equipmentid,
            tc.sourceticketid
            , startedon AS StartDateTime -- to adjust time stored as integer in DB
        FROM
            timecardinfo tc with (nolock)
        WHERE
             startedon > Dateadd(day,-@numberOfTimeCardDays,Getdate())
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
           tt.EstMaxDueDateTime AS TaskDueTime,
           ts.shipbydatetime,
           ts.ticketid,
           iscomplete,
           tm.sourceticketid,
           tt.taskname,
           tt.EstMeters,
           CASE 
                WHEN MAX(CASE
                            WHEN (tto.EstimatedMinutes IS NOT NULL OR tto.IsCompleted IS NOT NULL) THEN 1
                            ELSE 0
                        END) OVER (PARTITION BY tt.TicketId) = 1
                THEN 1 
                ELSE 0
           END AS IsTicketEdited,
           tt.[Sequence] AS TaskSequence
        FROM
            tickettask tt with (nolock)
            INNER JOIN ticketshipping ts with (nolock)
                ON ts.ticketid = tt.ticketid
            INNER JOIN ticketmaster tm with (nolock)
                ON tm.id = tt.ticketid
            LEFT JOIN TicketTaskOverride tto with (nolock)
                ON tto.TicketId = tt.TicketId AND tto.TaskName = tt.TaskName
        WHERE
            ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  tm.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
    ),
    schedule AS (
            SELECT
            sr.*,
            CASE
                WHEN iscomplete=1 THEN 'Complete'
                --WHEN lr.lastrunsourceticketid IS NOT NULL THEN 'On Press'
                WHEN tm.shipbydatetime IS NULL THEN 'Late'
                WHEN sr.endsat IS NULL THEN 'Unscheduled'
                WHEN Getdate()> tm.taskduetime OR sr.endsat > tm.taskduetime THEN 'Late'
                WHEN   Datediff(hh, Getdate(), tm.taskduetime) < 4
                    OR Datediff(hh, sr.endsat, tm.taskduetime) < 4 THEN 'At Risk'
                WHEN Getdate()>sr.endsat THEN 'Behind'
                ELSE 'On Track'
            END
                AS TaskStatus,
			CASE
				WHEN lr.lastrunsourceticketid IS NOT NULL THEN CAST(1 as bit)
				ELSE CAST(0 as bit)
			END AS IsOnPress,
			tm.EstMeters,
			tm.ShipByDateTime,
            tm.IsTicketEdited,
            tm.TaskSequence

            FROM schedulereport sr with (nolock)
            LEFT JOIN tasktime tm
                ON tm.sourceticketid = sr.sourceticketid
                AND tm.taskname = sr.taskname
            LEFT JOIN lastrun lr
                ON lr.lastrunsourceticketid = tm.sourceticketid
                AND lr.lastrunequipmentid = sr.equipmentid
            WHERE
                ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
                AND  ((SELECT Count(1) FROM @equipments) = 0 OR  sr.equipmentid IN (SELECT field FROM @equipments))
				AND (@startDate IS NULL OR @startDate <= sr.endsat)
				AND (@endDate IS NULL OR @endDate >= sr.startsat)
        ),
		ticketnotes as (
			select tm.id, STRING_AGG(notes,',') as notes from ticketgeneralnotes tn with (nolock) 
			inner join ticketmaster tm with (nolock) on tm.id = tn.ticketid
			WHERE
            ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 
			OR  tm.sourceticketid IN (SELECT field FROM @sourceTicketNumbers)
			OR  tm.sourceticketid IN (SELECT distinct sourceticketid FROM schedule))
			group by tm.id
		)
        SELECT
            s.Id,
            EM.Id AS EquipmentId,
            s.SourceTicketId,
            s.TaskName,
            s.StartsAt,
            s.EndsAt,
            s.ChangeoverMinutes,
            s.TaskMinutes,
            s.IsPinned,
            s.FeasibilityOverride,
            s.IsUpdated,
            s.IsCalculated,
            s.MasterRollNumber,
            s.CreatedOn,
            s.ModifiedOn,
            s.TaskStatus,
            s.IsOnPress,
            em.NAME AS EquipmentName,
            em.displayname AS EquipmentDisplayName,
            em.workcentertypeid,
            em.workcentername,
            em.facilityid,
			s.PinType as PinType,
			TM.CustomerName as CustomerName,
			s.ShipByDateTime as ShipByDateTime,
			SM.SourceStockId as Substrate,
			TSS.Width as StockWidth,
			TI.SourceToolingId as MainTool,
			s.EstMeters as EstimatedMeters,
			TM.GeneralDescription as GeneralDescription,
			TD.CoreSize as CoreSize,
			TD.CalcNumLeftoverRolls as NumberOfCores,
			ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketPoints,
			Varnish.Value as Varnish,
			Color.Value as Colors,
            CASE WHEN SO.ID IS NOT NULL THEN 1 ELSE 0 END AS IsManuallyScheduled,
            s.IsTicketEdited AS IsTicketEdited,
            (CASE WHEN s.MasterRollNumber IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) IsMasterRoll,
            s.ForcedGroup AS ForcedGroup,
            tn.Notes AS SchedulingNotes,
            TM.ID AS TicketId,
            s.TaskSequence,
            TM.TicketCategory AS TicketCategory,
            CASE 
				WHEN WMP.TicketId IS NOT NULL THEN 1
				WHEN WMC.TicketId IS NOT NULL THEN 2
				ELSE 0
			END AS WorkcenterMaterialTicketCategory,
            CASE 
				WHEN WMC.TicketId IS NOT NULL THEN WMC.IsCompletingOnTime
				WHEN WMP.TicketId IS NOT NULL THEN WMP.IsCompletingOnTime
				ELSE NULL
			END AS IsCompletingOnTime,
            SSD.StagingStatus,
            COALESCE(1 - (CAST(TD.ActualQuantity AS REAL) / NULLIF(CAST(TD.Quantity AS REAL), 0)), 0) * TM.EstTotalRevenue as WIPValue

        INTO #schedulereportdetail
        FROM equipmentmaster em with (nolock)
        LEFT JOIN schedule s ON em.id = s.equipmentid
		LEFT JOIN TicketMaster TM with (nolock) on Tm.SourceTicketId = s.SourceTicketId
		LEFT JOIN TicketStock TSS with (nolock) on TM.ID = TSS.TicketId and TSS.Sequence = 2
		LEFT JOIN StockMaterial SM with (nolock) on SM.Id = TSS.StockMaterialId
		LEFT JOIN TicketTool TTL with (nolock) on TM.ID = TTL.TicketId and TTL.Sequence = 1
		LEFT JOIN ToolingInventory TI with (nolock) on TTL.ToolingId = TI.Id
		LEFT JOIN TicketDimensions TD with (nolock) on TM.ID = TD.TicketId
		LEFT JOIN TicketScore TSC with (nolock) on TM.ID = TSC.TicketId
		LEFT JOIN TicketAttributeValues Varnish with (nolock) on TM.ID = Varnish.TicketId and Varnish.Name = 'Varnish'
		LEFT JOIN TicketAttributeValues Color with (nolock) on TM.ID = Color.TicketId and Color.Name = 'Colors'
        LEFT JOIN ScheduleOverride SO with (nolock) on TM.ID = SO.TicketId AND s.TaskName = SO.TaskName AND SO.IsScheduled = 1
		LEFT JOIN ticketnotes tn on tn.id = tm.id
        LEFT JOIN #WMConsumingTickets WMC ON TM.ID = WMC.TicketId
        LEFT JOIN #WMProducingTickets WMP ON TM.ID = WMP.TicketId
        LEFT JOIN #TempStagingStatusData SSD ON S.Id = SSD.ScheduleId
        WHERE
            ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
			AND EM.IsEnabled = 1 AND EM.AvailableForScheduling = 1


-- Latest schedule archives for each ticket-task between last 24 to 48 hours.
    SELECT
		Id,
        SourceTicketId,
        TaskName,
        ArchivedOnUTC,
        ROW_NUMBER() OVER (PARTITION BY SourceTicketId, TaskName ORDER BY ArchivedOnUTC DESC) AS RowNum
	INTO #RecentSchedules
    FROM ScheduleArchive
    WHERE ArchivedOnUTC < @Yesterday AND ArchivedOnUTC > @DayBeforeYesterday


 -- (Ticket-Task - not in latest schedule archive, but in schedule report - First day Scheduled)
	SELECT
		SRD.*,
        CASE
			WHEN RS.Id IS NULL THEN 1
            ELSE 0
		END AS IsFirstDay,
        'tbl_ScheduleReport' AS __dataset_tableName
    FROM #schedulereportdetail SRD
		LEFT JOIN #RecentSchedules RS ON SRD.SourceTicketId = RS.SourceTicketId AND SRD.TaskName = RS.TaskName AND RS.RowNum = 1

	
    -- tbl_EquipmentDowntime
	SELECT
        DISTINCT
        ed.Id AS Id,
        ed.EquipmentId AS EquipmentId, 
        ed.StartsOn AS StartsOn,
        ed.EndsAt AS EndsAt,
        ed.IsPlannedDowntime AS IsPlannedDowntime,
        ed.Name AS [Name],
        'tbl_EquipmentDowntime' AS __dataset_tableName 
    FROM equipmentdowntime ed with (nolock)
    LEFT JOIN EquipmentValueStream EVS with (nolock) ON EVS.EquipmentId = ed.EquipmentId
    LEFT JOIN EquipmentMaster EM with (nolock) ON EVS.EquipmentId = EM.ID
    WHERE
        ((SELECT Count(1) FROM @equipments) = 0 OR ed.equipmentid IN (SELECT field FROM @equipments))
		--AND (ed.equipmentid IN (SELECT equipmentid FROM #schedulereportdetail ))
        AND ((SELECT Count(1) FROM @facilities) = 0  OR EM.FacilityId  IN (SELECT field FROM @facilities))
        AND ((SELECT Count(1) FROM @valueStreams) = 0  OR EVS.ValueStreamId  IN (SELECT field FROM @valueStreams))
		AND (@startDate IS NULL OR @startDate <= ed.endsat)
		AND (@endDate IS NULL OR @endDate >= ed.startson)
		
    -- tbl_HolidaySchedule
	SELECT DISTINCT hs.id AS HolidayScheduleId, hs.date AS HolidayDate, hs.NAME, fh.facilityid, fh.id AS FacilityHolidayId, 'tbl_HolidaySchedule' AS __dataset_tableName
    FROM facilityholiday fh with (nolock)
    INNER JOIN holidayschedule hs with (nolock)
        ON fh.holidayid = hs.id
    LEFT JOIN EquipmentMaster em with (nolock)
        ON fh.FacilityId = em.FacilityId
    LEFT JOIN EquipmentValueStream evs with (nolock)
        ON evs.EquipmentId = em.ID
    WHERE
        (@startDate IS NULL OR hs.date >= CAST(@startDate AS DATE))
        AND (@endDate IS NULL OR hs.date <= CAST(@endDate AS DATE))
        --AND ((fh.facilityid IN (SELECT facilityid FROM #schedulereportdetail))
        AND (((SELECT Count(1) FROM @facilities)) = 0 OR  fh.facilityid IN (SELECT field FROM @facilities))
        AND ((((SELECT Count(1) FROM @valueStreams) = 0)) OR (evs.ValueStreamId IN (SELECT field FROM @valueStreams)))
		
        SELECT [Status],
		CASE WHEN (ExpiryTimeStamp <= GetUTCDATE()) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS isExpired, 'tbl_scheduleRunStatus' AS __dataset_tableName
		FROM scheduleRunStatus;

    ----- EnableMultiFacilityScheduling projection
	SELECT 
	    CASE WHEN @IsMultiFacilitySchedulingEnabled = 1 THEN 'True' ELSE 'False' END as isMultiFacilitySchedulingEnabled,
	    'tbl_isMultiFacilitySchedulingEnabled' AS __dataset_tableName


    ----- ValueStreams projection
	SELECT
        DISTINCT
        s.EquipmentId AS EquipmentId,
	    vs.Id AS ValueStreamID,
        vs.Name as ValueStreamName,
	    'tbl_ValueStreams' AS __dataset_tableName
        FROM 
            ValueStream vs with (nolock)
        INNER JOIN EquipmentValueStream evs with (nolock)
            ON vs.Id = evs.ValueStreamId
        INNER JOIN #schedulereportdetail s
            ON evs.EquipmentId = s.EquipmentId
        WHERE (((SELECT Count(1) FROM @facilities)) = 0 OR  s.FacilityId IN (SELECT field FROM @facilities))

END