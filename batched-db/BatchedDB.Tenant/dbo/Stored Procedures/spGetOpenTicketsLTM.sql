CREATE PROCEDURE [dbo].[spGetOpenTicketsLTM]
    @PageNumber             AS INT = 1,
    @NumberOfRows           AS INT = 100,
    @SortingColumn          AS VARCHAR(40) = 'DEFAULT',
    @StartDate				AS DATETIME = NULL,
    @EndDate				AS DATETIME = NULL,
    @Facilities				AS UDT_SINGLEFIELDFILTER READONLY,
    @Valuestreams			AS UDT_SINGLEFIELDFILTER READONLY,
    @Workcenters			AS UDT_SINGLEFIELDFILTER READONLY,
    @Equipments				AS UDT_SINGLEFIELDFILTER READONLY,
    @TicketNumbers	        AS UDT_SINGLEFIELDFILTER READONLY,
	@TicketAttributes       AS UDT_SINGLEFIELDFILTER READONLY,
	@ScheduleStatus			AS VARCHAR(40) = ''
AS
BEGIN

    DECLARE
        @TicketAttributeDataType    AS VARCHAR(50),
        @SortBy                     AS VARCHAR(1) = LEFT(@SortingColumn, 1),
        @SortField                  AS VARCHAR(50) = SUBSTRING(@SortingColumn, 2, LEN(@SortingColumn)),
        @TenantLocalTime            AS DATETIME;


    -- Cleanup temporary tables
    DROP TABLE IF EXISTS [dbo].[#LastRunJob];
    DROP TABLE IF EXISTS [dbo].[#DistinctTicketsWithNotes];
    DROP TABLE IF EXISTS [dbo].[#FilteredEquipments];
    DROP TABLE IF EXISTS [dbo].[#TempSchedule];
    DROP TABLE IF EXISTS [dbo].[#TicketsInSchedule];
    DROP TABLE IF EXISTS [dbo].[#TicketToolData];
    DROP TABLE IF EXISTS [dbo].[#TicketStockData];
    DROP TABLE IF EXISTS [dbo].[#TicketColors];
    DROP TABLE IF EXISTS [dbo].[#TicketPlates];
    DROP TABLE IF EXISTS [dbo].[#ColumnPerfData];
    DROP TABLE IF EXISTS [dbo].[#RowPerfData];
    DROP TABLE IF EXISTS [dbo].[#FinalSchedule];
    DROP TABLE IF EXISTS [dbo].[#DefaultSortedPaginatedReport];
    DROP TABLE IF EXISTS [dbo].[#AttributeSortedPaginatedReport];
    DROP TABLE IF EXISTS [dbo].[#FieldSortedPaginatedReport];
    DROP TABLE IF EXISTS [dbo].[#TicketIdsInCurrentPage];

    
    -- Current time in tenant timezone
	SELECT @TenantLocalTime = SYSDATETIMEOFFSET() AT TIME ZONE (
        SELECT CV.[Value]
        FROM [dbo].[ConfigurationValue] CV WITH (NOLOCK)
            INNER JOIN [dbo].[ConfigurationMaster] CM WITH (NOLOCK) ON CM.[Id] = CV.[ConfigId]
		WHERE CM.[Name] = 'Timezone');


    -- Last ran job on each equipment
    SELECT
        TCI.[EquipmentId], 
        TCI.[SourceTicketId]
    INTO [dbo].[#LastRunJob]
    FROM [dbo].[TimecardInfo] TCI
    WHERE TCI.[StartedOn] = (
            SELECT MAX(TCI2.[StartedOn])
            FROM [dbo].[TimecardInfo] TCI2
            WHERE TCI2.[EquipmentId] = TCI.[EquipmentId]
            AND TCI2.[StartedOn] > DATEADD(DAY, -15, @TenantLocalTime));


    -- Distinct tickets with general notes
    SELECT DISTINCT [TicketId]
    INTO [dbo].[#DistinctTicketsWithNotes]
    FROM [dbo].[TicketGeneralNotes] WITH (NOLOCK);

    
    -- Filtered equipments and their respective workcenters and facilities
    SELECT DISTINCT
        EM.[ID] AS [EquipmentId],
        EM.[Name] AS [EquipmentName],
        EM.[WorkcenterTypeId],
        EM.[WorkCenterName],
        EM.[FacilityId],
        EM.[FacilityName]
    INTO [dbo].[#FilteredEquipments]
    FROM [dbo].[EquipmentMaster] EM
        LEFT JOIN [dbo].[EquipmentValueStream] EVS WITH (NOLOCK) ON EVS.[EquipmentId] = EM.[ID]
    WHERE (NOT EXISTS (SELECT 1 FROM @Valuestreams) OR EVS.[ValueStreamId] IN (SELECT [Field] FROM @Valuestreams))
        AND (NOT EXISTS (SELECT 1 FROM @Facilities) OR EM.[FacilityId] IN (SELECT [Field] FROM @Facilities))
        AND (NOT EXISTS (SELECT 1 FROM @Workcenters) OR EM.[WorkcenterTypeId] IN (SELECT [Field] FROM @Workcenters))
        AND (NOT EXISTS (SELECT 1 FROM @Equipments) OR EM.[ID] IN (SELECT [Field] FROM @Equipments));       


    -- Report data based on the filters
    SELECT

        -- TicketTask
        TT.[TicketId],
        TT.[TaskName],
        TT.[EstMeters] AS [EstimatedLength],
        TT.[IsComplete],
        TT.[EstMaxDueDateTime],
        ISNULL(TT.[ActualEstTotalHours], 0) AS [ActualEstTotalHours],

        -- TicketMaster
        TM.[SourceTicketId] AS [TicketNumber],
        TM.[SourceCustomerId],
        TM.[SourcePriority] AS [TicketPriority],
        TM.[SourceFinishType] AS [FinishType],
        TM.[SourceTicketType] AS [TicketType],
        TM.[SourceStockTicketType] AS [StockTicketType],
        TM.[SourceStatus] AS [TicketStatus],
        TM.[SourceTicketNotes] AS [TicketNotes],
        TM.[SourceCreatedOn] AS [CreatedOn],
        TM.[SourceModifiedOn] AS [ModifiedOn],
        TM.[isBackSidePrinted] AS [IsBackSidePrinted],
        TM.[IsSlitOnRewind],
        TM.[IsPrintReversed],
        TM.[IsStockAllocated],
        TM.[CustomerName],
        TM.[CustomerPO],
        TM.[EndUserNum],
        TM.[EndUserName],
        TM.[EndUserPO],
        TM.[GeneralDescription],
        TM.[OrderDate],
        TM.[UseTurretRewinder],
        TM.[EstTotalRevenue],
        TM.[PriceMode],
        TM.[FinalUnwind],
        TM.[BackStageColorStrategy],
        TM.[Pinfeed],
        TM.[Tab],
        TM.[SizeAround],
        TM.[Shape],
        TM.[ITSName],
        TM.[ITSAssocNum],
        TM.[OTSName],
        TM.[OTSAssocNum],
        TM.[DateDone],
        TM.[EstPackHrs],
        TM.[ActPackHrs],
        TM.[InkStatus],
        TM.[CustContact],
        TM.[FinishNotes],
        TM.[StockNotes],
        TM.[CreditHoldOverride],
        TM.[ShrinkSleeveOverLap],
        TM.[ShrinkSleeveLayFlat],
        TM.[ShrinkSleeveCutHeight],
        
        -- TicketShipping
        TS.[ShipByDateTime] AS [ShipByDate],
        TS.[ShippedOnDate],
        TS.[SourceShipVia] AS [ShipVia],
        TS.[DueOnSiteDate],
        TS.[ShippingStatus],
        TS.[ShippingAddress],
        TS.[ShippingCity],
        TS.[ShippingInstruc],
        TS.[ShipAttnEmailAddress],
        TS.[ShipLocation],
        TS.[ShipZip],
        TS.[ShipCounty],
        TS.[BillAddr1],
        TS.[BillAddr2],
        TS.[BillCity],
        TS.[BillZip],
        TS.[BillCountry],
        TS.[BillState],

        -- TicketDimensions
        TD.[Quantity],
        TD.[ActualQuantity],
        TD.[ActFootage],
        TD.[ConsecutiveNumber],
        TD.[SizeAcross],
        TD.[ColumnSpace],
        TD.[RowSpace],
        TD.[NumAcross],
        TD.[NumAroundPlate],
        TD.[LabelRepeat],
        TD.[FinishedNumAcross],
        TD.[FinishedNumLabels],
        TD.[CoreSize],
        TD.[CoreType],
        TD.[RollUnit],
        TD.[RollLength],
        TD.[OutsideDiameter],
        TD.[OverRunLength],
        TD.[NoPlateChanges] AS [NoOfPlateChanges],

        -- ScheduleReport
        SR.[Id] AS [ScheduleId],
        SR.[StartsAt],
        SR.[EndsAt],

        ISNULL(ScheduledEM.[WorkcenterTypeId], PlannedEM.[WorkcenterTypeId]) AS [WorkcenterId],
        ISNULL(ScheduledEM.[WorkCenterName], PlannedEM.[WorkCenterName]) AS [WorkcenterName],
        
        ISNULL(ScheduledEM.[FacilityId], PlannedEM.[FacilityId]) AS [FacilityId],
        ISNULL(ScheduledEM.[FacilityName], PlannedEM.[FacilityName]) AS [FacilityName],

        TT.[OriginalEquipmentId],
        PlannedEM.[EquipmentName] AS [OriginalEquipmentName],
        
        SR.[EquipmentId],
        ScheduledEM.[EquipmentName] AS [EquipmentName],
        
        CASE
            WHEN SR.[Id] IS NULL THEN ISNULL(TT.[ActualEstTotalHours], 0)
            ELSE ((ISNULL(SR.[TaskMinutes], 0) + ISNULL(SR.[ChangeoverMinutes], 0)) / 60)
        END AS [ScheduledHours],

        CASE
            WHEN TT.[IsComplete] = 1 THEN 'Complete'
            WHEN SR.[Id] IS NULL THEN 'Unscheduled'
            WHEN @TenantLocalTime > TT.[EstMaxDueDateTime] OR SR.[EndsAt] > TT.[EstMaxDueDateTime] OR TS.[ShipByDateTime] IS NULL THEN 'Late'
            WHEN DATEDIFF(HH, @TenantLocalTime, TT.[EstMaxDueDateTime]) < 4 OR DATEDIFF(HH, SR.[EndsAt], TT.[EstMaxDueDateTime]) < 4 THEN 'At Risk'
            WHEN @TenantLocalTime > SR.[EndsAt] THEN 'Behind'
            ELSE 'On Track'
        END AS [TaskStatus]

    INTO [dbo].[#TempSchedule]
    FROM [dbo].[TicketTask] TT WITH (NOLOCK)
        INNER JOIN [dbo].[#FilteredEquipments] PlannedEM WITH (NOLOCK) ON PlannedEM.[EquipmentId] = TT.[OriginalEquipmentId]
        INNER JOIN [dbo].[TicketMaster] TM WITH (NOLOCK) ON TM.[ID]= TT.[TicketId]
        INNER JOIN [dbo].[TicketDimensions] TD WITH (NOLOCK) ON TD.[TicketId] = TT.[TicketId]
        LEFT JOIN [dbo].[ScheduleReport] SR WITH (NOLOCK) ON SR.[SourceTicketId] = TM.[SourceTicketId] AND SR.[TaskName] = TT.[TaskName]
        LEFT JOIN [dbo].[#FilteredEquipments] ScheduledEM WITH (NOLOCK) ON ScheduledEM.[EquipmentId] = SR.[EquipmentId]
        LEFT JOIN [dbo].[TicketShipping] TS WITH (NOLOCK) ON TS.[TicketId] = TT.[TicketId]

    WHERE (@ScheduleStatus = '' OR (@ScheduleStatus = 'Scheduled' AND SR.[Id] IS NOT NULL) OR (@ScheduleStatus = 'Unscheduled' AND SR.[Id] IS NULL))
        AND (@EndDate IS NULL OR TS.[ShipByDateTime] IS NULL OR TS.[ShipByDateTime] <= @EndDate)
        AND TT.[IsComplete] = 0
        AND (NOT EXISTS (SELECT 1 FROM @TicketNumbers) OR TM.[SourceTicketId] IN (SELECT [Field] FROM @TicketNumbers));


    -- Distinct ticket ids in the data
    SELECT DISTINCT [TicketId]
    INTO [dbo].[#TicketsInSchedule]
    FROM [dbo].[#TempSchedule];


    -- Ticket tool data
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


    -- Ticket colors
    ;WITH [TempColor] AS (
        SELECT DISTINCT
            TIS.[TicketId],
            PCI.[SourceColor],
            PCI.[SourceInkType]
        FROM [dbo].[#TicketsInSchedule] TIS
            INNER JOIN [dbo].[TicketItemInfo] TII WITH (NOLOCK) ON TII.[TicketId] = TIS.[TicketId]
            INNER JOIN [dbo].[ProductColorInfo] PCI WITH (NOLOCK) ON PCI.[ProductId] = TII.[ProductId]
    )
        SELECT DISTINCT
            TicketId,
            STRING_AGG(CONCAT([SourceColor], ' (', ISNULL([SourceInkType], 'N/A'), ')'), ', ') AS [Colors]
        INTO [dbo].[#TicketColors]
        FROM [TempColor]
        GROUP BY [TicketId];


    -- Ticket plates
    SELECT
        TIS.[TicketId],
        STRING_AGG(PM.[PlateId], ', ') AS [Plates]
    INTO [dbo].[#TicketPlates]
    FROM [dbo].[#TicketsInSchedule] TIS
        INNER JOIN [dbo].[TicketItemInfo] TII WITH (NOLOCK) ON TII.[TicketId] = TIS.[TicketId]
        INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON PM.[Id] = TII.[ProductId]
    GROUP BY TIS.[TicketId];


    -- Column perfs
    ;WITH [ColumnPerfCalc] AS (
        SELECT DISTINCT
            TIS.[TicketId],
            PM.[ColumnPerf]
        FROM [dbo].[#TicketsInSchedule] TIS
            INNER JOIN [dbo].[TicketItemInfo] TII WITH (NOLOCK) ON TII.[TicketId] = TIS.[TicketId]
            INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON PM.[Id] = TII.[ProductId]
    )
        SELECT DISTINCT
            [TicketId],
            STRING_AGG(ColumnPerf, ', ') AS [ColumnPerf]
        INTO [dbo].[#ColumnPerfData]
        FROM [ColumnPerfCalc]
        GROUP BY [TicketId];


    -- Row perfs
    ;WITH [RowPerfCalc] AS (
        SELECT DISTINCT
            TIS.[TicketId],
            PM.[RowPerf]
        FROM [dbo].[#TicketsInSchedule] TIS
            INNER JOIN [dbo].[TicketItemInfo] TII WITH (NOLOCK) ON TII.[TicketId] = TIS.[TicketId]
            INNER JOIN [dbo].[ProductMaster] PM WITH (NOLOCK) ON PM.[Id] = TII.[ProductId]
    )
        SELECT DISTINCT
            [TicketId],
            STRING_AGG(RowPerf, ', ') AS RowPerf
        INTO [dbo].[#RowPerfData]
        FROM [RowPerfCalc]
        GROUP BY [TicketId];


    -- Final data
    SELECT
        -- TempSchedule
        TS.*,

        -- TicketPreProcess
        TPP.[ArtWorkComplete],
        TPP.[InkReceived],
        TPP.[ProofComplete],
        TPP.[PlateComplete],
        TPP.[ToolsReceived],
        IIF(TPP.[StockReceived] LIKE '%In%', 1, 0) AS [StockReceived],

        -- TicketTool
        TTD.[Tool1Descr],
        TTD.[Tool2Descr],
        TTD.[Tool3Descr],
        TTD.[Tool4Descr],
        TTD.[Tool5Descr],

        -- TicketStock
        TSD.[StockDesc1],
        TSD.[StockDesc2],
        TSD.[StockDesc3],
        
        TC.[Colors],
        TP.[Plates],
        CPD.[ColumnPerf],
        RPD.[RowPerf],
        IIF(LRJ.[SourceTicketId] IS NULL, 0, 1) AS [IsOnPress],
        IIF(TGN.[TicketId] IS NULL, 0, 1) AS [IsTicketGeneralNotePresent],        
        ISNULL(TSC.[CustomerRankScore], 0) * ISNULL(TSC.[DueDateScore], 0) * ISNULL(TSC.[PriorityScore], 0) * ISNULL(TSC.[RevenueScore], 0) AS [TicketPoints]

    INTO [dbo].[#FinalSchedule]
    FROM [dbo].[#TempSchedule] TS
        LEFT JOIN [dbo].[TicketPreProcess] TPP WITH (NOLOCK) ON TPP.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[TicketScore] TSC WITH (NOLOCK) ON TSC.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#DistinctTicketsWithNotes] TGN ON TGN.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#TicketToolData] TTD ON TTD.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#TicketStockData] TSD ON TSD.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#TicketColors] TC ON TC.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#TicketPlates] TP ON TP.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#ColumnPerfData] CPD ON CPD.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#RowPerfData] RPD ON RPD.[TicketId] = TS.[TicketId]
        LEFT JOIN [dbo].[#LastRunJob] LRJ ON LRJ.[SourceTicketId] = TS.[TicketNumber] AND LRJ.[EquipmentId] = TS.[EquipmentId];


    CREATE TABLE [dbo].[#TicketIdsInCurrentPage] ([TicketId] VARCHAR(36));


    -- Sort the data
    IF(@SortingColumn = 'DEFAULT')
    BEGIN

        -- Sort by default parameters (ShipByDate ASC, TicketNumber ASC)
        SELECT IDENTITY(int, 1, 1) AS [RowNumber], *
        INTO [dbo].[#DefaultSortedPaginatedReport]
        FROM [dbo].[#FinalSchedule]
        ORDER BY [ShipByDate] ASC, [TicketNumber] ASC
        OFFSET (@PageNumber-1) * @NumberOfRows ROWS
	    FETCH NEXT @NumberOfRows ROWS ONLY;


        SELECT *, 'tbl_openTicketsReportLTM' AS __dataset_tableName
        FROM [dbo].[#DefaultSortedPaginatedReport]
        ORDER BY [RowNumber];


        INSERT INTO [#TicketIdsInCurrentPage]
        SELECT DISTINCT [TicketId]
        FROM [dbo].[#DefaultSortedPaginatedReport];

    END
    ELSE
    BEGIN

        IF EXISTS (SELECT 1 FROM @TicketAttributes WHERE [Field] = @SortField)
        BEGIN

            --- Get Ticket attribute data type
            SELECT @TicketAttributeDataType = [DataType] 
            FROM [dbo].[TicketAttribute] WITH (NOLOCK) 
            WHERE [Name] = @SortField;

            -- Sort by ticket attribute values
            SELECT IDENTITY(int, 1, 1) AS [RowNumber], FS.*
            INTO [dbo].[#AttributeSortedPaginatedReport]
            FROM [dbo].[#FinalSchedule] FS
                LEFT JOIN [dbo].[TicketAttributeValues] TAV WITH (NOLOCK) ON TAV.[TicketId] = FS.[TicketId]
            WHERE TAV.[Name] = @SortField
            ORDER BY
                CASE WHEN @TicketAttributeDataType = 'boolean' AND @SortBy = '+' THEN CAST(TAV.[Value] AS BIT) END,
                CASE WHEN @TicketAttributeDataType = 'boolean' AND @SortBy = '-' THEN CAST(TAV.[Value] AS BIT) END DESC,
                CASE WHEN @TicketAttributeDataType = 'decimal' AND @SortBy = '+' THEN CAST(TAV.[Value] AS REAL) END,
                CASE WHEN @TicketAttributeDataType = 'decimal' AND @SortBy = '-' THEN CAST(TAV.[Value] AS REAL) END DESC,
                CASE WHEN @TicketAttributeDataType = 'string' AND @SortBy = '+' THEN CAST(TAV.[Value] AS VARCHAR) END,
                CASE WHEN @TicketAttributeDataType = 'string' AND @SortBy = '-' THEN CAST(TAV.[Value] AS VARCHAR) END DESC
            OFFSET (@PageNumber-1) * @NumberOfRows ROWS
            FETCH NEXT @NumberOfRows ROWS ONLY;;

            
            SELECT *, 'tbl_openTicketsReportLTM' AS __dataset_tableName
            FROM [dbo].[#AttributeSortedPaginatedReport]
            ORDER BY [RowNumber];


            INSERT INTO [#TicketIdsInCurrentPage]
            SELECT DISTINCT [TicketId]
            FROM [dbo].[#AttributeSortedPaginatedReport];

        END
        ELSE
        BEGIN

            -- Sort by ticket fields
            SELECT IDENTITY(int, 1, 1) AS [RowNumber], *
            INTO [dbo].[#FieldSortedPaginatedReport]
            FROM [dbo].[#FinalSchedule]
            ORDER BY
                
                CASE WHEN @SortingColumn = '+actFootage' THEN [ActFootage] END,
                CASE WHEN @SortingColumn = '-actFootage' THEN [ActFootage] END DESC,
                
                CASE WHEN @SortingColumn = '+actPackHrs' THEN [ActPackHrs] END,
                CASE WHEN @SortingColumn = '-actPackHrs' THEN [ActPackHrs] END DESC,

                CASE WHEN @SortingColumn = '+actualEstTotalHours' THEN [ActualEstTotalHours] END,
                CASE WHEN @SortingColumn = '-actualEstTotalHours' THEN [ActualEstTotalHours] END DESC,

                CASE WHEN @SortingColumn = '+actualQuantity' THEN [ActualQuantity] END,
                CASE WHEN @SortingColumn = '-actualQuantity' THEN [ActualQuantity] END DESC,

                CASE WHEN @SortingColumn = '+artWorkComplete' THEN [ArtWorkComplete] END,
                CASE WHEN @SortingColumn = '-artWorkComplete' THEN [ArtWorkComplete] END DESC,

                CASE WHEN @SortingColumn = '+backStageColorStrategy' THEN [BackStageColorStrategy] END,
                CASE WHEN @SortingColumn = '-backStageColorStrategy' THEN [BackStageColorStrategy] END DESC,

                CASE WHEN @SortingColumn = '+billAddr1' THEN [BillAddr1] END,
                CASE WHEN @SortingColumn = '-billAddr1' THEN [BillAddr1] END DESC,

                CASE WHEN @SortingColumn = '+billAddr2' THEN [BillAddr2] END,
                CASE WHEN @SortingColumn = '-billAddr2' THEN [BillAddr2] END DESC,

                CASE WHEN @SortingColumn = '+billCity' THEN [BillCity] END,
                CASE WHEN @SortingColumn = '-billCity' THEN [BillCity] END DESC,

                CASE WHEN @SortingColumn = '+billCountry' THEN [BillCountry] END,
                CASE WHEN @SortingColumn = '-billCountry' THEN [BillCountry] END DESC,

                CASE WHEN @SortingColumn = '+billState' THEN [BillState] END,
                CASE WHEN @SortingColumn = '-billState' THEN [BillState] END DESC,

                CASE WHEN @SortingColumn = '+billZip' THEN [BillZip] END,
                CASE WHEN @SortingColumn = '-billZip' THEN [BillZip] END DESC,

                CASE WHEN @SortingColumn = '+colors' THEN [Colors] END,
                CASE WHEN @SortingColumn = '-colors' THEN [Colors] END DESC,

                CASE WHEN @SortingColumn = '+columnPerf' THEN [ColumnPerf] END,
                CASE WHEN @SortingColumn = '-columnPerf' THEN [ColumnPerf] END DESC,

                CASE WHEN @SortingColumn = '+columnSpace' THEN [ColumnSpace] END,
                CASE WHEN @SortingColumn = '-columnSpace' THEN [ColumnSpace] END DESC,

                CASE WHEN @SortingColumn = '+consecutiveNumber' THEN [ConsecutiveNumber] END,
                CASE WHEN @SortingColumn = '-consecutiveNumber' THEN [ConsecutiveNumber] END DESC,

                CASE WHEN @SortingColumn = '+coresize' THEN [CoreSize] END,
                CASE WHEN @SortingColumn = '-coresize' THEN [CoreSize] END DESC,

                CASE WHEN @SortingColumn = '+coreType' THEN [CoreType] END,
                CASE WHEN @SortingColumn = '-coreType' THEN [CoreType] END DESC,

                CASE WHEN @SortingColumn = '+createdOn' THEN [CreatedOn] END,
                CASE WHEN @SortingColumn = '-createdOn' THEN [ModifiedOn] END DESC,

                CASE WHEN @SortingColumn = '+creditHoldOverride' THEN [CreditHoldOverride] END,
                CASE WHEN @SortingColumn = '-creditHoldOverride' THEN [CreditHoldOverride] END DESC,

                CASE WHEN @SortingColumn = '+custContact' THEN [CustContact] END,
                CASE WHEN @SortingColumn = '-custContact' THEN [CustContact] END DESC,

                CASE WHEN @SortingColumn = '+customerName' THEN [CustomerName] END,
                CASE WHEN @SortingColumn = '-customerName' THEN [CustomerName] END DESC,

                CASE WHEN @SortingColumn = '+customerPO' THEN [CustomerPO] END,
                CASE WHEN @SortingColumn = '-customerPO' THEN [CustomerPO] END DESC,

                CASE WHEN @SortingColumn = '+dateDone' THEN [DateDone] END,
                CASE WHEN @SortingColumn = '-dateDone' THEN [DateDone] END DESC,

                CASE WHEN @SortingColumn = '+dueOnsiteDate' THEN [DueOnSiteDate] END,
                CASE WHEN @SortingColumn = '-dueOnsiteDate' THEN [DueOnSiteDate] END DESC,

                CASE WHEN @SortingColumn = '+endUserName' THEN [EndUserName] END,
                CASE WHEN @SortingColumn = '-endUserName' THEN [EndUserName] END DESC,

                CASE WHEN @SortingColumn = '+endUserNum' THEN [EndUserNum] END,
                CASE WHEN @SortingColumn = '-endUserNum' THEN [EndUserNum] END DESC,

                CASE WHEN @SortingColumn = '+endUserPO' THEN [EndUserPO] END,
                CASE WHEN @SortingColumn = '-endUserPO' THEN [EndUserPO] END DESC,

                CASE WHEN @SortingColumn = '+equipmentName' THEN [EquipmentName] END,
                CASE WHEN @SortingColumn = '-equipmentName' THEN [EquipmentName] END DESC,

                CASE WHEN @SortingColumn = '+estimatedLength' THEN [EstimatedLength] END,
                CASE WHEN @SortingColumn = '-estimatedLength' THEN [EstimatedLength] END DESC,

                CASE WHEN @SortingColumn = '+estMaxDueDateTime' THEN [EstMaxDueDateTime] END,
                CASE WHEN @SortingColumn = '-estMaxDueDateTime' THEN [EstMaxDueDateTime] END DESC,

                CASE WHEN @SortingColumn = '+estPackHrs' THEN [EstPackHrs] END,
                CASE WHEN @SortingColumn = '-estPackHrs' THEN [EstPackHrs] END DESC,

                CASE WHEN @SortingColumn = '+estTotalRevenue' THEN [EstTotalRevenue] END,
                CASE WHEN @SortingColumn = '-estTotalRevenue' THEN [EstTotalRevenue] END DESC,

                CASE WHEN @SortingColumn = '+finalUnwind' THEN [FinalUnwind] END,
                CASE WHEN @SortingColumn = '-finalUnwind' THEN [FinalUnwind] END DESC,

                CASE WHEN @SortingColumn = '+finishedNumAcross' THEN [FinishedNumAcross] END,
                CASE WHEN @SortingColumn = '-finishedNumAcross' THEN [FinishedNumAcross] END DESC,

                CASE WHEN @SortingColumn = '+finishedNumLabels' THEN [FinishedNumLabels] END,
                CASE WHEN @SortingColumn = '-finishedNumLabels' THEN [FinishedNumLabels] END DESC,

                CASE WHEN @SortingColumn = '+finishNotes' THEN [FinishNotes] END,
                CASE WHEN @SortingColumn = '-finishNotes' THEN [FinishNotes] END DESC,

                CASE WHEN @SortingColumn = '+finishType' THEN [FinishType] END,
                CASE WHEN @SortingColumn = '-finishType' THEN [FinishType] END DESC,

                CASE WHEN @SortingColumn = '+generalDescription' THEN [GeneralDescription] END,
                CASE WHEN @SortingColumn = '-generalDescription' THEN [GeneralDescription] END DESC,

                CASE WHEN @SortingColumn = '+inkReceived' THEN [InkReceived] END,
                CASE WHEN @SortingColumn = '-inkReceived' THEN [InkReceived] END DESC,

                CASE WHEN @SortingColumn = '+inkStatus' THEN [InkStatus] END,
                CASE WHEN @SortingColumn = '-inkStatus' THEN [InkStatus] END DESC,

                CASE WHEN @SortingColumn = '+isBackSidePrinted' THEN [IsBackSidePrinted] END,
                CASE WHEN @SortingColumn = '-isBackSidePrinted' THEN [IsBackSidePrinted] END DESC,

                CASE WHEN @SortingColumn = '+isPrintReversed' THEN [IsPrintReversed] END,
                CASE WHEN @SortingColumn = '-isPrintReversed' THEN [IsPrintReversed] END DESC,

                CASE WHEN @SortingColumn = '+isSlitOnRewind' THEN [IsSlitOnRewind] END,
                CASE WHEN @SortingColumn = '-isSlitOnRewind' THEN [IsSlitOnRewind] END DESC,

                CASE WHEN @SortingColumn = '+isStockAllocated' THEN [IsStockAllocated] END,
                CASE WHEN @SortingColumn = '-isStockAllocated' THEN [IsStockAllocated] END DESC,

                CASE WHEN @SortingColumn = '+iTSAssocNum' THEN [ITSAssocNum] END,
                CASE WHEN @SortingColumn = '-iTSAssocNum' THEN [ITSAssocNum] END DESC,

                CASE WHEN @SortingColumn = '+itsName' THEN [ITSName] END,
                CASE WHEN @SortingColumn = '-itsName' THEN [ITSName] END DESC,

                CASE WHEN @SortingColumn = '+labelRepeat' THEN [LabelRepeat] END,
                CASE WHEN @SortingColumn = '-labelRepeat' THEN [LabelRepeat] END DESC,

                CASE WHEN @SortingColumn = '+modifiedOn' THEN [ModifiedOn] END,
                CASE WHEN @SortingColumn = '-modifiedOn' THEN [ModifiedOn] END DESC,

                CASE WHEN @SortingColumn = '+noOfPlateChanges' THEN [NoOfPlateChanges] END,
                CASE WHEN @SortingColumn = '-noOfPlateChanges' THEN [NoOfPlateChanges] END DESC,

                CASE WHEN @SortingColumn = '+numAcross' THEN [NumAcross] END,
                CASE WHEN @SortingColumn = '-numAcross' THEN [NumAcross] END DESC,

                CASE WHEN @SortingColumn = '+numAroundPlate' THEN [NumAroundPlate] END,
                CASE WHEN @SortingColumn = '-numAroundPlate' THEN [NumAroundPlate] END DESC,

                CASE WHEN @SortingColumn = '+orderDate' THEN [OrderDate] END,
                CASE WHEN @SortingColumn = '-orderDate' THEN [OrderDate] END DESC,

                CASE WHEN @SortingColumn = '+originalEquipmentName' THEN [OriginalEquipmentName] END,
                CASE WHEN @SortingColumn = '-originalEquipmentName' THEN [OriginalEquipmentName] END DESC,

                CASE WHEN @SortingColumn = '+oTSAssocNum' THEN [OTSAssocNum] END,
                CASE WHEN @SortingColumn = '-oTSAssocNum' THEN [OTSAssocNum] END DESC,

                CASE WHEN @SortingColumn = '+otsName' THEN [OTSName] END,
                CASE WHEN @SortingColumn = '-otsName' THEN [OTSName] END DESC,

                CASE WHEN @SortingColumn = '+outsideDiameter' THEN [OutsideDiameter] END,
                CASE WHEN @SortingColumn = '-outsideDiameter' THEN [OutsideDiameter] END DESC,

                CASE WHEN @SortingColumn = '+overRunLength' THEN [OverRunLength] END,
                CASE WHEN @SortingColumn = '-overRunLength' THEN [OverRunLength] END DESC,

                CASE WHEN @SortingColumn = '+pinfeed' THEN [Pinfeed] END,
                CASE WHEN @SortingColumn = '-pinfeed' THEN [Pinfeed] END DESC,

                CASE WHEN @SortingColumn = '+plateComplete' THEN [PlateComplete] END,
                CASE WHEN @SortingColumn = '-plateComplete' THEN [PlateComplete] END DESC,

                CASE WHEN @SortingColumn = '+plates' THEN [Plates] END,
                CASE WHEN @SortingColumn = '-plates' THEN [Plates] END DESC,

                CASE WHEN @SortingColumn = '+priceMode' THEN [PriceMode] END,
                CASE WHEN @SortingColumn = '-priceMode' THEN [PriceMode] END DESC,

                CASE WHEN @SortingColumn = '+proofComplete' THEN [ProofComplete] END,
                CASE WHEN @SortingColumn = '-proofComplete' THEN [ProofComplete] END DESC,

                CASE WHEN @SortingColumn = '+quantity' THEN [Quantity] END,
                CASE WHEN @SortingColumn = '-quantity' THEN [Quantity] END DESC,

                CASE WHEN @SortingColumn = '+rollLength' THEN [RollLength] END,
                CASE WHEN @SortingColumn = '-rollLength' THEN [RollLength] END DESC,

                CASE WHEN @SortingColumn = '+rollUnit' THEN [RollUnit] END,
                CASE WHEN @SortingColumn = '-rollUnit' THEN [RollUnit] END DESC,

                CASE WHEN @SortingColumn = '+rowPerf' THEN [RowPerf] END,
                CASE WHEN @SortingColumn = '-rowPerf' THEN [RowPerf] END DESC,

                CASE WHEN @SortingColumn = '+rowSpace' THEN [RowSpace] END,
                CASE WHEN @SortingColumn = '-rowSpace' THEN [RowSpace] END DESC,

                CASE WHEN @SortingColumn = '+scheduledHours' THEN [ScheduledHours] END,
                CASE WHEN @SortingColumn = '-scheduledHours' THEN [ScheduledHours] END DESC,

                CASE WHEN @SortingColumn = '+shape' THEN [Shape] END,
                CASE WHEN @SortingColumn = '-shape' THEN [Shape] END DESC,

                CASE WHEN @SortingColumn = '+shipAttnEmailAddress' THEN [ShipAttnEmailAddress] END,
                CASE WHEN @SortingColumn = '-shipAttnEmailAddress' THEN [ShipAttnEmailAddress] END DESC,

                CASE WHEN @SortingColumn = '+shipByDate' THEN [ShipByDate] END,
                CASE WHEN @SortingColumn = '-shipByDate' THEN [ShipByDate] END DESC,

                CASE WHEN @SortingColumn = '+shipCounty' THEN [ShipCounty] END,
                CASE WHEN @SortingColumn = '-shipCounty' THEN [ShipCounty] END DESC,

                CASE WHEN @SortingColumn = '+shipLocation' THEN [ShipLocation] END,
                CASE WHEN @SortingColumn = '-shipLocation' THEN [ShipLocation] END DESC,

                CASE WHEN @SortingColumn = '+shippedOnDate' THEN [ShippedOnDate] END,
                CASE WHEN @SortingColumn = '-shippedOnDate' THEN [ShippedOnDate] END DESC,

                CASE WHEN @SortingColumn = '+shippingAddress' THEN [ShippingAddress] END,
                CASE WHEN @SortingColumn = '-shippingAddress' THEN [ShippingAddress] END DESC,

                CASE WHEN @SortingColumn = '+Shippingcity' THEN [ShippingCity] END,
                CASE WHEN @SortingColumn = '-Shippingcity' THEN [ShippingCity] END DESC,

                CASE WHEN @SortingColumn = '+shippingInstruc' THEN [ShippingInstruc] END,
                CASE WHEN @SortingColumn = '-shippingInstruc' THEN [ShippingInstruc] END DESC,

                CASE WHEN @SortingColumn = '+shippingStatus' THEN [ShippingStatus] END,
                CASE WHEN @SortingColumn = '-shippingStatus' THEN [ShippingStatus] END DESC,

                CASE WHEN @SortingColumn = '+shipVia' THEN [ShipVia] END,
                CASE WHEN @SortingColumn = '-shipVia' THEN [ShipVia] END DESC,

                CASE WHEN @SortingColumn = '+shipZip' THEN [ShipZip] END,
                CASE WHEN @SortingColumn = '-shipZip' THEN [ShipZip] END DESC,

                CASE WHEN @SortingColumn = '+shrinkSleeveCutHeight' THEN [ShrinkSleeveCutHeight] END,
                CASE WHEN @SortingColumn = '-shrinkSleeveCutHeight' THEN [ShrinkSleeveCutHeight] END DESC,

                CASE WHEN @SortingColumn = '+shrinkSleeveLayFlat' THEN [ShrinkSleeveLayFlat] END,
                CASE WHEN @SortingColumn = '-shrinkSleeveLayFlat' THEN [ShrinkSleeveLayFlat] END DESC,

                CASE WHEN @SortingColumn = '+shrinkSleeveOverLap' THEN [ShrinkSleeveOverLap] END,
                CASE WHEN @SortingColumn = '-shrinkSleeveOverLap' THEN [ShrinkSleeveOverLap] END DESC,

                CASE WHEN @SortingColumn = '+sizeAcross' THEN [SizeAcross] END,
                CASE WHEN @SortingColumn = '-sizeAcross' THEN [SizeAcross] END DESC,

                CASE WHEN @SortingColumn = '+sizeAround' THEN [SizeAround] END,
                CASE WHEN @SortingColumn = '-sizeAround' THEN [SizeAround] END DESC,

                CASE WHEN @SortingColumn = '+sourceCustomerId' THEN [SourceCustomerId] END,
                CASE WHEN @SortingColumn = '-sourceCustomerId' THEN [SourceCustomerId] END DESC,

                CASE WHEN @SortingColumn = '+startsAt' THEN [StartsAt] END,
                CASE WHEN @SortingColumn = '-startsAt' THEN [StartsAt] END DESC,

                CASE WHEN @SortingColumn = '+stockDesc1' THEN [StockDesc1] END,
                CASE WHEN @SortingColumn = '-stockDesc1' THEN [StockDesc1] END DESC,

                CASE WHEN @SortingColumn = '+stockDesc2' THEN [StockDesc2] END,
                CASE WHEN @SortingColumn = '-stockDesc2' THEN [StockDesc2] END DESC,

                CASE WHEN @SortingColumn = '+stockDesc3' THEN [StockDesc3] END,
                CASE WHEN @SortingColumn = '-stockDesc3' THEN [StockDesc3] END DESC,

                CASE WHEN @SortingColumn = '+stockNotes' THEN [StockNotes] END,
                CASE WHEN @SortingColumn = '-stockNotes' THEN [StockNotes] END DESC,

                CASE WHEN @SortingColumn = '+stockReceived' THEN [StockReceived] END,
                CASE WHEN @SortingColumn = '-stockReceived' THEN [StockReceived] END DESC,

                CASE WHEN @SortingColumn = '+stockTicketType' THEN [StockTicketType] END,
                CASE WHEN @SortingColumn = '-stockTicketType' THEN [StockTicketType] END DESC,

                CASE WHEN @SortingColumn = '+tab' THEN [Tab] END,
                CASE WHEN @SortingColumn = '-tab' THEN [Tab] END DESC,

                CASE WHEN @SortingColumn = '+taskName' THEN [TaskName] END,
                CASE WHEN @SortingColumn = '-taskName' THEN [TaskName] END DESC,

                CASE WHEN @SortingColumn = '+ticketId' THEN [TicketId] END,
                CASE WHEN @SortingColumn = '-ticketId' THEN [TicketId] END DESC,

                CASE WHEN @SortingColumn = '+ticketNotes' THEN [TicketNotes] END,
                CASE WHEN @SortingColumn = '-ticketNotes' THEN [TicketNotes] END DESC,

                CASE WHEN @SortingColumn = '+ticketNumber' THEN [TicketNumber] END,
                CASE WHEN @SortingColumn = '-ticketNumber' THEN [TicketNumber] END DESC,

                CASE WHEN @SortingColumn = '+ticketPoints' THEN [TicketPoints] END,
                CASE WHEN @SortingColumn = '-ticketPoints' THEN [TicketPoints] END DESC,

                CASE WHEN @SortingColumn = '+priority' THEN [TicketPriority] END,
                CASE WHEN @SortingColumn = '-priority' THEN [TicketPriority] END DESC,

                CASE WHEN @SortingColumn = '+status' THEN [TicketStatus] END,
                CASE WHEN @SortingColumn = '-status' THEN [TicketStatus] END DESC,

                CASE WHEN @SortingColumn = '+ticketType' THEN [TicketType] END,
                CASE WHEN @SortingColumn = '-ticketType' THEN [TicketType] END DESC,

                CASE WHEN @SortingColumn = '+tool1Descr' THEN [Tool1Descr] END,
                CASE WHEN @SortingColumn = '-tool1Descr' THEN [Tool1Descr] END DESC,

                CASE WHEN @SortingColumn = '+tool2Descr' THEN [Tool2Descr] END,
                CASE WHEN @SortingColumn = '-tool2Descr' THEN [Tool2Descr] END DESC,

                CASE WHEN @SortingColumn = '+tool3Descr' THEN [Tool3Descr] END,
                CASE WHEN @SortingColumn = '-tool3Descr' THEN [Tool3Descr] END DESC,

                CASE WHEN @SortingColumn = '+tool4Descr' THEN [Tool4Descr] END,
                CASE WHEN @SortingColumn = '-tool4Descr' THEN [Tool4Descr] END DESC,

                CASE WHEN @SortingColumn = '+tool5Descr' THEN [Tool5Descr] END,
                CASE WHEN @SortingColumn = '-tool5Descr' THEN [Tool5Descr] END DESC,

                CASE WHEN @SortingColumn = '+toolsReceived' THEN [ToolsReceived] END,
                CASE WHEN @SortingColumn = '-toolsReceived' THEN [ToolsReceived] END DESC,

                CASE WHEN @SortingColumn = '+useTurretRewinder' THEN [UseTurretRewinder] END,
                CASE WHEN @SortingColumn = '-useTurretRewinder' THEN [UseTurretRewinder] END DESC

            OFFSET (@PageNumber-1) * @NumberOfRows ROWS
            FETCH NEXT @NumberOfRows ROWS ONLY;


            SELECT *, 'tbl_openTicketsReportLTM' AS __dataset_tableName
            FROM [dbo].[#FieldSortedPaginatedReport]
            ORDER BY [RowNumber];

            
            INSERT INTO [#TicketIdsInCurrentPage]
            SELECT DISTINCT [TicketId]
            FROM [dbo].[#FieldSortedPaginatedReport];
        END

    END


    -- Total row count
    SELECT COUNT(1) AS [TotalCount], 'tbl_openTickets_Count' AS __dataset_tableName
    FROM [dbo].[#FinalSchedule];


    -- Ticket attribute values
    SELECT
        TAV.[TicketId],
        TAV.[Name],
        TAV.[Value],
        'tbl_ticketAttributeValues' AS __dataset_tableName 
    FROM [dbo].[#TicketIdsInCurrentPage] TIS 
        INNER JOIN [dbo].[TicketAttributeValues] TAV WITH (NOLOCK) ON TAV.[TicketId] = TIS.[TicketId]
        INNER JOIN @TicketAttributes TA ON TA.[Field] = TAV.[Name];

END