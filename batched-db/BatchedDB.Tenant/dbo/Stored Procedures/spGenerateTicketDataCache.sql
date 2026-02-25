CREATE PROCEDURE [dbo].[spGenerateTicketDataCache]
    @currentLocalDate		AS Datetime  = NULL,
    @CorelationId           AS VARCHAR(40) = NULL,
    @TenantId				AS VARCHAR(40) = NULL
AS
BEGIN

    DECLARE 
		@spName                         VARCHAR(100) = 'spGenerateTicketDataCache',
		@__ErrorInfoLog				    __ErrorInfoLog,
		@maxCustomMessageSize           INT = 4000,
		@blockName						VARCHAR(100),
        @Columns                        NVARCHAR(MAX),
        @StagingColumns                 NVARCHAR(MAX),
        @StagingQuery                   NVARCHAR(MAX),
		@warningStr						NVARCHAR(4000),
		@infoStr						NVARCHAR(4000),
		@errorStr						NVARCHAR(4000),
		@Yesterday						DATETIME = DATEADD(DAY, -1, GETUTCDATE()),
		@DayBeforeYesterday             DATETIME = DATEADD(DAY, -2, GETUTCDATE()),
		@IsError						BIT = 0,
		@startTime						DATETIME,
		@numberOfTimeCardDays	        INT = 15,
		@IsStockAvailabilityEnabled		BIT = 0;

    DROP TABLE IF EXISTS [dbo].[#TicketDetails];
    DROP TABLE IF EXISTS [dbo].[#TicketToolData];
    DROP TABLe IF EXISTs [dbo].[#TicketStockData];
    DROP TABLE IF EXISTS [dbo].[#equipmentValueStreams];
    DROP TABLE IF EXISTS [dbo].[#workcenterMaterialProducingTickets];
    DROP TABLE IF EXISTS [dbo].[#workcenterMaterialConsumingTickets];
    DROP TABLE IF EXISTS [dbo].[#wcmPTArrivalTime];
    DROP TABLE IF EXISTS [dbo].[#sortedPaginatedReport];
    DROP TABLE IF EXISTS [dbo].[#DistinctTicketsWithNotes]
    DROP TABLE IF EXISTS [dbo].[#RecentSchedules];
    DROP TABLE IF EXISTS [dbo].[#tasktime];
    DROP TABLE IF EXISTS [dbo].[#TempWorkcenterStagingRequirement];
    DROP TABLE IF EXISTS [dbo].[#TempStagingData];
    DROP TABLE IF EXISTS [dbo].[#TempStagingStatusData];
    DROP TABLE IF EXISTS [dbo].[#PartiallyRanDependentTickets];
    DROP TABLE IF EXISTS [dbo].[#PartiallyRanDistinctDependentTickets];
    DROP TABLE IF EXISTS [dbo].[#TicketDeps];
    DROP TABLE IF EXISTS [dbo].[#FinalTicketDeps];
    DROP TABLE IF EXISTS [dbo].[#TicketColors];
    DROP TABLE IF EXISTS [dbo].[#TicketPlates];
    DROP TABLE IF EXISTS [dbo].[#ColumnPerfData];
    DROP TABLE IF EXISTS [dbo].[#RowPerfData];
    DROP TABLE IF EXISTS [dbo].[#TicketDependentRaw];



    SET @blockName = 'AutomaticStockAvailability';
    SET @startTime = GETDATE();

    SELECT @IsStockAvailabilityEnabled = [CV].[Value]
    FROM [dbo].[ConfigurationValue] CV WITH (NOLOCK)
        INNER JOIN [dbo].[ConfigurationMaster] CM WITH (NOLOCK) ON [CM].[Id] = [CV].[ConfigId]
    WHERE [CM].[Name] = 'EnableAutomaticStockAvailability';

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'tasktime';
    SET @startTime = GETDATE();

    SELECT DISTINCT
        [TTD].[TicketId],
        [TTDP].[DependentTicketId],
        [TTD].[TaskName],
        MIN(IIF([TTD2].[IsComplete] = 1, 1, 0)) AS [IsAllTasksComplete]
    INTO [dbo].[#TicketDeps]
    FROM [dbo].[TicketTaskDependency] TTDP WITH (NOLOCK)
        INNER JOIN [dbo].[TicketTaskData] TTD WITH (NOLOCK) ON [TTDP].[TicketTaskDataId] = TTD.Id
        INNER JOIN [dbo].[TicketTaskData] TTD2 WITH (NOLOCK) ON [TTDP].[DependentTicketTaskDataId] = TTD2.Id
    GROUP BY [TTDP].[DependentTicketId], [TTD].[TicketId], [TTD].[TaskName];


    SELECT
        [TicketId],
        [TaskName],
        MIN(IIF([IsAllTasksComplete] = 1, 1, 0)) AS [IsAllTasksCompleteFinal]
    INTO [dbo].[#FinalTicketDeps]
    FROM [dbo].[#TicketDeps]
    GROUP by [TicketId], [TaskName];


    SELECT
        [TicketId],
        IIF([NetQuantityProduced] > 0 AND [IsComplete] = 0, 1, 0) AS [HasTaskPartiallyRan]
    INTO [dbo].[#PartiallyRanDependentTickets]
    FROM
        (
                SELECT
            [TTD].[TicketId],
            [TTD2].[NetQuantityProduced],
            IIF([TTO].[IsCompleted] = 1, 1, [TT].[IsComplete]) AS [IsComplete],
            ROW_NUMBER() OVER (PARTITION BY [TT].[TicketId] ORDER BY [TT].[Sequence] DESC) AS [rn]
        FROM [dbo].[TicketTaskDependency] TTDP WITH (NOLOCK)
            INNER JOIN [dbo].[TicketTaskData] TTD WITH (NOLOCK) ON [TTDP].[TicketTaskDataId] = [TTD].[Id]
            INNER JOIN [dbo].[TicketTaskData] TTD2 WITH (NOLOCK) ON [TTDP].[DependentTicketTaskDataId] = [TTD2].[Id]
            INNER JOIN [dbo].[TicketTask_temp] TT WITH (NOLOCK) ON [TTD2].[TicketId] = [TT].[TicketId] AND [TTD2].[TaskName] = [TT].[TaskName]
            LEFT JOIN [dbo].[TicketTaskOverride] TTO WITH (NOLOCK) ON [TTD2].[TicketId] = [TTO].[TicketId] AND [TTD2].[TaskName] = [TTO].[TaskName]
            ) AS [sub]
    WHERE rn = 1;


    SELECT
        [TicketId],
        MAX([HasTaskPartiallyRan]) AS [HasTaskPartiallyRan]
    INTO [dbo].[#PartiallyRanDistinctDependentTickets]
    FROM [dbo].[#PartiallyRanDependentTickets]
    GROUP BY [TicketId];


    SELECT
        [ts].[shipbydatetime],
        [ts].[ticketid],
        [tm].[sourceticketid],
        [tt].[taskname],
        IIF([TTO].[EstimatedMinutes] IS NOT NULL, 1, 0) AS [IsEstMinsEdited],
        IIF([TTO].[IsCompleted] IS NOT NULL, 1, 0) AS [IsStatusEdited],
        CASE 
                WHEN [td].[TicketId] IS NOT NULL AND [td].[IsAllTasksCompleteFinal] = 0 THEN 0
                WHEN [td].[TicketId] IS NOT NULL AND [td].[IsAllTasksCompleteFinal] = 1 THEN 1
                WHEN [td].[TicketId] IS NULL OR [td].[IsAllTasksCompleteFinal] = 1 THEN LAG([tt].[IsComplete]) OVER (PARTITION BY [TT].[TicketId] ORDER BY [tt].[Sequence])
                ELSE NULL
            END AS [PreviousIsComplete],
        CASE
				WHEN [prdt].[TicketId] IS NOT NULL AND [tt].[Sequence] = 1 THEN [prdt].[HasTaskPartiallyRan]
				WHEN [prdt].[TicketId] IS NULL THEN LAG(
                    CASE
                        WHEN [TTD].[NetQuantityProduced] > 0 AND ([TTO].[IsCompleted] = 1 OR [TT].[IsComplete] = 0) THEN 1
                        ELSE 0
                    END) OVER (PARTITION BY [TT].[TicketId] ORDER BY [TT].[Sequence])
				ELSE 0 
			END AS [HasPreviousTaskPartiallyRan]
    INTO [dbo].[#tasktime]
    FROM
        [dbo].[TicketTask_temp] tt WITH (NOLOCK)
        INNER JOIN [dbo].[ticketshipping] ts WITH (NOLOCK) ON [ts].[ticketid] = [tt].[ticketid]
        INNER JOIN [dbo].[ticketmaster] tm WITH (NOLOCK) ON [tm].[id] = [tt].[ticketid]
        INNER JOIN [dbo].[TicketTaskData] ttd WITH (NOLOCK) ON [tt].[TicketId] = [ttd].[TicketId] AND [tt].[TaskName] = [ttd].[TaskName]
        LEFT JOIN [dbo].[TicketTaskOverride] TTO WITH (NOLOCK) ON [TTO].[TicketId] = [tt].[TicketId] AND [TTO].[TaskName] = [tt].[TaskName]
        LEFT JOIN [dbo].[#FinalTicketDeps] td ON [tt].[TicketId] = [td].[TicketId] AND [tt].[TaskName] = [td].[TaskName]
        LEFT JOIN [dbo].[#PartiallyRanDistinctDependentTickets] prdt ON [tt].[TicketId] = [prdt].[TicketId];


    CREATE NONCLUSTERED INDEX [IX_TaskTime_Temp]
            ON [dbo].[#tasktime] ([sourceticketid], [taskname])
            INCLUDE ([shipbydatetime]);

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'Get Recent Schedule Archives';
    SET @startTime = GETDATE();
    -- Latest schedule archives for each ticket-task between last 24 to 48 hours.

    SELECT
        [Id],
        [SourceTicketId],
        [TaskName],
        [ArchivedOnUTC],
        ROW_NUMBER() OVER (PARTITION BY [SourceTicketId], [TaskName] ORDER BY [ArchivedOnUTC] DESC) AS [RowNum]
    INTO [dbo].[#RecentSchedules]
    FROM [dbo].[ScheduleArchive]
    WHERE [ArchivedOnUTC] < @Yesterday AND [ArchivedOnUTC] > @DayBeforeYesterday;

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'Ticket Tool Data';
    SET @startTime = GETDATE();


    ;WITH [TempTicketTools] AS (
        SELECT
            [TicketId],
            [Sequence],
            [Description]
        FROM [dbo].[TicketTool] WITH (NOLOCK)
        WHERE [RoutingNumber] IS NULL
    )
    SELECT
        [TT].[TicketId],
        [TT1].[Description] AS [Tool1Desc],
        [TT2].[Description] AS [Tool2Desc],
        [TT3].[Description] AS [Tool3Desc],
        [TT4].[Description] AS [Tool4Desc],
        [TT5].[Description] AS [Tool5Desc]
    INTO [dbo].[#TicketToolData]
    FROM [TempTicketTools] AS [TT]
        LEFT JOIN [TempTicketTools] AS [TT1] ON [TT1].[TicketId] = [TT].[TicketId] AND [TT1].[Sequence] = 1
        LEFT JOIN [TempTicketTools] AS [TT2] ON [TT2].[TicketId] = [TT].[TicketId] AND [TT2].[Sequence] = 2
        LEFT JOIN [TempTicketTools] AS [TT3] ON [TT3].[TicketId] = [TT].[TicketId] AND [TT3].[Sequence] = 3
        LEFT JOIN [TempTicketTools] AS [TT4] ON [TT4].[TicketId] = [TT].[TicketId] AND [TT4].[Sequence] = 4
        LEFT JOIN [TempTicketTools] AS [TT5] ON [TT5].[TicketId] = [TT].[TicketId] AND [TT5].[Sequence] = 5;



    CREATE NONCLUSTERED INDEX [IX_TicketToolData_Temp]
            ON [dbo].[#TicketToolData] ([TicketId])
            INCLUDE ([Tool1Desc], [Tool2Desc], [Tool3Desc], [Tool4Desc], [Tool5Desc]);

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'Ticket Stock Data';
    SET @startTime = GETDATE();

    ;WITH [TempTicketStocks] AS (
        SELECT
            [TicketId],
            [Sequence],
            [Notes]
        FROM [dbo].[TicketStock] WITH (NOLOCK)
        WHERE RoutingNo IS NULL
    )
    SELECT
        [T].[TicketId] ,
        [TT1].[Notes] AS [Stock1Desc],
        [TT2].[Notes] AS [Stock2Desc],
        [TT3].[Notes] AS [Stock3Desc]
    INTO [dbo].[#TicketStockData]
    FROM [TempTicketStocks] T
        LEFT JOIN [TempTicketStocks] TT1 ON [TT1].[TicketId] = [T].[TicketId] AND [TT1].[Sequence] = 1
        LEFT JOIN [TempTicketStocks] TT2 ON [TT2].[TicketId] = [T].[TicketId] AND [TT2].[Sequence] = 2
        LEFT JOIN [TempTicketStocks] TT3 ON [TT3].[TicketId] = [T].[TicketId] AND [TT3].[Sequence] = 3;


    CREATE NONCLUSTERED INDEX [IX_TicketStockData_Temp]
            ON [dbo].[#TicketStockData] ([TicketId])
            INCLUDE ([Stock1Desc], [Stock2Desc], [Stock3Desc]);

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'ticketGeneralNotes';
    SET @startTime = GETDATE();
    -- Distinct tickets WITH general notes
    SELECT DISTINCT [TicketId]
    INTO [dbo].[#DistinctTicketsWithNotes]
    FROM [dbo].[TicketGeneralNotes] WITH (NOLOCK);

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'stagingStatusData';
    SET @startTime = GETDATE();

    -- Create a temp table to store the staging status data
    CREATE TABLE [dbo].[#TempStagingStatusData]
    (
        [TicketId] VARCHAR(36),
        [TaskName] NVARCHAR(255),
        [StagingStatus] VARCHAR(36)
    );

    -- Create a temp table to store the staging requirements wrt workcenters
    SELECT
        [SRG].[WorkcenterTypeId],
        STRING_AGG(CONCAT('Is', REPLACE([SRQ].[Name], ' ', ''), 'Staged'), ',') AS [StagingReq]
    INTO [dbo].[#TempWorkcenterStagingRequirement]
    FROM [dbo].[StagingRequirementGroup] SRG
        INNER JOIN [dbo].[StagingRequirement] SRQ ON [SRG].[StagingRequirementId] = [SRQ].[Id]
    GROUP BY [SRG].[WorkcenterTypeId];

    -- Get comma separated names of boolean columns 
    SELECT @Columns = STRING_AGG(COLUMN_NAME , ',')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

    -- Get comma separated names of boolean columns WITH status conditions
    SELECT @StagingColumns = STRING_AGG(CONCAT('CASE WHEN [WSR].[StagingReq] IS NULL THEN NULL WHEN [WSR].[StagingReq] LIKE ''%', COLUMN_NAME, '%'' THEN COALESCE(', COLUMN_NAME, ', 0) ELSE NULL END AS ', COLUMN_NAME), ',')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

    -- Create a dynamic query to populate the temp table of staging status
    SET @StagingQuery =
            'SELECT
                [TM].[Id] AS [TicketId],
				[TT].[TaskName] AS [TaskName],
                [WSR].[StagingReq],
                '+@StagingColumns+'
            INTO [dbo].[#TempStagingData]
            FROM [dbo].[TicketTask_temp] TT WITH (NOLOCK)
                INNER JOIN [dbo].[TicketMaster] TM WITH (NOLOCK) ON [TT].[TicketId] = [TM].[Id]
                INNER JOIN [dbo].[EquipmentMaster] EM WITH (NOLOCK) ON [TT].[OriginalEquipmentId] = [EM].[ID]
                LEFT JOIN [dbo].[#TempWorkcenterStagingRequirement] WSR ON [EM].[WorkcenterTypeId] = [WSR].[WorkcenterTypeId]
                LEFT JOIN [dbo].[TicketTaskStagingInfo] TTS WITH (NOLOCK) ON [TM].[ID] = [TTS].[TicketId] AND [TT].[TaskName] = [TTS].[Taskname]
			WHERE [TT].[IsComplete] = 0;
            
            INSERT INTO [dbo].[#TempStagingStatusData]
            SELECT 
                [TicketId],
				[TaskName],
                CASE
                    WHEN ' + REPLACE(@Columns, ',', ' IS NULL AND ') + ' IS NULL THEN ''Staged''
                    WHEN COALESCE(' + REPLACE(@Columns, ',', ', 1) = 1 AND COALESCE(') + ', 1) = 1 THEN ''Staged''
                    WHEN COALESCE(' + REPLACE(@Columns, ',', ', 0) = 0 AND COALESCE(') + ', 0) = 0 THEN ''Unstaged''
                    ELSE ''Partially Staged''
                END AS [StagingStatus]
            FROM [dbo].[#TempStagingData];'

    -- Execute the dynamic query to populate temp table of staging status
    EXEC sp_executesql @StagingQuery;

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'Ticket Data cache';
    SET @startTime = GETDATE();

    SELECT
        [em].[FacilityId],
        [evs].[EquipmentId],
        STRING_AGG([evs].[ValueStreamId],', ') AS [valuestreams]
    INTO [dbo].[#equipmentValueStreams]
    FROM [dbo].[EquipmentValueStream] evs WITH (NOLOCK)
        JOIN [dbo].[EquipmentMaster] em WITH (NOLOCK) ON [em].[ID] = [evs].[EquipmentId]
    GROUP BY [EM].[FacilityId], [evs].[EquipmentId];


    SELECT
        [est].[TicketId],
        IIF([est].[EstTimeOfArrival] > [est].[FirstTaskDueDateTime], 0, 1) AS [IsCompletingOnTime]
    INTO [dbo].[#workcenterMaterialConsumingTickets]
    FROM
        (
			SELECT DISTINCT
            [tsa].[TicketId],
            [tsa].[FirstAvailableTime] AS [EstTimeOfArrival],
            ROW_NUMBER() OVER(PARTITION BY [tsa].[TicketId] ORDER BY [tt].[EstMaxDueDateTime]) AS [Rno],
            [tt].[EstMaxDueDateTime] AS [FirstTaskDueDateTime]
        FROM [dbo].[TicketStockAvailability_temp] tsa WITH (NOLOCK)
            INNER JOIN [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] tsarmt WITH (NOLOCK) ON [tsa].[Id] = [tsarmt].[TicketStockAvailabilityId]
            INNER JOIN [dbo].[TicketTask_Temp] tt WITH (NOLOCK) ON [tsa].[TicketId] = [tt].[TicketId]
		) [est]
    WHERE [est].[Rno] = 1;


    SELECT
        [TicketId],
        [EstTimeOfArrival]
    INTO [dbo].[#wcmPTArrivalTime]
    FROM
        (
			SELECT
            [tti].[TicketId] AS [TicketId],
            ROW_NUMBER() OVER(PARTITION BY [tti].[TicketId] ORDER BY [tsa].[FirstAvailableTime] DESC) AS [Rno],
            [tsa].[FirstAvailableTime] AS [EstTimeOfArrival]
        FROM [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] rmt WITH (NOLOCK)
            INNER JOIN [dbo].[TicketItemInfo] tti WITH (NOLOCK) ON [rmt].[TicketItemInfoId] = [tti].[Id]
            INNER JOIN [dbo].[TicketStockAvailability_temp] tsa WITH (NOLOCK) ON [rmt].[TicketStockAvailabilityId] = [tsa].[Id]
		) [t]
    WHERE [t].[Rno] = 1;


    SELECT DISTINCT
        [TicketId],
        IIF([t].[EstTimeOfArrival] > [t].[FirstTaskDueDateTime], 0, 1) AS [IsCompletingOnTime]
    INTO [dbo].[#workcenterMaterialProducingTickets]
    FROM
        (
			SELECT
            [pt].[TicketId],
            [pt].[EstTimeOfArrival],
            ROW_NUMBER() OVER(PARTITION BY [pt].[TicketId] ORDER BY [tt].[EstMaxDueDateTime]) AS [Rno],
            [tt].[EstMaxDueDateTime] AS [FirstTaskDueDateTime]
        FROM [dbo].[#wcmPTArrivalTime] pt
            INNER JOIN [dbo].[TicketItemInfo] tii WITH (NOLOCK) ON [pt].[TicketId] = [tii].[TicketId]
            INNER JOIN [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] rmt WITH (NOLOCK) ON [tii].[Id] = [rmt].[TicketItemInfoId]
            INNER JOIN [dbo].[TicketStockAvailability_temp] tsa WITH (NOLOCK) ON [rmt].[TicketStockAvailabilityId] = [tsa].[Id]
            INNER JOIN [dbo].[TicketTask_Temp] tt WITH (NOLOCK) ON [tsa].[TicketId] = [tt].[TicketId]
		) [t]
    WHERE [t].[Rno] = 1;


    -- Ticket colors
    ;WITH [TempColor] AS (
        SELECT DISTINCT
            [TII].[TicketId],
            [PCI].[SourceColor],
            [PCI].[SourceInkType]
        FROM [dbo].[TicketItemInfo] TII WITH (NOLOCK)
            INNER JOIN [dbo].[ProductColorInfo] PCI WITH (NOLOCK) ON [PCI].[ProductId] = [TII].[ProductId]
    )
    SELECT DISTINCT
        [TicketId],
        LEFT(STRING_AGG(CONVERT(NVARCHAR(max), CONCAT([SourceColor], ' (', ISNULL([SourceInkType], 'N/A'), ')')), ', '), 4000) AS [Colors]
    INTO [dbo].[#TicketColors]
    FROM [TempColor]
    GROUP BY [TicketId];

    CREATE NONCLUSTERED INDEX [IX_TempColor_Temp]
            ON [dbo].[#TicketColors] ([TicketId])
            INCLUDE ([Colors]);


    -- Ticket plates
    SELECT
        [TII].[TicketId],
        LEFT(STRING_AGG(CONVERT(NVARCHAR(max), [PM].[PlateId]), ', '), 4000) AS [Plates]
    INTO [dbo].[#TicketPlates]
    FROM [dbo].[TicketItemInfo] TII WITH (NOLOCK)
        INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON [PM].[Id] = [TII].[ProductId]
    GROUP BY [TII].[TicketId];

    CREATE NONCLUSTERED INDEX [IX_TicketPlates_Temp]
            ON [dbo].[#TicketPlates] ([TicketId])
            INCLUDE ([Plates]);


    -- Column perfs
    ;WITH [ColumnPerfCalc] AS (
        SELECT DISTINCT
            [TII].[TicketId],
            [PM].[ColumnPerf]
        FROM [dbo].[TicketItemInfo] TII WITH (NOLOCK)
            INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON [PM].[Id] = [TII].[ProductId]
    )
    SELECT DISTINCT
        [TicketId],
        LEFT(STRING_AGG(CONVERT(NVARCHAR(max), ColumnPerf), ', '), 4000) AS [ColumnPerf]
    INTO [dbo].[#ColumnPerfData]
    FROM [ColumnPerfCalc]
    GROUP BY [TicketId];

    CREATE NONCLUSTERED INDEX [IX_ColumnPerf_Temp]
            ON [dbo].[#ColumnPerfData] ([TicketId])
            INCLUDE ([ColumnPerf]);


    -- Row perfs
    ;WITH [RowPerfCalc] AS (
        SELECT DISTINCT
            [TII].[TicketId],
            [PM].[RowPerf]
        FROM [dbo].[TicketItemInfo] TII WITH (NOLOCK)
            INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON [PM].[Id] = [TII].[ProductId]
    )
    SELECT DISTINCT
        [TicketId],
        LEFT(STRING_AGG(CONVERT(NVARCHAR(max), RowPerf), ', '), 4000) AS [RowPerf]
    INTO [dbo].[#RowPerfData]
    FROM [RowPerfCalc]
    GROUP BY [TicketId];

    CREATE NONCLUSTERED INDEX [IX_RowPerf_Temp]
            ON [dbo].[#RowPerfData] ([TicketId])
            INCLUDE ([RowPerf]);



   
   -- fetch IsDependentProdReady
    SELECT 
        TTD.TicketId,
        CAST(
                CASE 
                    WHEN ISNULL(MIN(CAST(TT.IsProductionReady AS INT)), 0) = 1 THEN 1
                    ELSE 0
                END AS BIT
            ) AS IsDependentProdReady,
        TTDP.DependentTicketId  
    INTO #TicketDependentRaw
    FROM TicketTaskDependency TTDP WITH (NOLOCK)
        INNER JOIN TicketTask TT WITH (NOLOCK) ON TT.TicketId = TTDP.DependentTicketId
        INNER JOIN TicketTaskData TTD WITH (NOLOCK) ON TTDP.TicketTaskDataId = TTD.Id
    GROUP BY TTDP.DependentTicketId, TTD.TicketId;

    CREATE NONCLUSTERED INDEX [IX_TicketDependentRaw_Temp]
            ON [dbo].[#TicketDependentRaw] ([TicketId])
            INCLUDE ([IsDependentProdReady],[DependentTicketId]);



    SELECT
        DISTINCT
        --- Ticket Fields 
        [TM].[ID] AS [TicketId],
        [TM].[SourceTicketId] AS [TicketNumber],
        [TTT].[TaskName] AS [TaskName],
        [TTT].[IsComplete],
        [TTT].[EstMeters] AS [TaskEstimatedMeters],
        [TM].[CustomerName] AS [CustomerName],
        [TM].[GeneralDescription] AS [GeneralDescription],
        ISNULL([TSC].[CustomerRankScore], 0) * ISNULL([TSC].[DueDateScore], 0) * ISNULL([TSC].[PriorityScore], 0) * ISNULL([TSC].[RevenueScore], 0) AS [TicketPoints],
        [TS].[ShipByDateTime] AS [ShipByDate],
        [TM].[OrderDate] AS [OrderDate],
        [TM].[SourceCustomerId] AS [SourceCustomerId],
        [Tm].[CustomerPO] AS [CustomerPO],
        [TM].[SourcePriority] AS [TicketPriority],
        [TM].[SourceFinishType] AS [FinishType],
        [TM].[isBackSidePrinted] AS [IsBackSidePrinted],
        [TM].[IsSlitOnRewind] AS [IsSlitOnRewind],
        [TM].[UseTurretRewinder] AS [UseTurretRewinder],
        [TM].[EstTotalRevenue] AS [EstTotalRevenue],
        [Tm].[SourceTicketType] AS [TicketType],
        [TM].[PriceMode] AS [PriceMode],
        [TM].[FinalUnwind] AS [FinalUnwind],
        [TM].[SourceStatus] AS [TicketStatus],
        [TM].[BackStageColorStrategy] AS [BackStageColorStrategy],
        [TM].[Pinfeed] AS [Pinfeed],
        [TM].[IsPrintReversed] AS [IsPrintReversed],
        [Tm].[SourceTicketNotes] AS [TicketNotes],
        [Tm].[EndUserNum]  AS [EndUserNum],
        [TM].[EndUserName] AS [EndUserName],
        [TM].[SourceCreatedOn] AS [CreatedOn],
        [TM].[SourceModifiedOn] AS [ModifiedOn],
        [TM].[Tab] AS [Tab],
        [TM].[SizeAround] AS [SizeAround],
        [TM].[ShrinkSleeveLayFlat] AS [ShrinkSleeveLayFlat],
        [TM].[Shape] AS [Shape],
        [TM].[SourceStockTicketType] AS [StockTicketType],
        [TPP].[ArtWorkComplete] AS [ArtWorkComplete],
        [TPP].[InkReceived] AS [InkReceived],
        [TPP].[ProofComplete] AS [ProofComplete],
        [TPP].[PlateComplete] AS [PlateComplete],
        [TPP].[ToolsReceived] AS [ToolsReceived],
        IIF([TPP].[StockReceived] LIKE '%In%', 1, 0) AS [StockReceived],
        [TM].[ITSName] AS [ITSName],
        [TM].[OTSName] AS [OTSName],
        [TD].[ConsecutiveNumber] AS [ConsecutiveNumber],
        [TD].[Quantity] AS [Quantity],
        [TD].[ActualQuantity] AS [ActualQuantity],
        [TD].[SizeAcross] AS [SizeAcross],
        [TD].[ColumnSpace] AS [ColumnSpace],
        [TD].[RowSpace] AS [RowSpace],
        [TD].[NumAcross] AS [NumAcross],
        [TD].[NumAroundPlate] AS [NumAroundPlate],
        [TD].[LabelRepeat] AS [LabelRepeat],
        [TD].[FinishedNumAcross] AS [FinishedNumAcross],
        [TD].[FinishedNumLabels] AS [FinishedNumLabels],
        [TD].[Coresize] AS [Coresize],
        [TD].[OutsideDiameter] AS [OutsideDiameter],
        [TD].[EsitmatedLength] AS [EstimatedLength],
        [TD].[OverRunLength] AS [OverRunLength],
        [TD].[NoPlateChanges] AS [NoOfPlateChanges],
        [TS].[ShippedOnDate] AS [ShippedOnDate],
        [TS].[SourceShipVia] AS [ShipVia],
        [TS].[DueOnsiteDate] AS [DueOnsiteDate],
        [TS].[ShippingStatus] AS [ShippingStatus],
        [TS].[ShippingAddress] AS [ShippingAddress],
        [TS].[Shippingcity] AS [Shippingcity],
        [TM].[TicketCategory] AS [TicketCategory], -- 0 - Default, 1 - Parent, 2 - SubTicket
        [TM].[ITSAssocNum] AS [ITSAssocNum],
        [TM].[OTSAssocNum] AS [OTSAssocNum],
        [TS].[ShippingInstruc] AS [ShippingInstruc],
        [TM].[DateDone] AS [DateDone],
        [TS].[ShipAttnEmailAddress] AS [ShipAttnEmailAddress],
        [TS].[ShipLocation] AS [ShipLocation],
        [TS].[ShipZip] AS [ShipZip],
        [TS].[BillAddr1] AS [BillAddr1],
        [TS].[BillAddr2] AS [BillAddr2],
        [TS].[BillCity] AS [BillCity],
        [TS].[BillZip] AS [BillZip],
        [TS].[BillCountry] AS [BillCountry],
        [TM].[IsStockAllocated] AS [IsStockAllocated],
        [TM].[EndUserPO] AS [EndUserPO],
        [TTD].[Tool1Desc] AS [Tool1Descr],
        [TTD].[Tool2Desc] AS [Tool2Descr],
        [TTD].[Tool3Desc] AS [Tool3Descr],
        [TTD].[Tool4Desc] AS [Tool4Descr],
        [TTD].[Tool5Desc] AS [Tool5Descr],
        [TD].[ActFootage] AS [ActFootage],
        [TM].[EstPackHrs] AS [EstPackHrs],
        [TM].[ActPackHrs] AS [ActPackHrs],
        [TM].[InkStatus] AS [InkStatus],
        [TS].[BillState] AS [BillState],
        [TM].[CustContact] AS [CustContact],
        [TD].[CoreType] AS [CoreType],
        [TD].[RollUnit] AS [RollUnit],
        [TD].[RollLength] AS [RollLength],
        [TM].[FinishNotes] AS [FinishNotes],
        [TS].[ShipCounty] AS [ShipCounty],
        [TM].[StockNotes] AS [StockNotes],
        [TM].[CreditHoldOverride] AS [CreditHoldOverride],
        [TM].[ShrinkSleeveOverLap] AS [ShrinkSleeveOverLap],
        [TM].[ShrinkSleeveCutHeight] AS [ShrinkSleeveCutHeight],
        [TSD].[Stock1Desc] AS [StockDesc1],
        [TSD].[Stock2Desc] AS [StockDesc2],
        [TSD].[Stock3Desc] AS [StockDesc3],
        IIF(@IsStockAvailabilityEnabled = 1, [TM].[StockStatus], NULL) AS [StockStatus],
        CASE 
				WHEN [pt].[TicketId] IS NOT NULL THEN 1
				WHEN [ct].[TicketId] IS NOT NULL THEN 2
				ELSE 0
			END AS [WorkcenterMaterialTicketCategory],
        CASE 
				WHEN [ct].[TicketId] IS NOT NULL THEN [ct].[IsCompletingOnTime]
				WHEN [pt].[TicketId] IS NOT NULL THEN [pt].[IsCompletingOnTime]
				ELSE NULL
			END AS [IsCompletingOnTime],
        IIF([TTM].[PreviousIsComplete] = 0, CAST(1 AS BIT), CAST(0 AS BIT)) AS [Highlight],
        [TTM].[HasPreviousTaskPartiallyRan],
        IIF([TGN].[TicketId] IS NULL, 0, 1) AS [isTicketGeneralNotePresent],
        [SSD].[StagingStatus],
        IIF([RS].[Id] IS NULL, 1, 0) AS [IsFirstDay], -- (Ticket-Task - not in latest schedule archive, but in schedule report - First day Scheduled)

        [EM].[ID] AS [OriginalEquipmentId],
        [EM].[Name] AS [OriginalEquipmentName],
        [EM].[WorkcenterTypeId],
        [EM].[WorkCenterName],
        [EM].[FacilityId],
        [EM].[FacilityName],

        ISNULL([TTT].[ActualEstTotalHours], 0) AS [ActualEstTotalHours],
        [TTT].[EstMaxDueDateTime],

        [TC].[Colors],
        [TP].[Plates],
        [CPD].[ColumnPerf],
        [RPD].[RowPerf],

        [TDR].IsDependentProdReady,
        [TDR].DependentTicketId

    INTO [dbo].[#TicketDetails]
    FROM [dbo].[TicketMaster] TM
        INNER JOIN [dbo].[TicketShipping] TS WITH (NOLOCK) ON [TS].[TicketId] = [Tm].[ID]
        INNER JOIN [dbo].[TicketPreProcess] TPP WITH (NOLOCK) ON [TPP].[TicketId] = [TM].[Id]
        LEFT JOIN [dbo].[TicketTask_temp] TTT with (nolock) on [TM].[ID] = [TTT].[TicketId]
        LEFT JOIN [dbo].[TicketScore] TSC WITH(NOLOCK) ON [TSC].[TicketId] = [TM].[ID]
        LEFT JOIN [dbo].[TicketDimensions] TD WITH (NOLOCK) ON [TM].[ID] = [TD].[TicketId]
        LEFT JOIN [dbo].[#TicketToolData] TTD ON [TM].[ID] = [TTD].[TicketId]
        LEFT JOIN [dbo].[#TicketStockData] TSD ON [TM].[ID] = [TSD].[TicketId]
        LEFT JOIN [dbo].[#workcenterMaterialConsumingTickets] ct ON [TM].[ID] = [ct].[TicketId]
        LEFT JOIN [dbo].[#workcenterMaterialProducingTickets] pt ON [TM].[ID] = [pt].[TicketId]
        LEFT JOIN [dbo].[#DistinctTicketsWithNotes] TGN ON [TM].[ID] = [TGN].[TicketId]
        LEFT JOIN [dbo].[#tasktime] ttm ON [ttm].[sourceticketid] = [TM].[SourceTicketId] AND [TTM].[taskname] = [TTT].[TaskName]
        LEFT JOIN [dbo].[#TicketDependentRaw] TDR ON [TM].[ID] = [TDR].[TicketId]
        LEFT JOIN [dbo].[EquipmentMaster] EM WITH (NOLOCK) ON EM.[ID] = [TTT].[OriginalEquipmentId]
        LEFT JOIN [dbo].[#TempStagingStatusData] SSD ON [TM].[Id] = [SSD].[TicketId] AND [TTT].[TaskName] = [SSD].[TaskName]
        LEFT JOIN [dbo].[#RecentSchedules] RS ON [TM].[SourceTicketId] = [RS].[SourceTicketId] AND [TTT].[TaskName] = [RS].[TaskName] AND [RS].[RowNum] = 1
        LEFT JOIN [dbo].[#TicketColors] TC ON TC.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#TicketPlates] TP ON TP.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#ColumnPerfData] CPD ON CPD.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#RowPerfData] RPD ON RPD.[TicketId] = TS.[TicketId];


    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



    SET @blockName = 'Replacing records in TicketDataCache';
    SET @startTime = GETDATE();

    TRUNCATE TABLE [dbo].[TicketDataCache_temp];

	;WITH [DeduplicatedDetails] AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY [TicketNumber], [TaskName] ORDER BY [TicketNumber]) AS [RowNum]
        FROM [dbo].[#TicketDetails]
    )
    INSERT INTO [dbo].[TicketDataCache_temp]
    SELECT
        [TicketId],
        [TicketNumber],
        [TaskName],
        [IsComplete],
        [TaskEstimatedMeters],
        [CustomerName],
        [GeneralDescription],
        [TicketPoints],
        [ShipByDate],
        [OrderDate],
        [SourceCustomerId],
        [CustomerPO],
        [TicketPriority],
        [FinishType],
        [IsBackSidePrinted],
        [IsSlitOnRewind],
        [UseTurretRewinder],
        [EstTotalRevenue],
        [TicketType],
        [PriceMode],
        [FinalUnwind],
        [TicketStatus],
        [BackStageColorStrategy],
        [Pinfeed],
        [IsPrintReversed],
        [TicketNotes],
        [EndUserNum],
        [EndUserName],
        [CreatedOn],
        [ModifiedOn],
        [Tab],
        [SizeAround],
        [ShrinkSleeveLayFlat],
        [Shape],
        [StockTicketType],
        [ArtWorkComplete],
        [InkReceived],
        [ProofComplete],
        [PlateComplete],
        [ToolsReceived],
        [StockReceived],
        [ITSName],
        [OTSName],
        [ConsecutiveNumber],
        [Quantity],
        [ActualQuantity],
        [SizeAcross],
        [ColumnSpace],
        [RowSpace],
        [NumAcross],
        [NumAroundPlate],
        [LabelRepeat],
        [FinishedNumAcross],
        [FinishedNumLabels],
        [Coresize],
        [OutsideDiameter],
        [EstimatedLength],
        [OverRunLength],
        [NoOfPlateChanges],
        [ShippedOnDate],
        [ShipVia],
        [DueOnsiteDate],
        [ShippingStatus],
        [ShippingAddress],
        [Shippingcity],
        [TicketCategory],
        [ITSAssocNum],
        [OTSAssocNum],
        [ShippingInstruc],
        [DateDone],
        [ShipAttnEmailAddress],
        [ShipLocation],
        [ShipZip],
        [BillAddr1],
        [BillAddr2],
        [BillCity],
        [BillZip],
        [BillCountry],
        [IsStockAllocated],
        [EndUserPO],
        [Tool1Descr],
        [Tool2Descr],
        [Tool3Descr],
        [Tool4Descr],
        [Tool5Descr],
        [ActFootage],
        [EstPackHrs],
        [ActPackHrs],
        [InkStatus],
        [BillState],
        [CustContact],
        [CoreType],
        [RollUnit],
        [RollLength],
        [FinishNotes],
        [ShipCounty],
        [StockNotes],
        [CreditHoldOverride],
        [ShrinkSleeveOverLap],
        [ShrinkSleeveCutHeight],
        [StockDesc1],
        [StockDesc2],
        [StockDesc3],
        [StockStatus],
        [WorkcenterMaterialTicketCategory],
        [IsCompletingOnTime],
        [Highlight],
        [HasPreviousTaskPartiallyRan],
        [isTicketGeneralNotePresent],
        [StagingStatus],
        [IsFirstDay],
        [OriginalEquipmentId],
        [OriginalEquipmentName],
        [WorkcenterTypeId],
        [WorkCenterName],
        [FacilityId],
        [FacilityName],
        [ActualEstTotalHours],
        [EstMaxDueDateTime],
        [Colors],
        [Plates],
        [ColumnPerf],
        [RowPerf],
        [IsDependentProdReady],
        [DependentTicketId]

    FROM [DeduplicatedDetails]
    WHERE [RowNum] = 1;

    INSERT @__ErrorInfoLog
    EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName
    FROM @__ErrorInfoLog AS ErrorInfoLog;

END