CREATE PROCEDURE [dbo].[spGetScheduleManagerData]
	@PageNumber				AS INT = 1,
	@RowsOfPage				AS INT = 10,
	@SortingColumn			AS VARCHAR(100) = 'default',
    @startDate				AS DATETIME = NULL,
    @endDate				AS DATETIME = NULL,
    @equipments				AS UDT_SINGLEFIELDFILTER readonly,
    @facilities				AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers	AS UDT_SINGLEFIELDFILTER readonly,
    @workcenters			AS UDT_SINGLEFIELDFILTER readonly,
    @valuestreams			AS UDT_SINGLEFIELDFILTER readonly,
    @numberOfTimeCardDays	AS INT = 15,
	@currentLocalDate		AS Datetime  = null,
	@ticketAttributeNames	AS UDT_SINGLEFIELDFILTER readonly,
	@CorelationId			AS VARCHAR(40) = NULL,
	@TenantId				AS VARCHAR(40) = NULL
AS
BEGIN

	DECLARE 
		@spName								VARCHAR(100) = 'spGetScheduleManagerData',
		@__ErrorInfoLog						__ErrorInfoLog,
		@maxCustomMessageSize				INT = 4000,
		@blockName							VARCHAR(100),
		@warningStr							NVARCHAR(4000),
		@infoStr							NVARCHAR(4000),
		@errorStr							NVARCHAR(4000),
		@IsError							BIT = 0,
		@startTime							DATETIME,
		@IsStockAvailabilityEnabled			BIT = 0,
		@IsMultiFacilitySchedulingEnabled	BIT = 0,
		@Yesterday							DATETIME = DATEADD(DAY, -1, GETUTCDATE()),
		@DayBeforeYesterday					DATETIME = DATEADD(DAY, -2, GETUTCDATE()),
        @Columns                            NVARCHAR(MAX),
        @StagingColumns                     NVARCHAR(MAX),
        @StagingQuery                       NVARCHAR(MAX);


	DROP TABLE IF EXISTS #TicketsInSchedule;
	DROP TABLE IF EXISTS #schedulereportdetail;
	DROP TABLE IF EXISTS #TicketAttribute;
	DROP TABLE IF EXISTS #Tickets;
	DROP TABLE IF EXISTS #TicketsInCurrentPage;
	DROP TABLE IF EXISTS #ColumnPerfData;
	DROP TABLE IF EXISTS #RowPerfData;
	DROP TABLE IF EXISTS #TicketToolData;
	DROP TABLe IF EXISTs #TicketStockData;
	DROP TABLE IF EXISTS #timecard;
	DROP TABLE IF EXISTS #latestruntime;
	DROP TABLE IF EXISTS #lastrun;
	DROP TABLE IF EXISTS #tasktime;
	DROP TABLE IF EXISTS #taskStatuses;
	DROP TABLE IF EXISTS #taskGrouping;
	DROP TABLE IF EXISTS #schedule;
	DROP TABLE IF EXISTS #ColumnPERFCalc;
	DROP TABLE IF EXISTS #RowPERFCalc;
	DROP TABLE IF EXISTS #TempTicketGeneralNotesCount;
	DROP TABLE IF EXISTS #equipmentValueStreams;
	DROP TABLE IF EXISTS #RollingNumber;
	DROP TABLE IF EXISTS #RollingHour;
	DROP TABLE IF EXISTS #workcenterMaterialProducingTickets;
	DROP TABLE IF EXISTS #workcenterMaterialConsumingTickets;
	DROP TABLE IF EXISTS #wcmPTArrivalTime;
	DROP TABLE IF EXISTS #sortedPaginatedReport;
	DROP TABLE IF EXISTS #PartiallyRanDependentTickets;
	DROP TABLE IF EXISTS #TicketDeps;
	DROP TABLE IF EXISTS #FinalTicketDeps;
	DROP TABLE IF EXISTS #RecentSchedules;
    DROP TABLE IF EXISTS #TempWorkcenterStagingRequirement;
    DROP TABLE IF EXISTS #TempStagingData;
	DROP TABLE IF EXISTS #TempStagingStatusData;


