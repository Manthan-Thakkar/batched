CREATE PROCEDURE [dbo].[spArchiveScheduleData]
    @numberOfTimeCardDays AS int = 15,
    @facilities AS UDT_SINGLEFIELDFILTER readonly,	
    @currentLocalDate AS datetime  = NULL
AS
BEGIN

    DECLARE @FromDate datetime;
    DECLARE @ToDate datetime;
    DECLARE @currentUtcDate datetime = GETUTCDATE();
    IF(@currentLocalDate IS NULL)
        SET @currentLocalDate = GETDATE();

    SELECT @FromDate = CAST(CAST(@currentLocalDate as date) as datetime),
        @ToDate = DATEADD(SECOND, -1, CAST(CAST(DATEADD(DAY, 1, @currentLocalDate) as date) as datetime));

    -- Delete existing archived records if the archive had already executed.
    BEGIN
        DELETE sa FROM ScheduleArchive sa 
        INNER JOIN EquipmentMaster em on sa.OriginalEquipmentId = em.ID 
        WHERE (ArchivedOn BETWEEN @FromDate AND @ToDate) 
            AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
    END

    ;WITH TimeCard AS 
    (
        SELECT
            tci.EquipmentId AS EquipmentId,
            tci.SourceTicketId AS SourceTicketId, 
            tci.StartedOn AS StartDateTime
        FROM
            TimecardInfo tci
        WHERE
             tci.StartedOn > Dateadd(day,-@numberOfTimeCardDays,@currentLocalDate)
    ), 
    LatestRunTime AS 
    (
        SELECT
            tc.EquipmentId AS EquipmentId, 
            Max(tc.StartDateTime) AS MaxStartDateTime
        FROM
            TimeCard tc
        GROUP BY
            tc.EquipmentId
    ), 
    LastRun AS
    (
        SELECT
            lrt.EquipmentId AS LastRunEquipmentId, 
            Cast(tc.SourceTicketId AS NVARCHAR(255)) AS LastRunSourceTicketId
        FROM
            LatestRunTime lrt
        INNER JOIN TimeCard tc
            ON lrt.EquipmentId = tc.EquipmentId
            AND lrt.MaxStartDateTime = tc.StartDateTime
     ),
    TaskTime AS
    (
        SELECT
           tt.EstMaxDueDateTime AS TaskDueTime, 
           ts.ShipByDateTime AS ShipByDateTime, 
           ts.TicketId AS TicketId, 
           tt.IsComplete AS IsComplete, 
           tm.SourceTicketId AS SourceTicketId,
           tt.TaskName AS TaskName
        FROM
            TicketTask tt
            INNER JOIN TicketShipping ts
                ON ts.TicketId = tt.TicketId
            INNER JOIN TicketMaster tm
                ON tm.ID = tt.TicketId
    ),
    TaskStatuses AS 
    (
        SELECT
        sr.SourceTicketId,
        sr.TaskName,
        CASE
            WHEN tt.IsComplete = 1 THEN 'Complete'
            WHEN tt.ShipByDateTime IS NULL THEN 'Late'
            WHEN sr.EndsAt IS NULL THEN 'Unscheduled'
            WHEN @currentLocalDate> tt.TaskDueTime OR sr.EndsAt > tt.TaskDueTime THEN 'Late'
            WHEN Datediff(hh, @currentLocalDate, tt.TaskDueTime) < 4
                OR Datediff(hh, sr.EndsAt, tt.TaskDueTime) < 4 THEN 'At Risk'
            WHEN @currentLocalDate >sr.EndsAt THEN 'Behind'
            ELSE 'On Track'
        END
            AS TaskStatus           
        FROM ScheduleReport sr
        LEFT JOIN TaskTime tt
            ON tt.SourceTicketId = sr.SourceTicketId
            AND tt.TaskName = sr.TaskName
        LEFT JOIN LastRun lr
            ON lr.LastRunSourceTicketId = tt.SourceTicketId
            AND lr.LastRunEquipmentId = sr.EquipmentId
    )

    INSERT INTO ScheduleArchive (Id, ScheduleId, EquipmentId, OriginalEquipmentId, SourceTicketId, TaskName, 
        StartsAt, EndsAt, ChangeoverMinutes, TaskMinutes, IsPinned, FeasibilityOverride, IsUpdated, IsCalculated,
        MasterRollNumber, CreatedOn, ModifiedOn, PinType, ChangeoverCount, ChangeoverDescription, ForcedGroup,
        TicketId, EstMeters, TaskStatus, ShipByDateTime, Quantity, ActualQuantity, EstimatedLength, ArchivedOn, ArchivedOnUTC)
	SELECT 
        NEWID() AS Id,
        sr.Id AS ScheduleId,
        sr.EquipmentId AS EquipmentId,
        tt.OriginalEquipmentId AS OriginalEquipmentId,
        sr.SourceTicketId AS SourceTicketId,
        sr.TaskName AS TaskName,
        sr.StartsAt AS StartsAt,
        sr.EndsAt AS EndsAt,
        sr.ChangeoverMinutes AS ChangeoverMinutes,
        sr.TaskMinutes AS TaskMinutes,
        sr.IsPinned AS IsPinned,
        sr.FeasibilityOverride AS FeasibilityOverride,
        sr.IsUpdated AS IsUpdated,
        sr.IsCalculated AS IsCalculated,
        sr.MasterRollNumber AS MasterRollNumber,
        sr.CreatedOn AS CreatedOn,
        sr.ModifiedOn AS ModifiedOn,
        sr.PinType AS PinType,
        sr.ChangeoverCount AS ChangeoverCount,
        sr.ChangeoverDescription AS ChangeoverDescription,
        sr.ForcedGroup AS ForcedGroup,
        tm.ID AS TicketId,
        tt.EstMeters AS EstMeters,
        tss.TaskStatus AS TaskStatus,
        ts.ShipByDateTime AS ShipByDateTime,
        td.Quantity AS Quantity,
        td.ActualQuantity AS ActualQuantity,
        td.EstimatedLength AS EstimatedLength,
        @currentLocalDate AS ArchivedOn,
        @currentUtcDate AS ArchivedOnUTC
	FROM ScheduleReport sr
	INNER JOIN TicketMaster tm ON sr.SourceTicketId = tm.SourceTicketId
    LEFT JOIN TaskStatuses tss ON tss.SourceTicketId = sr.SourceTicketId AND tss.TaskName = sr.TaskName
	LEFT JOIN TicketShipping ts ON tm.Id = ts.TicketId
	LEFT JOIN TicketDimensions td ON tm.Id = td.TicketId
	LEFT JOIN TicketTask tt ON tt.TaskName = sr.TaskName AND tt.TicketId = tm.ID
    LEFT JOIN EquipmentMaster em ON sr.EquipmentId = em.Id
    WHERE ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
    
    DECLARE @TotalSchedulesArchived int = @@ROWCOUNT;
    DECLARE @TotalSchedulesCount int = (SELECT COUNT(1) FROM ScheduleReport);

    SELECT 
        @TotalSchedulesArchived AS TotalSchedulesArchived, 
        @TotalSchedulesCount AS TotalSchedulesCount,  
        'tbl_archiveScheduleResult' AS __dataset_tableName  
	
END
