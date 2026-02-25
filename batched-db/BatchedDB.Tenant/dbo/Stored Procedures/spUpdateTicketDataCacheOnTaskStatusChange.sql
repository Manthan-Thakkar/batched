CREATE PROCEDURE [dbo].[spUpdateTicketDataCacheOnTaskStatusChange]
    @CorelationId   AS VARCHAR(40) = NULL,
    @TenantId		AS VARCHAR(40) = NULL
AS
BEGIN
    DECLARE 
		@spName                 VARCHAR(100) = 'spUpdateTicketDataCacheOnTaskStatusChange',
        @Columns                NVARCHAR(MAX),
		@__ErrorInfoLog			__ErrorInfoLog,
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@maxCustomMessageSize   INT = 4000,
		@startTime				DATETIME,
		@blockName				VARCHAR(100),
		@IsError				BIT = 0,
        @StagingColumns         NVARCHAR(MAX),
        @StagingQuery           NVARCHAR(MAX);

    DROP TABLE IF EXISTS #TicketDeps;
    DROP TABLE IF EXISTS #FinalTicketDeps;
    DROP TABLE IF EXISTS #PartiallyRanDependentTickets;
    DROP TABLE IF EXISTS #tasktime;

    SET @blockName = 'tasktime';
    SET @startTime = GETDATE();

    SELECT distinct
        TTD.TicketId ,
        TTDp.DependentTicketId,
        TTD.TaskName,
        CASE 
		           WHEN COUNT(*) = SUM(CASE WHEN TTD2.IsComplete = 1 THEN 1 ELSE 0 END) THEN 1 
		           ELSE 0 
		    END AS IsAllTasksComplete
    INTO #TicketDeps
    FROM TicketTaskDependency TTDP with (nolock)
        INNER JOIN TicketTaskData TTD with (nolock) ON TTDP.TicketTaskDataId = TTD.Id
        INNER JOIN TicketTaskData TTD2 with (nolock) ON TTDP.DependentTicketTaskDataId = TTD2.Id
    GROUP BY TTDP.DependentTicketId, TTD.TicketId, TTD.TaskName

    Select TicketId,
        CASE 
		          WHEN COUNT(*) = SUM(CASE WHEN IsAllTasksComplete = 1 THEN 1 ELSE 0 END) THEN 1 
		          ELSE	0
		   END AS IsAllTasksCompleteFinal,
        TaskName
    INTO #FinalTicketDeps
    From #TicketDeps
    Group by TicketId, TaskName

    SELECT TicketId, CASE WHEN NetQuantityProduced > 0 AND IsComplete = 0 THEN 1 ELSE 0 END AS HasTaskPartiallyRan
    INTO #PartiallyRanDependentTickets
    FROM
        (
			SELECT TTD.TicketId, TTD2.NetQuantityProduced, CASE WHEN TTO.IsCompleted = 1 THEN 1 ELSE TT.IsComplete END AS IsComplete,
            ROW_NUMBER() OVER (PARTITION BY TT.TicketId ORDER BY TT.Sequence DESC) AS rn
        FROM TicketTaskDependency TTDP with (nolock)
            INNER JOIN TicketTaskData TTD with (nolock) ON TTDP.TicketTaskDataId = TTD.Id
            INNER JOIN TicketTaskData TTD2 with (nolock) ON TTDP.DependentTicketTaskDataId = TTD2.Id
            INNER JOIN TicketTask TT with (nolock) ON TTD2.TicketId = TT.TicketId AND TTD2.TaskName = TT.TaskName
            LEFT JOIN TicketTaskOverride TTO with (nolock) ON TTD2.TicketId = TTO.TicketId AND TTD2.TaskName = TTO.TaskName
		) AS sub
    WHERE rn = 1


    SELECT
        ts.ticketid,
        tt.taskname,
        tt.IsComplete,
        CASE WHEN td.TicketId IS NOT NULL AND td.IsAllTasksCompleteFinal = 0 THEN 0
		   WHEN td.TicketId IS NOT NULL AND td.IsAllTasksCompleteFinal = 1 THEN 1
           WHEN td.TicketId IS NULL OR td.IsAllTasksCompleteFinal = 1 THEN LAG(tt.IsComplete) OVER (PARTITION BY TT.TicketId ORDER BY tt.Sequence) ELSE NULL END AS PreviousIsComplete,
        CASE
				WHEN prdt.TicketId IS NOT NULL AND tt.Sequence = 1 THEN prdt.HasTaskPartiallyRan
				WHEN prdt.TicketId IS NULL THEN LAG(CASE WHEN TTD.NetQuantityProduced > 0 AND (CASE WHEN TTO.IsCompleted = 1 THEN 1 ELSE TT.IsComplete END) = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY TT.TicketId ORDER BY TT.Sequence)
				ELSE 0 
			END AS HasPreviousTaskPartiallyRan
    INTO #tasktime
    FROM
        tickettask tt with (nolock)
        INNER JOIN ticketshipping ts with (nolock)
        ON ts.ticketid = tt.ticketid
        INNER JOIN ticketmaster tm with (nolock)
        ON tm.id = tt.ticketid
        INNER JOIN TicketTaskData ttd
        ON tt.TicketId = ttd.TicketId AND tt.TaskName = ttd.TaskName
        LEFT JOIN TicketTaskOverride TTO with (nolock)
        ON TTO.TicketId = tt.TicketId and TTO.TaskName = tt.TaskName
        LEFT JOIN #FinalTicketDeps td with (nolock)
        ON (tt.TicketId = td.TicketId) and tt.TaskName =  td.TaskName
        LEFT JOIN #PartiallyRanDependentTickets prdt
        ON tt.TicketId = prdt.TicketId


    UPDATE SMC
			SET 
			SMC.HasPreviousTaskPartiallyRan = TT.HasPreviousTaskPartiallyRan,
			SMC.Highlight = CASE 
                WHEN TT.PreviousIsComplete = 0 THEN CAST(1 as BIT)
                ELSE CAST(0 as BIT)
            END,
			SMC.IsComplete = TT.IsComplete
			FROM TicketDataCache SMC
        JOIN #tasktime TT ON SMC.TicketId = TT.TicketId AND SMC.TaskName = TT.TaskName


    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

END;