SET @blockName = 'timecard'; SET @startTime = GETDATE();
	if(@currentLocalDate = null)
		set @currentLocalDate = GETDATE()

	IF(@CorelationId IS NULL)
		SET @CorelationId = NEWID()
	IF(@TenantId IS NULL)
		SELECT TOP 1 @TenantId = TenantId FROM TicketMaster



		SELECT @IsStockAvailabilityEnabled = CV.Value  
		FROM ConfigurationValue CV with (nolock)
		INNER JOIN ConfigurationMaster CM with (nolock) on CM.Id = CV.ConfigId
		Where CM.Name = 'EnableAutomaticStockAvailability' 

        /** Calculate a DateTime value for latest scan **/
        SELECT
            tc.equipmentid,
            tc.sourceticketid
            , startedon AS StartDateTime -- to adjust time stored as integer in DB
		INTO #timecard
        FROM
            timecardinfo tc with (nolock)
        WHERE
             startedon > Dateadd(day,-@numberOfTimeCardDays,@currentLocalDate)
	
	CREATE NONCLUSTERED INDEX [IX_Timecard_Temp] ON #timecard (EquipmentId) INCLUDE (StartDateTime)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'latestruntime'; SET @startTime = GETDATE();
  
        /** Find latest scan for each press **/
        SELECT
            tc.equipmentid
            , Max(startdatetime) AS MaxStartDateTime
		INTO #latestruntime
        FROM
            #timecard tc
        GROUP BY
            tc.equipmentid

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	

	SET @blockName = 'lastrun'; SET @startTime = GETDATE();
        /** Find latest ticket run on each machine, load key attributes to identify possible changeovers **/
		SELECT
            lrt.equipmentid AS LastRunEquipmentId
            , Cast(tc.sourceticketid AS NVARCHAR(255)) AS LastRunSourceTicketId
		INTO #lastrun
        FROM
            #latestruntime LRT
			INNER JOIN #timecard tc
				ON LRT.equipmentid = tc.equipmentid AND LRT.maxstartdatetime = tc.startdatetime

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
     

	SET @blockName = 'tasktime'; SET @startTime = GETDATE();

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
           tt.EstMaxDueDateTime AS TaskDueTime,
		   ts.shipbydatetime,
		   ts.ticketid,
		   tt.iscomplete,
		   CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited,
		   CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited,
		   tm.sourceticketid,
		   tt.taskname,
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
        WHERE
            ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  tm.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
	
	CREATE NONCLUSTERED INDEX [IX_TaskTime_Temp] ON #tasktime (sourceticketid) INCLUDE (TaskDueTime,shipbydatetime,iscomplete)

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	

	SET @blockName = 'taskStatuses'; SET @startTime = GETDATE();
        SELECT
            sr.SourceTicketId,
            sr.TaskName,
			sr.Startsat,
			sr.endsat,
            CASE
                WHEN iscomplete=1 THEN 'Complete'
                --WHEN lr.lastrunsourceticketid IS NOT NULL THEN 'On Press'
                WHEN tm.shipbydatetime IS NULL THEN 'Late'
                WHEN sr.endsat IS NULL THEN 'Unscheduled'
                WHEN @currentLocalDate> tm.taskduetime OR sr.endsat > tm.taskduetime THEN 'Late'
                WHEN   Datediff(hh, @currentLocalDate, tm.taskduetime) < 4
                    OR Datediff(hh, sr.endsat, tm.taskduetime) < 4 THEN 'At Risk'
                WHEN @currentLocalDate >sr.endsat THEN 'Behind'
                ELSE 'On Track'
            END AS TaskStatus,
			tm.IsEstMinsEdited,
			tm.IsStatusEdited,
            CASE
                WHEN lr.lastrunsourceticketid IS NOT NULL THEN CAST(1 as bit)
                ELSE CAST(0 as bit)
            END AS IsOnPress      
			INTO #taskStatuses
            FROM
				schedulereport sr
				LEFT JOIN TicketMaster TMM with (nolock) 
					ON sr.SourceTicketId = TMM.SourceTicketId
				LEFT JOIN #tasktime tm
					ON tm.sourceticketid = sr.sourceticketid AND tm.taskname = sr.taskname
				LEFT JOIN #lastrun lr
					ON lr.lastrunsourceticketid = tm.sourceticketid AND lr.lastrunequipmentid = sr.equipmentid
				LEFT JOIN TicketScore TSC with (nolock)
					ON TMM.ID = TSC.TicketId
            WHERE
                ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
        
	CREATE NONCLUSTERED INDEX [IX_TaskStatus_Temp] ON #taskStatuses (sourceticketid) INCLUDE (TaskName,StartsAt,EndsAt,TaskStatus)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'taskGrouping'; SET @startTime = GETDATE();

		SELECT SourceTicketId,
			STRING_AGG( TaskName +'*,*'+convert(varchar, StartsAt,0 )+'*,*'+convert(varchar,EndsAt,0)+'*,*'+TaskStatus+'*,*'+CAST( IsOnPress as varchar)+'*,*'+CAST( IsEstMinsEdited as varchar)+'*,*'+CAST( IsStatusEdited as varchar),'|||') within group (order by [startsat] asc)  as TaskString
		INTO #taskGrouping
		FROM #taskStatuses
		GROUP BY SourceTicketId
		
		
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	

		
	SET @blockName = 'stagingStatusData'; SET @startTime = GETDATE();

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

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT



	SET @blockName = 'schedule'; SET @startTime = GETDATE();
	
		SELECT
            SR.Id,
			SR.TaskName,
			SR.ChangeoverMinutes,
			SR.StartsAt,
			SR.EndsAt,
			SR.TaskMinutes,
			SR.IsPinned,
			SR.PinType,
			SR.FeasibilityOverride,
			SR.MasterRollNumber,
			SR.EquipmentId,
			SR.SourceTicketId,
			SR.ForcedGroup,
			TMM.ID as TicketId,
			tss.TaskStatus,
			tss.IsOnPress,
			SR.CreatedOn,
            Case When Sr.IsPinned = 1 Then  'Locked' Else 'Unlocked' END as LockStatus,
            Case When Sr.IsPinned = 1 Then  Sr.PinType Else NULL END as LockType,
            ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketPoints,
			CASE 
                WHEN PreviousIsComplete = 0 THEN CAST(1 as BIT)
                ELSE CAST(0 as BIT)
            END Highlight,
			TaskString,
			CAST(tm.HasPreviousTaskPartiallyRan AS BIT) AS HasPreviousTaskPartiallyRan
		INTO #schedule
        FROM schedulereport sr with (nolock)
			inner join #taskStatuses tss on sr.SourceTicketId = tss.SourceTicketId and sr.TaskName = tss.TaskName 
			LEFT join #taskGrouping tg on sr.SourceTicketId = tg.SourceTicketId
            LEFT join TicketMaster TMM with (nolock) on sr.SourceTicketId = TMM.SourceTicketId
            LEFT JOIN #tasktime tm
                ON tm.sourceticketid = sr.sourceticketid
                AND tm.taskname = sr.taskname
            LEFT JOIN #lastrun lr
                ON lr.lastrunsourceticketid = tm.sourceticketid
                AND lr.lastrunequipmentid = sr.equipmentid
            LEFT JOIN TicketScore TSC with (nolock) on TMM.ID = TSC.TicketId
            WHERE
                ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
                AND  ((SELECT Count(1) FROM @equipments) = 0 OR  sr.equipmentid IN (SELECT field FROM @equipments))
                AND (@startDate IS NULL OR @startDate <= sr.endsat)
                AND (@endDate IS NULL OR @endDate >= sr.startsat)

	CREATE NONCLUSTERED INDEX [IX_Schedule_Temp] ON #schedule (sourceticketid) INCLUDE (TaskName,StartsAt,EndsAt,TaskStatus)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Tickets Distinct'; SET @startTime = GETDATE();
	
		Select distinct Ticketid into #TicketsInSchedule from #schedule
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Column Perf Calc'; SET @startTime = GETDATE();

	--	Select distinct TI.TicketId, P.ColumnPerf as ColumnPerf
	--	INTO #ColumnPERFCalc
	--	from TicketItemInfo TI 
	--	inner join #TicketsInSchedule T on TI.TicketId = T.TicketId
	--	left join ProductMaster P on TI.ProductId = P.Id

	--CREATE NONCLUSTERED INDEX [IX_ColumnPERFCalc_Temp] ON #ColumnPERFCalc (TicketId) INCLUDE (ColumnPerf)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	

	SET @blockName = 'Column Perf Data'; SET @startTime = GETDATE();	
	
	--	Select TicketId, STRING_AGG(ColumnPerf,',') as ColumnPerf into #ColumnPerfData from #ColumnPERFCalc
	--	Group by TicketId

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	

	SET @blockName = 'Row Perf Calc'; SET @startTime = GETDATE();
		
	--	Select distinct TI.TicketId, P.RowPerf as RowPerf
	--	into #RowPERFCalc
	--	from TicketItemInfo TI 
	--	inner join #TicketsInSchedule T on TI.TicketId = T.TicketId
	--	left join ProductMaster P on TI.ProductId = P.Id
	
	--CREATE NONCLUSTERED INDEX [IX_RowPERFCalc_Temp] ON #RowPERFCalc (TicketId) INCLUDE (RowPerf)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Row Perf Data'; SET @startTime = GETDATE();

	--    Select TicketId, STRING_AGG(RowPerf,',') as RowPerf into #RowPerfData from #RowPERFCalc
	--	Group by TicketId

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Ticket Tool Data'; SET @startTime = GETDATE();

		;WITH [TempTicketTools] AS (
			SELECT
				[TicketId],
				[Sequence],
				[Description]
			FROM [dbo].[TicketTool] WITH (NOLOCK)
			WHERE [RoutingNumber] IS NULL
		)
			SELECT
				[TIS].[TicketId],
				[TT1].[Description] AS [Tool1Desc], 
				[TT2].[Description] AS [Tool2Desc],
				[TT3].[Description] AS [Tool3Desc],
				[TT4].[Description] AS [Tool4Desc],
				[TT5].[Description] AS [Tool5Desc]
			INTO [dbo].[#TicketToolData]
			FROM [dbo].[#TicketsInSchedule] AS [TIS]
				LEFT JOIN [TempTicketTools] AS [TT1] ON [TT1].[TicketId] = [TIS].[TicketId] AND [TT1].[Sequence] = 1
				LEFT JOIN [TempTicketTools] AS [TT2] ON [TT2].[TicketId] = [TIS].[TicketId] AND [TT2].[Sequence] = 2
				LEFT JOIN [TempTicketTools] AS [TT3] ON [TT3].[TicketId] = [TIS].[TicketId] AND [TT3].[Sequence] = 3
				LEFT JOIN [TempTicketTools] AS [TT4] ON [TT4].[TicketId] = [TIS].[TicketId] AND [TT4].[Sequence] = 4
				LEFT JOIN [TempTicketTools] AS [TT5] ON [TT5].[TicketId] = [TIS].[TicketId] AND [TT5].[Sequence] = 5;

	CREATE NONCLUSTERED INDEX [IX_TicketToolData_Temp] ON #TicketToolData (TicketId) INCLUDE (Tool1Desc,Tool2Desc,Tool3Desc,Tool4Desc,Tool5Desc)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	
	SET @blockName = 'Ticket Stock Data'; SET @startTime = GETDATE();		
		
    -- Ticket stock data
        ;WITH [TempTicketStocks] AS (
			SELECT
				[TicketId],
				[Sequence],
				[Notes]
			FROM [dbo].[TicketStock] WITH (NOLOCK)
			WHERE RoutingNo IS NULL
		)
		Select 
		T.TicketId ,
		TT1.Notes as Stock1Desc, 
		TT2.Notes as Stock2Desc,
		TT3.Notes as Stock3Desc
		Into #TicketStockData	
		from #TicketsInSchedule T
		left join [TempTicketStocks] TT1 on TT1.TicketId = T.TicketId  and TT1.Sequence = 1
		left join [TempTicketStocks] TT2 on TT2.TicketId = T.TicketId  and TT2.Sequence = 2
		left join [TempTicketStocks] TT3 on TT3.TicketId = T.TicketId  and TT3.Sequence = 3
	
	CREATE NONCLUSTERED INDEX [IX_TicketStockData_Temp] ON #TicketStockData (TicketId) INCLUDE (Stock1Desc,Stock2Desc,Stock3Desc)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'ticketGeneralNotes'; SET @startTime = GETDATE();
		SELECT 
			TM.ID as TicketId, 
			CASE
				WHEN COUNT(TGN.TicketId) > 0 THEN 1
				ELSE 0
			END AS isTicketGeneralNotePresent
		INTO #TempTicketGeneralNotesCount
		FROM TicketMaster TM with (nolock)
			LEFT JOIN TicketGeneralNotes TGN with (nolock) ON TM.ID = TGN.TicketId
		GROUP BY TM.ID

		
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Get Recent Schedule Archives'; SET @startTime = GETDATE();
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

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    

	SET @blockName = 'Schedule Report Detail'; SET @startTime = GETDATE();	
		
	select em.FacilityId, evs.EquipmentId, string_agg(evs.ValueStreamId,', ') as valuestreams
			into #equipmentValueStreams
			from EquipmentValueStream evs with (nolock)
			join EquipmentMaster em with (nolock) on em.ID = evs.EquipmentId
			where ((SELECT Count(1) FROM @valuestreams) = 0  OR evs.ValueStreamId in (SELECT field FROM @valuestreams))
			and ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
			and ((SELECT Count(1) FROM @equipments) = 0  OR em.ID IN (SELECT field FROM @equipments))
			group by FacilityId,evs.EquipmentId

		-- Rolling Number
		SELECT r.Id
			into #RollingNumber
		FROM
		(
			select 
				Sr.Id,
				EM.RollingNumber, 
				ROW_NUMBER() OVER(partition by EM.RollingNumber order by sr.startsAt) rn 
			from
			#schedule Sr
			inner join EquipmentMaster EM with (nolock) on Sr.EquipmentId = EM.ID and EM.RollingNumber is not null
			where Sr.TaskStatus != 'Complete'
		) r
		WHERE r.rn <= r.RollingNumber

		-- Rolling hours 
		select  Sr.Id
		Into #RollingHour
		from #schedule Sr
		inner join EquipmentMaster EM with (nolock) on Sr.EquipmentId = EM.ID and EM.RollingHour is not null
		where Sr.StartsAt <= DATEADD(hour,EM.RollingHour,@currentLocalDate)
		and Sr.TaskStatus != 'Complete'

		
		SELECT est.TicketId, 
		CASE 
			WHEN est.EstTimeOfArrival > est.FirstTaskDueDateTime THEN 0 
			ELSE 1 
		END AS IsCompletingOnTime
		INTO #workcenterMaterialConsumingTickets
		FROM
		(
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
		) est
		WHERE est.Rno = 1
		
		
		
		SELECT TicketId, EstTimeOfArrival 
		INTO #wcmPTArrivalTime
		FROM 
		(
			SELECT
				tti.TicketId AS TicketId,
				ROW_NUMBER() OVER(PARTITION BY tti.TicketId ORDER BY tsa.FirstAvailableTime DESC) AS Rno,
				tsa.FirstAvailableTime AS EstTimeOfArrival
			FROM TicketStockAvailabilityRawMaterialTickets rmt with (nolock)
			INNER JOIN TicketItemInfo tti  with (nolock)
				ON rmt.TicketItemInfoId = tti.Id
			INNER JOIN TicketStockAvailability tsa with (nolock)
				ON rmt.TicketStockAvailabilityId = tsa.Id
		) t
		WHERE  t.Rno = 1
		
		
		SELECT 
			DISTINCT TicketId,  
			CASE 
				WHEN t.EstTimeOfArrival > t.FirstTaskDueDateTime THEN 0 
				ELSE 1 
			END AS IsCompletingOnTime
		INTO #workcenterMaterialProducingTickets
		FROM
		(
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
		) t
		WHERE t.Rno = 1

        SELECT
			DISTINCT
			--- Ticket Fields 
			TM.SourceTicketId as TicketNumber,
			TM.ID as TicketId,
			TM.CustomerName as CustomerName,
			TM.GeneralDescription as GeneralDescription,
			s.TicketPoints as TicketPoints,
			TSS.ShipByDateTime as ShipByDate,
			TM.OrderDate as OrderDate,
			TM.SourceCustomerId as SourceCustomerId,
			Tm.CustomerPO as CustomerPO,
			TM.SourcePriority as TicketPriority,
			TM.SourceFinishType as FinishType,
			TM.isBackSidePrinted as IsBackSidePrinted,
			TM.IsSlitOnRewind as IsSlitOnRewind,
			TM.UseTurretRewinder as UseTurretRewinder,
			TM.EstTotalRevenue as EstTotalRevenue,
			Tm.SourceTicketType AS TicketType,
			TM.PriceMode as PriceMode,
			TM.FinalUnwind as FinalUnwind,
			TM.SourceStatus as TicketStatus,
			TM.BackStageColorStrategy as BackStageColorStrategy,
			TM.Pinfeed as Pinfeed,
			TM.IsPrintReversed as IsPrintReversed,
			Tm.SourceTicketNotes as TicketNotes,
			Tm.EndUserNum  as EndUserNum,
			TM.EndUserName as EndUserName,
			TM.SourceCreatedOn as CreatedOn,
			TM.SourceModifiedOn as ModifiedOn,
			TM.Tab as Tab,
			TM.SizeAround as SizeAround,
			TM.ShrinkSleeveLayFlat as ShrinkSleeveLayFlat,
			TM.Shape as Shape,
			TM.SourceStockTicketType as StockTicketType,
			TPP.ArtWorkComplete as ArtWorkComplete,
			TPP.InkReceived  as InkReceived,
			TPP.ProofComplete as ProofComplete,
			TPP.PlateComplete as PlateComplete,
			TPP.ToolsReceived as ToolsReceived,
			Case when Tpp.StockReceived like '%In%' THEN 1 ELSE 0 END as StockReceived ,
			TM.ITSName as ITSName,
			TM.OTSName as OTSName,
			TD.ConsecutiveNumber as ConsecutiveNumber,
			TD.Quantity as Quantity,
			TD.ActualQuantity as ActualQuantity,
			TD.SizeAcross as SizeAcross,
			TD.ColumnSpace as ColumnSpace,
			TD.RowSpace as RowSpace,
			TD.NumAcross as NumAcross,
			TD.NumAroundPlate as NumAroundPlate,
			TD.LabelRepeat as LabelRepeat,
			TD.FinishedNumAcross as FinishedNumAcross,
			TD.FinishedNumLabels as FinishedNumLabels,
			TD.Coresize as Coresize,
			TD.OutsideDiameter as OutsideDiameter,
			TD.EsitmatedLength as EstimatedLength,
			TD.OverRunLength as OverRunLength,
			TD.NoPlateChanges as NoOfPlateChanges,
			TS.ShippedOnDate as ShippedOnDate,
			TS.SourceShipVia as ShipVia,
			TS.DueOnsiteDate as DueOnsiteDate,
			TS.ShippingStatus as ShippingStatus,
			TS.ShippingAddress as ShippingAddress,
			TS.Shippingcity as Shippingcity,
			TM.TicketCategory AS TicketCategory, -- 0 - Default, 1 - Parent, 2 - SubTicket

			--- New fields added
			--CD.ColumnPerf as ColumnPerf,
			--RD.RowPerf as RowPerf,
			NULL as ColumnPerf,
			NULL as RowPerf,
			TM.ITSAssocNum as ITSAssocNum,
			TM.OTSAssocNum as OTSAssocNum,
			TS.ShippingInstruc as ShippingInstruc,
			TM.DateDone as DateDone,
			TS.ShipAttnEmailAddress as ShipAttnEmailAddress,
			TS.ShipLocation as ShipLocation,
			TS.ShipZip as ShipZip,
			TS.BillAddr1 as BillAddr1,
			TS.BillAddr2 as BillAddr2,
			TS.BillCity as BillCity,
			TS.BillZip as BillZip,
			TS.BillCountry as BillCountry,
			TM.IsStockAllocated as IsStockAllocated,
			TM.EndUserPO as EndUserPO,
			TTD.Tool1Desc as Tool1Descr,
			TTD.Tool2Desc as Tool2Descr,
			TTD.Tool3Desc as Tool3Descr,
			TTD.Tool4Desc as Tool4Descr,
			TTD.Tool5Desc as Tool5Descr,
			TD.ActFootage as ActFootage,
			TM.EstPackHrs as EstPackHrs,
			TM.ActPackHrs as ActPackHrs,
			TM.InkStatus as InkStatus,
			TS.BillState as BillState,
			TM.CustContact as CustContact,
			TD.CoreType as CoreType,
			TD.RollUnit as RollUnit,
			TD.RollLength as RollLength,
			TM.FinishNotes as FinishNotes,
			TS.ShipCounty as ShipCounty,
			TM.StockNotes as StockNotes,
			TM.CreditHoldOverride as CreditHoldOverride,
			TM.ShrinkSleeveOverLap as ShrinkSleeveOverLap,
			TM.ShrinkSleeveCutHeight as ShrinkSleeveCutHeight,
			TSD.Stock1Desc as StockDesc1,
			TSD.Stock2Desc as StockDesc2,
			TSD.Stock3Desc as StockDesc3,
			 
			--- Schedule Fields
			s.TaskName as TaskName,
			em.Name as EquipmentName,
			s.StartsAt as StartsAt,
			s.EndsAt as EndsAt,
			s.ChangeoverMinutes as ChangeoverMinutes,
			s.TaskMinutes as TaskMinutes,
			s.TaskStatus as TaskStatus,
			em.WorkCenterName as WorkcenterName,
			TTT.EstMeters as TaskEstimatedMeters,
			SO.Notes as SchedulingNotes,
			s.ForcedGroup as ForcedGroup,

			--- Mandatory fields / Indicators
			s.Id as ScheduleId,
			s.IsPinned as IsPinned,
			s.PinType as PinType,
			s.LockType,
			s.LockStatus,
			s.IsOnPress as IsOnPress,
			s.Highlight as Highlight,
			CASE WHEN SO.ID is not null THEN 1 ELSE 0 END as ManuallyScheduled,
			s.FeasibilityOverride as FeasibilityOverride,

			CASE WHEN 
				RN.Id is not null OR RH.Id is not null THEN 1
			ELSE 0 END as IsRollingLock,

			s.MasterRollNumber as MasterRollNumber,
		    (CASE WHEN s.MasterRollNumber is not null THEN CAST(1 as BIT) ELSE CAST(0 as BIT) END) IsMasterRoll,
			CASE 
				WHEN s.MasterRollNumber is not null AND (TTT.Sequence <> 1 OR s.MasterRollNumber like 'PRINTED_%') THEN (CAST(1 as bit))
				ELSE (CAST(0 as bit))
			END IsMasterRollGroup,
			em.ID as EquipmentId,
			Em.WorkcenterTypeId as WorkcenterId,
			S.TaskString,
			S.CreatedOn as RecordCreatedOn,
			TT.isTicketGeneralNotePresent,
			CASE 
				WHEN @IsStockAvailabilityEnabled = 1 THEN TM.StockStatus
				ELSE NULL
			END as StockStatus,
			evsTempTable.valuestreams,
			CASE 
				WHEN pt.TicketId IS NOT NULL THEN 1
				WHEN ct.TicketId IS NOT NULL THEN 2
				ELSE 0
			END AS WorkcenterMaterialTicketCategory,
			
			CASE 
				WHEN ct.TicketId IS NOT NULL THEN ct.IsCompletingOnTime
				WHEN pt.TicketId IS NOT NULL THEN pt.IsCompletingOnTime
				ELSE NULL
			END AS IsCompletingOnTime,
			s.HasPreviousTaskPartiallyRan AS HasPreviousTaskPartiallyRan,
	        CASE
				WHEN RS.Id IS NULL THEN 1
			    ELSE 0
			END AS IsFirstDay, -- (Ticket-Task - not in latest schedule archive, but in schedule report - First day Scheduled)
			SSD.StagingStatus,
			COALESCE(1 - (CAST(TD.ActualQuantity AS REAL) / NULLIF(CAST(TD.Quantity AS REAL), 0)), 0) * TM.EstTotalRevenue as WIPValue

        INTO #schedulereportdetail
        FROM #schedule s
        INNER JOIN equipmentmaster em
            ON em.id = s.equipmentid
			
			INNER JOIN TicketMaster TM with (nolock) on s.SourceTicketId = TM.SourceTicketId
			Inner join TicketShipping TS with (nolock) on TS.TicketId = Tm.ID
			inner join TicketPreProcess TPP with (nolock) on TPP.TicketId = TM.Id
			LEFT join ScheduleOverride SO with (nolock) on TM.ID = SO.TicketId and s.TaskName = SO.TaskName and SO.IsScheduled = 1
			LEFT JOIN TicketTask TTT with (nolock) on Tm.ID = TTT.TicketId and s.TaskName = TTT.TaskName
			LEFT JOIN TicketShipping TSS with (nolock) on TM.ID =  TSS.TicketId
			LEFT JOIN TicketDimensions TD with (nolock) on TM.ID = TD.TicketId
			--LEFT JOIN #ColumnPerfData CD on TM.ID = CD.TicketId
			--LEFT JOIN #RowPerfData RD on TM.ID = RD.TicketId
			LEFT JOIN #TicketToolData TTD on TM.ID = TTD.TicketId
			LEFT JOIN #TicketStockData TSD on TM.ID = TSD.TicketId
			LEFT JOIN #TempTicketGeneralNotesCount TT ON TM.ID = TT.TicketId
			LEFT JOIN #RollingNumber RN on s.Id = RN.Id
			LEFT JOIN #RollingHour RH on s.Id = RH.Id
			LEFT JOIN EquipmentValueStream evs with (nolock) ON em.ID = evs.equipmentId AND s.EquipmentId = evs.EquipmentId
			LEFT JOIN #equipmentValueStreams evsTempTable ON evs.EquipmentId = evsTempTable.equipmentId
			LEFT JOIN #workcenterMaterialConsumingTickets ct ON TM.ID = ct.TicketId
			LEFT JOIN #workcenterMaterialProducingTickets pt ON TM.ID = pt.TicketId
			LEFT JOIN #RecentSchedules RS ON s.SourceTicketId = RS.SourceTicketId AND s.TaskName = RS.TaskName AND RS.RowNum = 1
			LEFT JOIN #TempStagingStatusData SSD ON S.Id = SSD.ScheduleId
           WHERE
            ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
            AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
			AND ((SELECT Count(1) FROM @valuestreams) = 0  OR evs.ValueStreamId in (SELECT field FROM @valuestreams))

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'Tickets in Current Page'; SET @startTime = GETDATE();
			--------CREATE TABLE SCRIPT--------------
		CREATE TABLE #sortedPaginatedReport (RowNumber INT IDENTITY(0,1) PRIMARY KEY, TicketNumber nvarchar(255), 
		TicketId varchar(36), CustomerName nvarchar(255), 
		GeneralDescription nvarchar(4000), TicketPoints numeric, ShipByDate datetime, OrderDate datetime, SourceCustomerId nvarchar(36), 
		CustomerPO nvarchar(255), TicketPriority nvarchar(255), FinishType nvarchar(255), IsBackSidePrinted bit, IsSlitOnRewind bit, UseTurretRewinder bit,
		EstTotalRevenue real, TicketType smallint, PriceMode nvarchar(4000), FinalUnwind nvarchar(4000), TicketStatus nvarchar(4000), 
		BackStageColorStrategy nvarchar(4000), Pinfeed bit, IsPrintReversed bit, TicketNotes nvarchar(4000), EndUserNum nvarchar(4000), 
		EndUserName nvarchar(4000), CreatedOn datetime, ModifiedOn datetime, Tab real, SizeAround real, ShrinkSleeveLayFlat real, 
		Shape nvarchar(4000), StockTicketType smallint, ArtWorkComplete bit, InkReceived bit, ProofComplete bit, PlateComplete bit,
		ToolsReceived bit, StockReceived int, ITSName nvarchar(1000), OTSName nvarchar(1000), ConsecutiveNumber bit, Quantity int, 
		ActualQuantity int, SizeAcross real, ColumnSpace real, RowSpace real, NumAcross smallint, NumAroundPlate smallint, 
		LabelRepeat real, FinishedNumAcross real, FinishedNumLabels int, Coresize real, OutsideDiameter real, EstimatedLength int, 
		OverRunLength real, NoOfPlateChanges int, ShippedOnDate datetime, ShipVia nvarchar(4000), DueOnsiteDate datetime, ShippingStatus nvarchar(4000),
		ShippingAddress nvarchar(4000), Shippingcity nvarchar(1000), TicketCategory int, ColumnPerf nvarchar(4000), RowPerf nvarchar(4000),
		ITSAssocNum nvarchar(1000), OTSAssocNum nvarchar(1000), ShippingInstruc nvarchar(4000), DateDone datetime, ShipAttnEmailAddress nvarchar(1000), 
		ShipLocation nvarchar(1000), ShipZip nvarchar(255), BillAddr1 nvarchar(1000), BillAddr2 nvarchar(1000), BillCity nvarchar(255), BillZip nvarchar(255),
		BillCountry nvarchar(255), IsStockAllocated bit, EndUserPO nvarchar(1000), Tool1Descr nvarchar(4000), Tool2Descr nvarchar(4000), 
		Tool3Descr nvarchar(4000), Tool4Descr nvarchar(4000), Tool5Descr nvarchar(4000), ActFootage int, EstPackHrs real, ActPackHrs real,
		InkStatus nvarchar(4000), BillState nvarchar(255), CustContact nvarchar(1000), CoreType nvarchar(255), RollUnit nvarchar(255), RollLength int,
		FinishNotes nvarchar(4000), ShipCounty nvarchar(255), StockNotes nvarchar(4000), CreditHoldOverride bit, ShrinkSleeveOverLap bit,
		ShrinkSleeveCutHeight bit, StockDesc1 nvarchar(4000), StockDesc2 nvarchar(4000), StockDesc3 nvarchar(4000), TaskName nvarchar(255),
		EquipmentName nvarchar(128), StartsAt datetime, EndsAt datetime, ChangeoverMinutes float, TaskMinutes float, TaskStatus varchar(11),
		WorkcenterName nvarchar(32), TaskEstimatedMeters real, SchedulingNotes nvarchar(4000), ForcedGroup nvarchar(128), ScheduleId varchar(36), 
		IsPinned bit, PinType nvarchar(24), LockType nvarchar(24), LockStatus varchar(8), IsOnPress bit, Highlight bit, ManuallyScheduled int, FeasibilityOverride bit,
		IsRollingLock int, MasterRollNumber varchar(255), IsMasterRoll bit, IsMasterRollGroup bit, EquipmentId varchar(36), WorkcenterId varchar(36),
		TaskString nvarchar(4000), RecordCreatedOn datetime, isTicketGeneralNotePresent int, StockStatus varchar(64), valuestreams varchar(8000),
		WorkcenterMaterialTicketCategory int, IsCompletingOnTime int, HasPreviousTaskPartiallyRan bit, IsFirstDay bit, StagingStatus VARCHAR(36),
		WIPValue REAL, Value nvarchar(4000) DEFAULT '');
		
		CREATE NONCLUSTERED INDEX [IX_SortedPage_Temp] ON #sortedPaginatedReport (EquipmentName ASC, StartsAt ASC)
		--------END OF CREATE TABLE SCRIPT----------		

	
	Create table #TicketsInCurrentPage(TicketId nvarchar(36))

	if(@SortingColumn <> 'default')
	BEGIN

		----- Sorting by a Ticket attribute value
		IF EXISTS ( select 1 from @ticketAttributeNames where Field = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1))
			Begin 
						--- Get Ticket attribute data type
						Declare @TicketAttributeType varchar(50)
						select @TicketAttributeType = DataType from TicketAttribute with (nolock) where name = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1)

						Select distinct Ticketid into #Tickets from #schedulereportdetail

						--- Get Ticket attribute value of the sorting column
						select TTR.TicketId,TAV.Value as Value
						into #TicketAttribute
						from 
						#Tickets TTR with (nolock)
						inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1)
						
						--- Add the sorting attribute value in projection 
						INSERT INTO #sortedPaginatedReport
							SELECT S.*,Ta.Value
							FROM #schedulereportdetail S
							left join #TicketAttribute TA on S.TicketId = TA.TicketId 
							ORDER BY

							---- order by attribute value
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@SortingColumn, 1) = '+'  THEN CAST( TA.Value as bit ) end,
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as bit ) end DESC,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@SortingColumn, 1) = '+'  THEN CAST( TA.Value as real ) end,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as real ) end DESC,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@SortingColumn, 1) = '+'  THEN CAST( TA.Value as varchar ) end,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as varchar ) end DESC
							OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY
		END

	ELSE
	BEGIN ---- Sorting by Table fields

		-- tbl_ScheduleReport
		BEGIN
		
			INSERT INTO #sortedPaginatedReport
			SELECT *,''
				FROM #schedulereportdetail
				Order by 

						CASE WHEN @SortingColumn = '+backStageColorStrategy'  THEN BackStageColorStrategy END ,
						CASE WHEN @SortingColumn = '-backStageColorStrategy'  THEN BackStageColorStrategy END DESC,
						CASE WHEN @SortingColumn = '+createdOn'  THEN CreatedOn END ,
						CASE WHEN @SortingColumn = '-createdOn'  THEN CreatedOn END DESC,
						CASE WHEN @SortingColumn = '+customerName'  THEN CustomerName END ,
						CASE WHEN @SortingColumn = '-customerName'  THEN CustomerName END DESC,
						CASE WHEN @SortingColumn = '+customerPO'  THEN CustomerPO END ,
						CASE WHEN @SortingColumn = '-customerPO'  THEN CustomerPO END DESC,
						CASE WHEN @SortingColumn = '+endsAt'  THEN EndsAt END ,
						CASE WHEN @SortingColumn = '-endsAt'  THEN EndsAt END DESC,
						CASE WHEN @SortingColumn = '+endUserName'  THEN EndUserName END ,
						CASE WHEN @SortingColumn = '-endUserName'  THEN EndUserName END DESC,
						CASE WHEN @SortingColumn = '+endUserNum'  THEN EndUserNum END ,
						CASE WHEN @SortingColumn = '-endUserNum'  THEN EndUserNum END DESC,

						-- To sort on multiple columns => For EquipmentName, sort by EquipmentName, StartsAt
						CASE WHEN @SortingColumn = '+equipmentName'  THEN EquipmentName END ,
						CASE WHEN @SortingColumn = '-equipmentName'  THEN EquipmentName END DESC,
						CASE WHEN @SortingColumn = '+equipmentName'  THEN StartsAt END ,
						CASE WHEN @SortingColumn = '-equipmentName'  THEN StartsAt END DESC,

						CASE WHEN @SortingColumn = '+estTotalRevenue'  THEN EstTotalRevenue END ,
						CASE WHEN @SortingColumn = '-estTotalRevenue'  THEN EstTotalRevenue END DESC,
						CASE WHEN @SortingColumn = '+finalUnwind'  THEN FinalUnwind END ,
						CASE WHEN @SortingColumn = '-finalUnwind'  THEN FinalUnwind END DESC,
						CASE WHEN @SortingColumn = '+finishType'  THEN FinishType END ,
						CASE WHEN @SortingColumn = '-finishType'  THEN FinishType END DESC,
						CASE WHEN @SortingColumn = '+generalDescription'  THEN GeneralDescription END ,
						CASE WHEN @SortingColumn = '-generalDescription'  THEN GeneralDescription END DESC,
						CASE WHEN @SortingColumn = '+isBackSidePrinted'  THEN IsBackSidePrinted END ,
						CASE WHEN @SortingColumn = '-isBackSidePrinted'  THEN IsBackSidePrinted END DESC,
						CASE WHEN @SortingColumn = '+isPrintReversed'  THEN IsPrintReversed END ,
						CASE WHEN @SortingColumn = '-isPrintReversed'  THEN IsPrintReversed END DESC,
						CASE WHEN @SortingColumn = '+isSlitOnRewind'  THEN IsSlitOnRewind END ,
						CASE WHEN @SortingColumn = '-isSlitOnRewind'  THEN IsSlitOnRewind END DESC,
						CASE WHEN @SortingColumn = '+modifiedOn'  THEN ModifiedOn END ,
						CASE WHEN @SortingColumn = '-modifiedOn'  THEN ModifiedOn END DESC,
						CASE WHEN @SortingColumn = '+orderDate'  THEN OrderDate END ,
						CASE WHEN @SortingColumn = '-orderDate'  THEN OrderDate END DESC,
						CASE WHEN @SortingColumn = '+pinfeed'  THEN Pinfeed END ,
						CASE WHEN @SortingColumn = '-pinfeed'  THEN Pinfeed END DESC,
						CASE WHEN @SortingColumn = '+priceMode'  THEN PriceMode END ,
						CASE WHEN @SortingColumn = '-priceMode'  THEN PriceMode END DESC,
						CASE WHEN @SortingColumn = '+schedulingNotes'  THEN SchedulingNotes END ,
						CASE WHEN @SortingColumn = '-schedulingNotes'  THEN SchedulingNotes END DESC,
						CASE WHEN @SortingColumn = '+shape'  THEN Shape END ,
						CASE WHEN @SortingColumn = '-shape'  THEN Shape END DESC,
						CASE WHEN @SortingColumn = '+shipByDate'  THEN ShipByDate END ,
						CASE WHEN @SortingColumn = '-shipByDate'  THEN ShipByDate END DESC,
						CASE WHEN @SortingColumn = '+shrinkSleeveLayFlat'  THEN ShrinkSleeveLayFlat END ,
						CASE WHEN @SortingColumn = '-shrinkSleeveLayFlat'  THEN ShrinkSleeveLayFlat END DESC,
						CASE WHEN @SortingColumn = '+sizeAround'  THEN SizeAround END ,
						CASE WHEN @SortingColumn = '-sizeAround'  THEN SizeAround END DESC,
						CASE WHEN @SortingColumn = '+sourceCustomerId'  THEN SourceCustomerId END ,
						CASE WHEN @SortingColumn = '-sourceCustomerId'  THEN SourceCustomerId END DESC,
						CASE WHEN @SortingColumn = '+startsAt'  THEN StartsAt END ,
						CASE WHEN @SortingColumn = '-startsAt'  THEN StartsAt END DESC,
						CASE WHEN @SortingColumn = '+tab'  THEN Tab END ,
						CASE WHEN @SortingColumn = '-tab'  THEN Tab END DESC,
						CASE WHEN @SortingColumn = '+taskMeters'  THEN TaskEstimatedMeters END ,
						CASE WHEN @SortingColumn = '-taskMeters'  THEN TaskEstimatedMeters END DESC,
						CASE WHEN @SortingColumn = '+taskMinutes'  THEN TaskMinutes END ,
						CASE WHEN @SortingColumn = '-taskMinutes'  THEN TaskMinutes END DESC,
						CASE WHEN @SortingColumn = '+taskName'  THEN TaskName END ,
						CASE WHEN @SortingColumn = '-taskName'  THEN TaskName END DESC,
						CASE WHEN @SortingColumn = '+taskStatus'  THEN TaskStatus END ,
						CASE WHEN @SortingColumn = '-taskStatus'  THEN TaskStatus END DESC,
						CASE WHEN @SortingColumn = '+ticketId'  THEN TicketId END ,
						CASE WHEN @SortingColumn = '-ticketId'  THEN TicketId END DESC,
						CASE WHEN @SortingColumn = '+ticketNotes'  THEN TicketNotes END ,
						CASE WHEN @SortingColumn = '-ticketNotes'  THEN TicketNotes END DESC,
						CASE WHEN @SortingColumn = '+ticketNumber'  THEN TicketNumber END ,
						CASE WHEN @SortingColumn = '-ticketNumber'  THEN TicketNumber END DESC,
						CASE WHEN @SortingColumn = '+ticketPoints'  THEN TicketPoints END ,
						CASE WHEN @SortingColumn = '-ticketPoints'  THEN TicketPoints END DESC,
						CASE WHEN @SortingColumn = '+priority'  THEN TicketPriority END ,
						CASE WHEN @SortingColumn = '-priority'  THEN TicketPriority END DESC,
						CASE WHEN @SortingColumn = '+status'  THEN TicketStatus END ,
						CASE WHEN @SortingColumn = '-status'  THEN TicketStatus END DESC,
						CASE WHEN @SortingColumn = '+stockTicketType'  THEN StockTicketType END ,
						CASE WHEN @SortingColumn = '-stockTicketType'  THEN StockTicketType END DESC,
						CASE WHEN @SortingColumn = '+ticketType'  THEN TicketType END ,
						CASE WHEN @SortingColumn = '-ticketType'  THEN TicketType END DESC,
						CASE WHEN @SortingColumn = '+useTurretRewinder'  THEN UseTurretRewinder END ,
						CASE WHEN @SortingColumn = '-useTurretRewinder'  THEN UseTurretRewinder END DESC,

						-- To sort on multiple columns => For workcenterName, sort by WorkcenterName, EquipmentName, StartsAt
						CASE WHEN @SortingColumn = '+workcenterName'  THEN WorkcenterName END ,
						CASE WHEN @SortingColumn = '-workcenterName'  THEN WorkcenterName END DESC,
						CASE WHEN @SortingColumn = '+workcenterName'  THEN EquipmentName END ,
						CASE WHEN @SortingColumn = '-workcenterName'  THEN EquipmentName END DESC,
						CASE WHEN @SortingColumn = '+workcenterName'  THEN StartsAt END ,
						CASE WHEN @SortingColumn = '-workcenterName'  THEN StartsAt END DESC,

						CASE WHEN @SortingColumn = '+consecutiveNumber'  THEN ConsecutiveNumber END ,
						CASE WHEN @SortingColumn = '-consecutiveNumber'  THEN ConsecutiveNumber END DESC,
						CASE WHEN @SortingColumn = '+quantity'  THEN Quantity END ,
						CASE WHEN @SortingColumn = '-quantity'  THEN Quantity END DESC,
						CASE WHEN @SortingColumn = '+actualQuantity'  THEN ActualQuantity END ,
						CASE WHEN @SortingColumn = '-actualQuantity'  THEN ActualQuantity END DESC,
						CASE WHEN @SortingColumn = '+sizeAcross'  THEN SizeAcross END ,
						CASE WHEN @SortingColumn = '-sizeAcross'  THEN SizeAcross END DESC,
						CASE WHEN @SortingColumn = '+columnSpace'  THEN ColumnSpace END ,
						CASE WHEN @SortingColumn = '-columnSpace'  THEN ColumnSpace END DESC,
						CASE WHEN @SortingColumn = '+rowSpace'  THEN RowSpace END ,
						CASE WHEN @SortingColumn = '-rowSpace'  THEN RowSpace END DESC,
						CASE WHEN @SortingColumn = '+numAcross'  THEN NumAcross END ,
						CASE WHEN @SortingColumn = '-numAcross'  THEN NumAcross END DESC,
						CASE WHEN @SortingColumn = '+numAroundPlate'  THEN NumAroundPlate END ,
						CASE WHEN @SortingColumn = '-numAroundPlate'  THEN NumAroundPlate END DESC,
						CASE WHEN @SortingColumn = '+labelRepeat'  THEN LabelRepeat END ,
						CASE WHEN @SortingColumn = '-labelRepeat'  THEN LabelRepeat END DESC,
						CASE WHEN @SortingColumn = '+finishedNumAcross'  THEN FinishedNumAcross END ,
						CASE WHEN @SortingColumn = '-finishedNumAcross'  THEN FinishedNumAcross END DESC,
						CASE WHEN @SortingColumn = '+finishedNumLabels'  THEN FinishedNumLabels END ,
						CASE WHEN @SortingColumn = '-finishedNumLabels'  THEN FinishedNumLabels END DESC,
						CASE WHEN @SortingColumn = '+coresize'  THEN Coresize END ,
						CASE WHEN @SortingColumn = '-coresize'  THEN Coresize END DESC,
						CASE WHEN @SortingColumn = '+estimatedLength'  THEN EstimatedLength END ,
						CASE WHEN @SortingColumn = '-estimatedLength'  THEN EstimatedLength END DESC,
						CASE WHEN @SortingColumn = '+overRunLength'  THEN OverRunLength END ,
						CASE WHEN @SortingColumn = '-overRunLength'  THEN OverRunLength END DESC,
						CASE WHEN @SortingColumn = '+noOfPlateChanges'  THEN NoOfPlateChanges END ,
						CASE WHEN @SortingColumn = '-noOfPlateChanges'  THEN NoOfPlateChanges END DESC,
						CASE WHEN @SortingColumn = '+shippedOnDate'  THEN ShippedOnDate END ,
						CASE WHEN @SortingColumn = '-shippedOnDate'  THEN ShippedOnDate END DESC,
						CASE WHEN @SortingColumn = '+shipVia'  THEN ShipVia END ,
						CASE WHEN @SortingColumn = '-shipVia'  THEN ShipVia END DESC,
						CASE WHEN @SortingColumn = '+dueOnsiteDate'  THEN DueOnsiteDate END ,
						CASE WHEN @SortingColumn = '-dueOnsiteDate'  THEN DueOnsiteDate END DESC,
						CASE WHEN @SortingColumn = '+shippingStatus'  THEN ShippingStatus END ,
						CASE WHEN @SortingColumn = '-shippingStatus'  THEN ShippingStatus END DESC,
						CASE WHEN @SortingColumn = '+shippingAddress'  THEN ShippingAddress END ,
						CASE WHEN @SortingColumn = '-shippingAddress'  THEN ShippingAddress END DESC,
						CASE WHEN @SortingColumn = '+shippingcity'  THEN Shippingcity END ,
						CASE WHEN @SortingColumn = '-shippingcity'  THEN Shippingcity END DESC,
						CASE WHEN @SortingColumn = '+itsName'  THEN ITSName END ,
						CASE WHEN @SortingColumn = '-itsName'  THEN ITSName END DESC,
						CASE WHEN @SortingColumn = '+otsName'  THEN OTSName END ,
						CASE WHEN @SortingColumn = '-otsName'  THEN OTSName END DESC,
						CASE WHEN @SortingColumn = '+artWorkComplete'  THEN ArtWorkComplete END ,
						CASE WHEN @SortingColumn = '-artWorkComplete'  THEN ArtWorkComplete END DESC,
						CASE WHEN @SortingColumn = '+toolsReceived'  THEN ToolsReceived END ,
						CASE WHEN @SortingColumn = '-toolsReceived'  THEN ToolsReceived END DESC,
						CASE WHEN @SortingColumn = '+inkReceived'  THEN InkReceived END ,
						CASE WHEN @SortingColumn = '-inkReceived'  THEN InkReceived END DESC,
						CASE WHEN @SortingColumn = '+stockReceived'  THEN StockReceived END ,
						CASE WHEN @SortingColumn = '-stockReceived'  THEN StockReceived END DESC,

						CASE WHEN @SortingColumn = '+columnPerf'  THEN ColumnPerf END ,
						CASE WHEN @SortingColumn = '-columnPerf'  THEN ColumnPerf END DESC,
						CASE WHEN @SortingColumn = '+rowPerf'  THEN rowPerf END ,
						CASE WHEN @SortingColumn = '-rowPerf'  THEN rowPerf END DESC,
						CASE WHEN @SortingColumn = '+iTSAssocNum'  THEN iTSAssocNum END ,
						CASE WHEN @SortingColumn = '-iTSAssocNum'  THEN iTSAssocNum END DESC,
						CASE WHEN @SortingColumn = '+oTSAssocNum'  THEN oTSAssocNum END ,
						CASE WHEN @SortingColumn = '-oTSAssocNum'  THEN oTSAssocNum END DESC,
						CASE WHEN @SortingColumn = '+shippingInstruc'  THEN shippingInstruc END ,
						CASE WHEN @SortingColumn = '-shippingInstruc'  THEN shippingInstruc END DESC,
						CASE WHEN @SortingColumn = '+dateDone'  THEN dateDone END ,
						CASE WHEN @SortingColumn = '-dateDone'  THEN dateDone END DESC,
						CASE WHEN @SortingColumn = '+shipAttnEmailAddress'  THEN shipAttnEmailAddress END ,
						CASE WHEN @SortingColumn = '-shipAttnEmailAddress'  THEN shipAttnEmailAddress END DESC,
						CASE WHEN @SortingColumn = '+shipLocation'  THEN shipLocation END ,
						CASE WHEN @SortingColumn = '-shipLocation'  THEN shipLocation END DESC,
						CASE WHEN @SortingColumn = '+shipZip'  THEN shipZip END ,
						CASE WHEN @SortingColumn = '-shipZip'  THEN shipZip	 END DESC,
						CASE WHEN @SortingColumn = '+billAddr1'  THEN billAddr1 END ,
						CASE WHEN @SortingColumn = '-billAddr1'  THEN billAddr1 END DESC,
						CASE WHEN @SortingColumn = '+billAddr2'  THEN billAddr2 END ,
						CASE WHEN @SortingColumn = '-billAddr2'  THEN billAddr2 END DESC,
						CASE WHEN @SortingColumn = '+billCity'  THEN billCity END ,
						CASE WHEN @SortingColumn = '-billCity'  THEN billCity END DESC,
						CASE WHEN @SortingColumn = '+billZip'  THEN billZip END ,
						CASE WHEN @SortingColumn = '-billZip'  THEN billZip END DESC,
						CASE WHEN @SortingColumn = '+billCountry'  THEN billCountry END ,
						CASE WHEN @SortingColumn = '-billCountry'  THEN billCountry END DESC,
						CASE WHEN @SortingColumn = '+isStockAllocated'  THEN isStockAllocated END ,
						CASE WHEN @SortingColumn = '-isStockAllocated'  THEN isStockAllocated END DESC,
						CASE WHEN @SortingColumn = '+endUserPO'  THEN endUserPO END ,
						CASE WHEN @SortingColumn = '-endUserPO'  THEN endUserPO END DESC,
						CASE WHEN @SortingColumn = '+tool1Descr'  THEN tool1Descr END ,
						CASE WHEN @SortingColumn = '-tool1Descr'  THEN tool1Descr END DESC,
						CASE WHEN @SortingColumn = '+tool2Descr'  THEN tool2Descr END ,
						CASE WHEN @SortingColumn = '-tool2Descr'  THEN tool2Descr END DESC,
						CASE WHEN @SortingColumn = '+tool3Descr'  THEN tool3Descr END ,
						CASE WHEN @SortingColumn = '-tool3Descr'  THEN tool3Descr END DESC,
						CASE WHEN @SortingColumn = '+tool4Descr'  THEN tool4Descr END ,
						CASE WHEN @SortingColumn = '-tool4Descr'  THEN tool4Descr END DESC,
						CASE WHEN @SortingColumn = '+tool5Descr'  THEN tool5Descr END ,
						CASE WHEN @SortingColumn = '-tool5Descr'  THEN tool5Descr END DESC,
						CASE WHEN @SortingColumn = '+actFootage'  THEN actFootage END ,
						CASE WHEN @SortingColumn = '-actFootage'  THEN actFootage END DESC,
						CASE WHEN @SortingColumn = '+estPackHrs'  THEN estPackHrs END ,
						CASE WHEN @SortingColumn = '-estPackHrs'  THEN estPackHrs END DESC,
						CASE WHEN @SortingColumn = '+actPackHrs'  THEN actPackHrs END ,
						CASE WHEN @SortingColumn = '-actPackHrs'  THEN actPackHrs END DESC,
						CASE WHEN @SortingColumn = '+inkStatus'  THEN inkStatus END ,
						CASE WHEN @SortingColumn = '-inkStatus'  THEN inkStatus END DESC,
						CASE WHEN @SortingColumn = '+billState'  THEN billState END ,
						CASE WHEN @SortingColumn = '-billState'  THEN billState END DESC,
						CASE WHEN @SortingColumn = '+custContact'  THEN custContact END ,
						CASE WHEN @SortingColumn = '-custContact'  THEN custContact END DESC,
						CASE WHEN @SortingColumn = '+coreType'  THEN coreType END ,
						CASE WHEN @SortingColumn = '-coreType'  THEN coreType END DESC,
						CASE WHEN @SortingColumn = '+rollLength'  THEN rollLength END ,
						CASE WHEN @SortingColumn = '-rollLength'  THEN rollLength END DESC,
						CASE WHEN @SortingColumn = '+rollUnit'  THEN rollUnit END ,
						CASE WHEN @SortingColumn = '-rollUnit'  THEN rollUnit END DESC,
						CASE WHEN @SortingColumn = '+finishNotes'  THEN finishNotes END ,
						CASE WHEN @SortingColumn = '-finishNotes'  THEN finishNotes END DESC,
						CASE WHEN @SortingColumn = '+shipCounty'  THEN shipCounty END ,
						CASE WHEN @SortingColumn = '-shipCounty'  THEN shipCounty END DESC,
						CASE WHEN @SortingColumn = '+stockNotes'  THEN stockNotes END ,
						CASE WHEN @SortingColumn = '-stockNotes'  THEN stockNotes END DESC,
						CASE WHEN @SortingColumn = '+creditHoldOverride'  THEN creditHoldOverride END ,
						CASE WHEN @SortingColumn = '-creditHoldOverride'  THEN creditHoldOverride END DESC,
						CASE WHEN @SortingColumn = '+shrinkSleeveOverLap'  THEN shrinkSleeveOverLap END ,
						CASE WHEN @SortingColumn = '-shrinkSleeveOverLap'  THEN shrinkSleeveOverLap END DESC,
						CASE WHEN @SortingColumn = '+shrinkSleeveCutHeight'  THEN shrinkSleeveCutHeight END ,
						CASE WHEN @SortingColumn = '-shrinkSleeveCutHeight'  THEN shrinkSleeveCutHeight END DESC,
						CASE WHEN @SortingColumn = '+stockDesc1'  THEN stockDesc1 END ,
						CASE WHEN @SortingColumn = '-stockDesc1'  THEN stockDesc1 END DESC,
						CASE WHEN @SortingColumn = '+stockDesc2'  THEN stockDesc2 END ,
						CASE WHEN @SortingColumn = '-stockDesc2'  THEN stockDesc2 END DESC,
						CASE WHEN @SortingColumn = '+stockDesc3'  THEN stockDesc3 END ,
						CASE WHEN @SortingColumn = '-stockDesc3'  THEN stockDesc3 END DESC,
						CASE WHEN @SortingColumn = '+stockStatus'  THEN stockStatus END ,
						CASE WHEN @SortingColumn = '-stockStatus'  THEN stockStatus END DESC,						
						CASE WHEN @SortingColumn = '+changeoverMinutes'  THEN ChangeoverMinutes END ,
						CASE WHEN @SortingColumn = '-changeoverMinutes'  THEN ChangeoverMinutes END DESC,
						CASE WHEN @SortingColumn = '+stagingStatus' THEN StagingStatus END,
						CASE WHEN @SortingColumn = '-stagingStatus' THEN StagingStatus END DESC,
						CASE WHEN @SortingColumn = '+wipValue'  THEN WIPValue END ,
						CASE WHEN @SortingColumn = '-wipValue'  THEN WIPValue END DESC

						OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY
	
			END			   						
		END	
				
End

INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'ordering schedule by default'; SET @startTime = GETDATE();
	---- Default sorting
		IF(@SortingColumn = 'default')
		BEGIN
			INSERT INTO #sortedPaginatedReport	
			SELECT *,''
			FROM #schedulereportdetail
			Order by EquipmentName ASC, StartsAt ASC
			OFFSET (@PageNumber-1)*@RowsOfPage ROWS
				FETCH NEXT @RowsOfPage ROWS ONLY
		END
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	INSERT INTO #TicketsInCurrentPage SELECT DISTINCT TicketId FROM #sortedPaginatedReport


	SET @blockName = 'Get Schedule Report'; SET @startTime = GETDATE();

	SELECT *, 'tbl_ScheduleReport' AS __dataset_tableName FROM #sortedPaginatedReport ORDER BY RowNumber

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'SR count of records'; SET @startTime = GETDATE();	
	
	Select count(1) as TotalCount,'tbl_ScheduleReport_count' AS __dataset_tableName	
	from #schedulereportdetail s
	
	

	SET @blockName = 'Time window'; SET @startTime = GETDATE();
	---------- Time window
	select IIF(@startDate is NULL, min(StartsAt), @startDate) as StartDate, IIF(@endDate is NULL, max(EndsAt), @endDate) as EndDate , 'tbl_timeWindow' AS __dataset_tableName
	from #schedule s 
	inner join EquipmentMaster em with (nolock)
	ON em.id = s.equipmentid
	WHERE
            ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
            AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	--SET @blockName = 'select from #TicketsInCurrentPage'; SET @startTime = GETDATE();

	--select * from #TicketsInCurrentPage

	--INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'TicketAttributeValues projection'; SET @startTime = GETDATE();
	----- TicketAttributeValues projection
	Select  TAV.TicketId,TAV.Name, TAV.Value,'tbl_ticketAttributeValues' AS __dataset_tableName 
	from #TicketsInCurrentPage S 
	inner join TicketAttributeValues TAV with (nolock) on  S.TicketId = TAV.TicketId 
	and TAV.Name in (select field from @ticketAttributeNames) 
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
END