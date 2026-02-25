CREATE PROCEDURE [dbo].[spUnScheduledTicketsData_V2]
	@PageNumber				AS INT = 1,
	@RowsOfPage				AS INT = 1000,
	@SortingColumn			AS VARCHAR(100) = 'default',
	@startDate				AS DATETIME = NULL,
	@endDate				AS DATETIME = NULL,
    @sourceTicketNumbers	AS UDT_SINGLEFIELDFILTER READONLY,
    @customers				AS UDT_SINGLEFIELDFILTER READONLY,
    @csr					AS UDT_SINGLEFIELDFILTER READONLY,
    @salesPerson			AS UDT_SINGLEFIELDFILTER READONLY,
    @facilities				AS UDT_SINGLEFIELDFILTER READONLY,
	@workcenters			AS UDT_SINGLEFIELDFILTER READONLY,
	@ticketAttributeNames	AS UDT_SINGLEFIELDFILTER READONLY,
	@valuestreams			AS UDT_SINGLEFIELDFILTER READONLY,
	@userAssignedFacilities AS UDT_SINGLEFIELDFILTER READONLY
AS
BEGIN
    DROP TABLE IF EXISTS #FilteredEquipments;
    DROP TABLE IF EXISTS #TicketDependentRaw;
    DROP TABLE IF EXISTS #TicketTaskRaw;
    DROP TABLE IF EXISTS #TicketTaskFeasiblility;
    DROP TABLE IF EXISTS #ScheduleOverrideNotes;
    DROP TABLE IF EXISTS #TicketsInSchedule;
    DROP TABLE IF EXISTS #ColumnPerfData;
    DROP TABLE IF EXISTS #RowPerfData;
    DROP TABLE IF EXISTS #TicketToolData;
    DROP TABLE IF EXISTS #TicketStockData;
    DROP TABLE IF EXISTS #TempTicketGeneralNotesCount;
    DROP TABLE IF EXISTS #RecentSchedules;
    DROP TABLE IF EXISTS #DistinctScheduledTickets;
    DROP TABLE IF EXISTS #UnscheduledTickets;
    DROP TABLE IF EXISTS #DeduplicatedUnscheduledTickets;
    DROP TABLE IF EXISTS #SortedPaginatedReport;
    DROP TABLE IF EXISTS #TicketAttribute;
    DROP TABLE IF EXISTS #TicketsInCurrentPage;


	DECLARE 
		@IsStockAvailabilityEnabled			BIT = 0,
		@IsMultiFacilitySchedulingEnabled	BIT = 0,
		@Yesterday							DATETIME = DATEADD(DAY, -1, GETUTCDATE()),
		@DayBeforeYesterday					DATETIME = DATEADD(DAY, -2, GETUTCDATE());


	-- Equipments filtered based ON the facilities AND workcenters
	SELECT DISTINCT
        EM.ID,
        EM.SourceEquipmentId,
        EM.WorkcenterTypeId,
        EM.WorkCenterName,
        EM.FacilityId,
        EM.FacilityName,
        EM.AvailableForPlanning,
        EM.AvailableForScheduling,
        EM.IsEnabled
	INTO #FilteredEquipments
	FROM EquipmentMaster EM WITH (NOLOCK)
    LEFT JOIN EquipmentValueStream EVS WITH (NOLOCK) ON EM.ID = EVS.EquipmentId
	WHERE (NOT EXISTS (SELECT 1 FROM @facilities) OR FacilityId IN (SELECT Field FROM @facilities))
		AND (NOT EXISTS (SELECT 1 FROM @workcenters) OR WorkcenterTypeId IN (SELECT Field FROM @workcenters))
		AND (NOT EXISTS (SELECT 1 FROM @valuestreams) OR EVS.ValueStreamId IN (SELECT Field FROM @valuestreams));


	SELECT @IsStockAvailabilityEnabled = CV.Value  
	FROM ConfigurationValue CV WITH (NOLOCK)
	INNER JOIN ConfigurationMaster CM WITH (NOLOCK) ON CM.Id = CV.ConfigId
	WHERE CM.NAME = 'EnableAutomaticStockAvailability';


	SELECT @IsMultiFacilitySchedulingEnabled = CV.Value  
	FROM ConfigurationValue CV WITH (NOLOCK)
	INNER JOIN ConfigurationMaster CM WITH (NOLOCK) ON CM.Id = CV.ConfigId
	WHERE CM.NAME = 'EnableMultiFacilityScheduling';


	SELECT 
		TTD.TicketId,
		MIN(CAST(TT.IsProductionReady AS INT)) AS IsDependentProdReady, 
		TTDp.DependentTicketId  
	INTO #TicketDependentRaw
	FROM TicketTaskDependency TTDP WITH (NOLOCK)
		INNER JOIN TicketTask TT WITH (NOLOCK) ON TT.TicketId = TTDP.DependentTicketId
		INNER JOIN TicketTaskData TTD WITH (NOLOCK) ON TTDP.TicketTaskDataId = TTD.Id
	GROUP BY TTDP.DependentTicketId, TTD.TicketId;


	SELECT 
		TT.TicketId,
		CASE
            WHEN MAX(FR.ID) IS NULL THEN 0
            ELSE 1
        END AS FeasibleRoutesString,
		CASE
			WHEN ((MAX(SR.Id) IS NULL AND Max(SO.ID) IS NULL AND Max(CAST( TT.IsProductionReady AS INT)) = 1)
				OR (MAX(SR.Id) IS NULL AND Max(CAST(SO.IsScheduled AS INT )) = 1 AND MAX(CAST(TT.IsProductionReady AS INT)) = 0)
				OR (MAX(SR.Id) IS NULL AND Max(CAST(SO.IsScheduled AS INT )) = 1 AND MAX(CAST(TT.IsProductionReady AS INT)) = 1))
				AND (MAX(CAST(ISNULL(TDR.IsDependentProdReady, 1) AS INT)) = 1)
			THEN 1 
			ELSE 0
		END AS ProductionReady
    INTO #TicketTaskRaw
	FROM TicketTask TT WITH (NOLOCK)
	     INNER JOIN TicketMaster TM WITH (NOLOCK) ON TT.TicketId = TM.ID
		 LEFT JOIN #TicketDependentRaw TDR ON TDR.TicketId = TM.ID
		 INNER JOIN #FilteredEquipments EM ON EM.SourceEquipmentId IN (TM.Press, TM.EquipId, TM.Equip2Id, TM.Equip3Id, TM.Equip4Id, TM.RewindEquipNum, TM.Equip6Id, Equip7Id)
		 LEFT JOIN FeasibleRoutes FR WITH (NOLOCK) ON TT.Id = FR.TaskId AND FR.RouteFeasible = 1
		 LEFT JOIN ScheduleOverride SO WITH (NOLOCK) ON TT.TicketId = SO.TicketId AND TT.TaskName = SO.TaskName 
		 LEFT JOIN ScheduleReport SR WITH (NOLOCK) ON SR.SourceTicketId = TM.SourceTicketId AND SR.TaskName = TT.TaskName
	WHERE 
		((IsProductionReady = 0 AND SR.Id IS NULL) OR (IsProductionReady = 1 AND (SO.IsScheduled = 0 OR SR.Id IS NULL)))
		AND TT.IsComplete = 0
		AND (NOT EXISTS (SELECT 1 FROM @customers) OR TM.CustomerName IN (SELECT Field FROM @customers))
		AND (NOT EXISTS (SELECT 1 FROM @sourceTicketNumbers) OR TM.SourceTicketId IN (SELECT Field FROM @sourceTicketNumbers))
		AND (NOT EXISTS (SELECT 1 FROM @csr) OR TM.ITSName IN (SELECT Field FROM @csr))
		AND (NOT EXISTS (SELECT 1 FROM @salesPerson) OR TM.OTSName IN (SELECT Field FROM @salesPerson))
	GROUP BY TT.TicketId, TT.TaskName;


	SELECT 
        TicketId,
        CASE
            WHEN MIN(FeasibleRoutesString) = 0 THEN 0
            ELSE 1
        END AS TaskFeasible,
        Max(ProductionReady) AS ProductionReadyTicket
    INTO #TicketTaskFeasiblility
    FROM #TicketTaskRaw
    GROUP BY TicketId;


	SELECT DISTINCT SO.TicketId, Notes 
	INTO #ScheduleOverrideNotes
    FROM ScheduleOverride SO WITH (NOLOCK)
        INNER JOIN #TicketTaskFeasiblility UT ON SO.TicketId = UT.TicketId;


	SELECT DISTINCT TicketId
    INTO #TicketsInSchedule
    FROM #TicketTaskFeasiblility;


	;WITH ColumnPERFCalc AS (
        SELECT DISTINCT TI.TicketId, P.ColumnPerf AS ColumnPerf
        FROM TicketItemInfo TI WITH (NOLOCK)
            INNER JOIN #TicketsInSchedule T ON TI.TicketId = T.TicketId
            LEFT JOIN ProductMaster P WITH (NOLOCK) ON TI.ProductId = P.Id
	)			   
		SELECT TicketId, STRING_AGG(ColumnPerf,',') AS ColumnPerf
		INTO #ColumnPerfData
		FROM ColumnPERFCalc WITH (NOLOCK)
		GROUP BY TicketId;


	;WITH RowPERFCalc AS (
        SELECT DISTINCT TI.TicketId, P.RowPerf AS RowPerf
        FROM TicketItemInfo TI WITH (NOLOCK)
            INNER JOIN #TicketsInSchedule T ON TI.TicketId = T.TicketId
            LEFT JOIN ProductMaster P WITH (NOLOCK) ON TI.ProductId = P.Id
	)
		SELECT TicketId, STRING_AGG(RowPerf,',') AS RowPerf
		INTO #RowPerfData
		FROM RowPERFCalc WITH (NOLOCK)
		GROUP BY TicketId;


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

		
	SELECT 
		TM.ID AS TicketId, 
		CASE
			WHEN COUNT(TGN.TicketId) > 0 THEN 1
			ELSE 0
		END AS IsTicketGeneralNotePresent
	INTO #TempTicketGeneralNotesCount
	FROM TicketMaster TM WITH (NOLOCK)
		LEFT JOIN TicketGeneralNotes TGN WITH (NOLOCK) ON TM.ID = TGN.TicketId
	GROUP BY TM.ID;


	-- Latest schedule archives for each ticket between last 24 to 48 hours.
	SELECT
		Id,
		SourceTicketId,
        ArchivedOnUTC,
        ROW_NUMBER() OVER (PARTITION BY SourceTicketId ORDER BY ArchivedOnUTC DESC) AS RowNum
	INTO #RecentSchedules
    FROM ScheduleArchive WITH (NOLOCK)
    WHERE ArchivedOnUTC < @Yesterday AND ArchivedOnUTC > @DayBeforeYesterday;


	-- Distict tickets present IN schedule report.
	SELECT DISTINCT SourceTicketId
	INTO #DistinctScheduledTickets
	FROM ScheduleReport SR WITH (NOLOCK);


	;WITH workcenterMaterialConsumingTickets AS 
	(
		SELECT EST.TicketId, 
		CASE 
			WHEN EST.EstTimeOfArrival > EST.FirstTaskDueDateTime THEN 0 
			ELSE 1 
		END AS IsCompletingOnTime
		FROM
			(
				SELECT 
					DISTINCT TSA.TicketId, 
					TSA.FirstAvailableTime AS EstTimeOfArrival,
					ROW_NUMBER() OVER(PARTITION BY TSA.TicketId ORDER BY TT.EstMaxDueDateTime) AS RNO,
					TT.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM TicketStockAvailability TSA WITH (NOLOCK)
					INNER JOIN TicketStockAvailabilityRawMaterialTickets TSARMT WITH (NOLOCK) ON TSA.Id = TSARMT.TicketStockAvailabilityId
					INNER JOIN TicketTask TT WITH (NOLOCK) ON TSA.TicketId = TT.TicketId
			) AS EST
		WHERE EST.RNO = 1
	),
	wcmPTArrivalTime AS
	(
		SELECT TicketId, EstTimeOfArrival 
		FROM 
			(
				SELECT
					TTI.TicketId AS TicketId,
					ROW_NUMBER() OVER(PARTITION BY TTI.TicketId ORDER BY TSA.FirstAvailableTime DESC) AS RNO,
					TSA.FirstAvailableTime AS EstTimeOfArrival
				FROM TicketStockAvailabilityRawMaterialTickets RMT WITH (NOLOCK)
					INNER JOIN TicketItemInfo TTI WITH (NOLOCK) ON RMT.TicketItemInfoId = TTI.Id
					INNER JOIN TicketStockAvailability TSA WITH (NOLOCK) ON RMT.TicketStockAvailabilityId = TSA.Id
			) AS T
		WHERE T.RNO = 1
	),
	workcenterMaterialProducingTickets AS
	(
		SELECT 
			DISTINCT TicketId,  
			CASE 
				WHEN T.EstTimeOfArrival > T.FirstTaskDueDateTime THEN 0 
				ELSE 1 
			END AS IsCompletingOnTime
		FROM
			(
				SELECT 
					PT.TicketId, 
					PT.EstTimeOfArrival,  
					ROW_NUMBER() OVER(PARTITION BY PT.TicketId ORDER BY TT.EstMaxDueDateTime) AS RNO,
					TT.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM wcmPTArrivalTime PT
					INNER JOIN TicketItemInfo TII ON PT.TicketId = TII.TicketId
					INNER JOIN TicketStockAvailabilityRawMaterialTickets RMT ON TII.Id = RMT.TicketItemInfoId
					INNER JOIN TicketStockAvailability TSA ON RMT.TicketStockAvailabilityId = TSA.Id
					INNER JOIN TicketTask TT ON TSA.TicketId = TT.TicketId
			) T
		WHERE T.RNO = 1
	)

	SELECT 
	--- Ticket Fields 
		TM.SourceTicketId AS TicketNumber,
		TM.ID AS TicketId,
		TM.CustomerName AS CustomerName,
		TM.GeneralDescription AS GeneralDescription,
		ISNULL(TSC.CustomerRankScore, 0) * ISNULL(TSC.DueDateScore, 0) * ISNULL(TSC.PriorityScore, 0) * ISNULL(TSC.RevenueScore, 0) AS TicketPoints,
		TS.ShipByDateTime AS ShipByDate,
		TM.OrderDate AS OrderDate,
		TM.SourceCustomerId AS SourceCustomerId,
		Tm.CustomerPO AS CustomerPO,
		TM.SourcePriority AS TicketPriority,
		TM.SourceFinishType AS FinishType,
		TM.isBackSidePrinted AS IsBackSidePrinted,
		TM.IsSlitOnRewind AS IsSlitOnRewind,
		TM.UseTurretRewinder AS UseTurretRewinder,
		TM.EstTotalRevenue AS EstTotalRevenue,
		Tm.SourceTicketType AS TicketType,
		TM.PriceMode AS PriceMode,
		TM.FinalUnwind AS FinalUnwind,
		TM.SourceStatus AS TicketStatus,
		TM.BackStageColorStrategy AS BackStageColorStrategy,
		TM.Pinfeed AS Pinfeed,
		TM.IsPrintReversed AS IsPrintReversed,
		Tm.SourceTicketNotes AS TicketNotes,
		Tm.EndUserNum  AS EndUserNum,
		TM.EndUserName AS EndUserName,
		TM.SourceCreatedOn AS CreatedOn,
		TM.SourceModifiedOn AS ModifiedOn,
		TM.Tab AS Tab,
		TM.SizeAround AS SizeAround,
		TM.ShrinkSleeveLayFlat AS ShrinkSleeveLayFlat,
		TM.Shape AS Shape,
		TM.SourceStockTicketType AS StockTicketType,
		TPP.ArtWorkComplete AS ArtWorkComplete,
		TPP.InkReceived  AS InkReceived,
		TPP.ProofComplete AS ProofComplete,
		TPP.PlateComplete AS PlateComplete,
		TPP.ToolsReceived AS ToolsReceived,
		TM.ITSName AS ITSName,
		TM.OTSName AS OTSName,
		TD.ConsecutiveNumber AS ConsecutiveNumber,
		TD.Quantity AS Quantity,
		TD.ActualQuantity AS ActualQuantity,
		TD.SizeAcross AS SizeAcross,
		TD.ColumnSpace AS ColumnSpace,
		TD.RowSpace AS RowSpace,
		TD.NumAcross AS NumAcross,
		TD.NumAroundPlate AS NumAroundPlate,
		TD.LabelRepeat AS LabelRepeat,
		TD.FinishedNumAcross AS FinishedNumAcross,
		TD.FinishedNumLabels AS FinishedNumLabels,
		TD.Coresize AS Coresize,
		TD.OutsideDiameter AS OutsideDiameter,
		TD.EsitmatedLength AS EstimatedLength,
		TD.OverRunLength AS OverRunLength,
		TD.NoPlateChanges AS NoOfPlateChanges,
		TS.ShippedOnDate AS ShippedOnDate,
		TS.SourceShipVia AS ShipVia,
		TS.DueOnsiteDate AS DueOnsiteDate,
		TS.ShippingStatus AS ShippingStatus,
		TS.ShippingAddress AS ShippingAddress,
		TS.Shippingcity AS Shippingcity,
		CASE
            WHEN TPP.StockReceived LIKE '%IN%' THEN 1
            ELSE 0
        END AS StockReceived,
		TM.TicketCategory AS TicketCategory,  -- 0 -> Default, 1 -> Parent, 2 -> SubTicket

		--- New fields added
		CD.ColumnPerf AS ColumnPerf,
		RD.RowPerf AS RowPerf,
		TM.ITSAssocNum AS ITSAssocNum,
		TM.OTSAssocNum AS OTSAssocNum,
		TS.ShippingInstruc AS ShippingInstruc,
		TM.DateDone AS DateDone,
		TS.ShipAttnEmailAddress AS ShipAttnEmailAddress,
		TS.ShipLocation AS ShipLocation,
		TS.ShipZip AS ShipZip,
		TS.BillAddr1 AS BillAddr1,
		TS.BillAddr2 AS BillAddr2,
		TS.BillCity AS BillCity,
		TS.BillZip AS BillZip,
		TS.BillCountry AS BillCountry,
		TM.IsStockAllocated AS IsStockAllocated,
		TM.EndUserPO AS EndUserPO,
		TTD.Tool1Desc AS Tool1Descr,
		TTD.Tool2Desc AS Tool2Descr,
		TTD.Tool3Desc AS Tool3Descr,
		TTD.Tool4Desc AS Tool4Descr,
		TTD.Tool5Desc AS Tool5Descr,
		TD.ActFootage AS ActFootage,
		TM.EstPackHrs AS EstPackHrs,
		TM.ActPackHrs AS ActPackHrs,
		TM.InkStatus AS InkStatus,
		TS.BillState AS BillState,
		TM.CustContact AS CustContact,
		TD.CoreType AS CoreType,
		TD.RollUnit AS RollUnit,
		TD.RollLength AS RollLength,
		TM.FinishNotes AS FinishNotes,
		TS.ShipCounty AS ShipCounty,
		TM.StockNotes AS StockNotes,
		TM.CreditHoldOverride AS CreditHoldOverride,
		TM.ShrinkSleeveOverLap AS ShrinkSleeveOverLap,
		TM.ShrinkSleeveCutHeight AS ShrinkSleeveCutHeight,
		TSD.Stock1Desc AS StockDesc1,
		TSD.Stock2Desc AS StockDesc2,
		TSD.Stock3Desc AS StockDesc3,

		--- Unschedule report specific
		SO.Notes AS SchedulingNotes,

		---- Mandatory indicators
		TTF.ProductionReadyTicket AS ProductionReadyTicket,
		TTF.TaskFeasible AS TaskFeasible,
		EM.WorkCenterName AS WorkcenterName,
		EM.WorkcenterTypeId AS WorkcenterId, 
		EM.FacilityId AS FacilityId,
		TT.IsTicketGeneralNotePresent,
		CASE 
			WHEN @IsStockAvailabilityEnabled = 1 THEN TM.StockStatus
			ELSE NULL
		END AS StockStatus,
		CASE 
			WHEN PT.TicketId IS NOT NULL THEN 1
			WHEN CT.TicketId IS NOT NULL THEN 2
			ELSE 0
		END AS WorkcenterMaterialTicketCategory,
		CASE 
			WHEN CT.TicketId IS NOT NULL THEN CT.IsCompletingOnTime
			WHEN PT.TicketId IS NOT NULL THEN PT.IsCompletingOnTime
			ELSE NULL
		END AS IsCompletingOnTime,

	    CASE
			WHEN RS.SourceTicketId IS NOT NULL AND DST.SourceTicketId IS NULL THEN 1
		    ELSE 0
		END AS IsFirstDay, -- (Ticket number - IN latest schedule archive, but not IN schedule report - First day Uncheduled)
		COALESCE(1 - (CAST(TD.ActualQuantity AS REAL) / NULLIF(CAST(TD.Quantity AS REAL), 0)), 0) * TM.EstTotalRevenue AS WIPValue

	INTO #UnscheduledTickets
	FROM #TicketTaskFeasiblility TTF WITH (NOLOCK)
		INNER JOIN TicketMaster TM WITH (NOLOCK) ON TTF.TicketId = TM.ID
		INNER JOIN TicketPreProcess TPP WITH (NOLOCK) ON TTF.TicketId = TPP.TicketId
		INNER JOIN #FilteredEquipments EM WITH (NOLOCK) ON EM.SourceEquipmentId IN (TM.Press, TM.EquipId, TM.Equip2Id, TM.Equip3Id, TM.Equip4Id, TM.RewindEquipNum, TM.Equip6Id, Equip7Id)
		INNER JOIN TicketDimensions TD WITH (NOLOCK) ON TTF.TicketId = TD.TicketId
		INNER JOIN TicketShipping TS WITH (NOLOCK) ON TS.TicketId = TM.ID
		INNER JOIN TicketScore TSC WITH (NOLOCK) ON TSC.TicketId = TM.ID
		LEFT JOIN #ScheduleOverrideNotes SO ON TM.Id = SO.TicketId
		LEFT JOIN #ColumnPerfData CD ON TM.ID = CD.TicketId
		LEFT JOIN #RowPerfData RD ON TM.ID = RD.TicketId
		LEFT JOIN #TicketToolData TTD ON TM.ID = TTD.TicketId
		LEFT JOIN #TicketStockData TSD ON TM.ID = TSD.TicketId
		LEFT JOIN #TempTicketGeneralNotesCount TT ON TM.ID = TT.TicketId
		LEFT JOIN workcenterMaterialConsumingTickets CT ON TM.ID = CT.TicketId
		LEFT JOIN workcenterMaterialProducingTickets PT ON TM.ID = PT.TicketId
		LEFT JOIN #RecentSchedules RS ON TM.SourceTicketId = RS.SourceTicketId AND RS.RowNum = 1
		LEFT JOIN #DistinctScheduledTickets DST ON RS.SourceTicketId = DST.SourceTicketId;


    ;WITH DeduplicatedDetails AS (
		SELECT ROW_NUMBER() OVER (PARTITION BY TicketNumber ORDER BY TicketNumber) AS DeduplicateRowNum, *
		FROM #UnscheduledTickets
	)
        SELECT *
        INTO #DeduplicatedUnscheduledTickets
        FROM DeduplicatedDetails
        WHERE DeduplicateRowNum = 1;


    -------CREATE TABLE SCRIPT--------------

    CREATE TABLE #SortedPaginatedReport
    (
		RowNumber INT IDENTITY(0,1) PRIMARY KEY,
        DeduplicateRowNum INT,
        TicketNumber NVARCHAR(255),
        TicketId VARCHAR(36),
        CustomerName NVARCHAR(255),
        GeneralDescription NVARCHAR(4000),
        TicketPoints NUMERIC,
        ShipByDate DATETIME,
        OrderDate DATETIME,
        SourceCustomerId NVARCHAR(36),
        CustomerPO NVARCHAR(255),
        TicketPriority NVARCHAR(255),
        FinishType NVARCHAR(255),
        IsBackSidePrinted BIT,
        IsSlitOnRewind BIT,
        UseTurretRewinder BIT,
        EstTotalRevenue REAL,
        TicketType SMALLINT,
        PriceMode NVARCHAR(4000),
        FinalUnwind NVARCHAR(4000),
        TicketStatus NVARCHAR(4000),
        BackStageColorStrategy NVARCHAR(4000),
        Pinfeed BIT,
        IsPrintReversed BIT,
        TicketNotes NVARCHAR(4000),
        EndUserNum NVARCHAR(4000),
        EndUserName NVARCHAR(4000),
        CreatedOn DATETIME,
        ModifiedOn DATETIME,
        Tab REAL,
        SizeAround REAL,
        ShrinkSleeveLayFlat REAL,
        Shape NVARCHAR(4000),
        StockTicketType SMALLINT,
        ArtWorkComplete BIT,
        InkReceived BIT,
        ProofComplete BIT,
        PlateComplete BIT,
        ToolsReceived BIT,
        ITSName NVARCHAR(1000),
        OTSName NVARCHAR(1000),
        ConsecutiveNumber BIT,
        Quantity INT,
        ActualQuantity INT,
        SizeAcross REAL,
        ColumnSpace REAL,
        RowSpace REAL,
        NumAcross SMALLINT,
        NumAroundPlate SMALLINT,
        LabelRepeat REAL,
        FinishedNumAcross REAL,
        FinishedNumLabels INT,
        Coresize REAL,
        OutsideDiameter REAL,
        EstimatedLength INT,
        OverRunLength REAL,
        NoOfPlateChanges INT,
        ShippedOnDate DATETIME,
        ShipVia NVARCHAR(4000),
        DueOnsiteDate DATETIME,
        ShippingStatus NVARCHAR(4000),
        ShippingAddress NVARCHAR(4000),
        Shippingcity NVARCHAR(1000),
        StockReceived INT,
        TicketCategory INT,
        ColumnPerf NVARCHAR(4000),
        RowPerf NVARCHAR(4000),
        ITSAssocNum NVARCHAR(1000),
        OTSAssocNum NVARCHAR(1000),
        ShippingInstruc NVARCHAR(4000),
        DateDone DATETIME,
        ShipAttnEmailAddress NVARCHAR(1000),
        ShipLocation NVARCHAR(1000),
        ShipZip NVARCHAR(255),
        BillAddr1 NVARCHAR(1000),
        BillAddr2 NVARCHAR(1000),
        BillCity NVARCHAR(255),
        BillZip NVARCHAR(255),
        BillCountry NVARCHAR(255),
        IsStockAllocated BIT,
        EndUserPO NVARCHAR(1000),
        Tool1Descr NVARCHAR(4000),
        Tool2Descr NVARCHAR(4000),
        Tool3Descr NVARCHAR(4000),
        Tool4Descr NVARCHAR(4000),
        Tool5Descr NVARCHAR(4000),
        ActFootage INT,
        EstPackHrs REAL,
        ActPackHrs REAL,
        InkStatus NVARCHAR(4000),
        BillState NVARCHAR(255),
        CustContact NVARCHAR(1000),
        CoreType NVARCHAR(255),
        RollUnit NVARCHAR(255),
        RollLength INT,
        FinishNotes NVARCHAR(4000),
        ShipCounty NVARCHAR(255),
        StockNotes NVARCHAR(4000),
        CreditHoldOverride BIT,
        ShrinkSleeveOverLap BIT,
        ShrinkSleeveCutHeight BIT,
        StockDesc1 NVARCHAR(4000),
        StockDesc2 NVARCHAR(4000),
        StockDesc3 NVARCHAR(4000),
        SchedulingNotes NVARCHAR(4000),
        ProductionReadyTicket BIT,
        TaskFeasible BIT,
        WorkcenterName NVARCHAR(32),
        WorkcenterId VARCHAR(36),
        FacilityId VARCHAR(36),
        IsTicketGeneralNotePresent INT,
        StockStatus VARCHAR(64),
        WorkcenterMaterialTicketCategory INT,
        IsCompletingOnTime INT,
		IsFirstDay BIT,
		WIPValue REAL,
		Value NVARCHAR(4000) DEFAULT ''
    );

    --------END OF CREATE TABLE SCRIPT----------				



	CREATE TABLE #TicketsInCurrentPage (TicketId NVARCHAR(36));

	 IF(@SortingColumn <> 'default')
     BEGIN

		----- Sorting BY a Ticket attribute value
		IF EXISTS (SELECT 1 FROM @ticketAttributeNames WHERE Field = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1))
		BEGIN

			--- Get Ticket attribute data type
			DECLARE @TicketAttributeType VARCHAR(50) = (SELECT DataType FROM TicketAttribute WHERE NAME = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1));


			--- Get Ticket attribute value of the sorting column
			SELECT TTR.TicketId, TAV.Value AS Value
			INTO #TicketAttribute
			FROM #TicketsInSchedule TTR
			    INNER JOIN TicketAttributeValues TAV WITH (NOLOCK) ON TTr.TicketId = TAV.TicketId AND TAV.NAME = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1);
						

			--- Add the sorting attribute value IN projection
			INSERT INTO #SortedPaginatedReport
			SELECT DUT.*, Ta.Value
			FROM #DeduplicatedUnscheduledTickets DUT
			    LEFT JOIN #TicketAttribute TA ON DUT.TicketId = TA.TicketId 
			ORDER BY
				---- ORDER BY attribute value
				CASE WHEN @TicketAttributeType = 'boolean' AND LEFT(@SortingColumn, 1) = '+' THEN CAST(TA.Value AS BIT) END,
				CASE WHEN @TicketAttributeType = 'boolean' AND LEFT(@SortingColumn, 1) = '-' THEN CAST(TA.Value AS BIT) END DESC,

				CASE WHEN @TicketAttributeType = 'decimal' AND LEFT(@SortingColumn, 1) = '+' THEN CAST(TA.Value AS REAL) END,
				CASE WHEN @TicketAttributeType = 'decimal' AND LEFT(@SortingColumn, 1) = '-' THEN CAST(TA.Value AS REAL) END DESC,

				CASE WHEN @TicketAttributeType = 'string' AND LEFT(@SortingColumn, 1) = '+' THEN CAST(TA.Value AS VARCHAR) END,
				CASE WHEN @TicketAttributeType = 'string' AND LEFT(@SortingColumn, 1) = '-' THEN CAST(TA.Value AS VARCHAR) END DESC

			OFFSET (@PageNumber-1) * @RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY;


			INSERT INTO #TicketsInCurrentPage
            SELECT DISTINCT TicketId
            FROM #DeduplicatedUnscheduledTickets;
		END
		ELSE
		BEGIN

            ---- Sorting BY TABLE fields
			INSERT INTO #SortedPaginatedReport
			SELECT *, ''
			FROM #DeduplicatedUnscheduledTickets
			ORDER BY 
				CASE WHEN @SortingColumn = '+backStageColorStrategy' THEN BackStageColorStrategy END,
				CASE WHEN @SortingColumn = '-backStageColorStrategy' THEN BackStageColorStrategy END DESC,

				CASE WHEN @SortingColumn = '+createdOn' THEN CreatedOn END,
				CASE WHEN @SortingColumn = '-createdOn' THEN CreatedOn END DESC,

				CASE WHEN @SortingColumn = '+customerName' THEN CustomerName END,
				CASE WHEN @SortingColumn = '-customerName' THEN CustomerName END DESC,

				CASE WHEN @SortingColumn = '+customerPO' THEN CustomerPO END,
				CASE WHEN @SortingColumn = '-customerPO' THEN CustomerPO END DESC,

				CASE WHEN @SortingColumn = '+endUserName' THEN EndUserName END,
				CASE WHEN @SortingColumn = '-endUserName' THEN EndUserName END DESC,

				CASE WHEN @SortingColumn = '+endUserNum' THEN EndUserNum END,
				CASE WHEN @SortingColumn = '-endUserNum' THEN EndUserNum END DESC,

				CASE WHEN @SortingColumn = '+estTotalRevenue' THEN EstTotalRevenue END,
				CASE WHEN @SortingColumn = '-estTotalRevenue' THEN EstTotalRevenue END DESC,

				CASE WHEN @SortingColumn = '+finalUnwind' THEN FinalUnwind END,
				CASE WHEN @SortingColumn = '-finalUnwind' THEN FinalUnwind END DESC,

				CASE WHEN @SortingColumn = '+finishType' THEN FinishType END,
				CASE WHEN @SortingColumn = '-finishType' THEN FinishType END DESC,

				CASE WHEN @SortingColumn = '+generalDescription' THEN GeneralDescription END,
				CASE WHEN @SortingColumn = '-generalDescription' THEN GeneralDescription END DESC,

				CASE WHEN @SortingColumn = '+isBackSidePrinted' THEN IsBackSidePrinted END,
				CASE WHEN @SortingColumn = '-isBackSidePrinted' THEN IsBackSidePrinted END DESC,

				CASE WHEN @SortingColumn = '+isPrintReversed' THEN IsPrintReversed END,
				CASE WHEN @SortingColumn = '-isPrintReversed' THEN IsPrintReversed END DESC,

				CASE WHEN @SortingColumn = '+isSlitOnRewind' THEN IsSlitOnRewind END,
				CASE WHEN @SortingColumn = '-isSlitOnRewind' THEN IsSlitOnRewind END DESC,

				CASE WHEN @SortingColumn = '+modifiedOn' THEN ModifiedOn END,
				CASE WHEN @SortingColumn = '-modifiedOn' THEN ModifiedOn END DESC,

				CASE WHEN @SortingColumn = '+orderDate' THEN OrderDate END,
				CASE WHEN @SortingColumn = '-orderDate' THEN OrderDate END DESC,

				CASE WHEN @SortingColumn = '+pinfeed' THEN Pinfeed END,
				CASE WHEN @SortingColumn = '-pinfeed' THEN Pinfeed END DESC,

				CASE WHEN @SortingColumn = '+priceMode' THEN PriceMode END,
				CASE WHEN @SortingColumn = '-priceMode' THEN PriceMode END DESC,

				CASE WHEN @SortingColumn = '+shape' THEN Shape END,
				CASE WHEN @SortingColumn = '-shape' THEN Shape END DESC,

				CASE WHEN @SortingColumn = '+shipByDate' THEN ShipByDate END,
				CASE WHEN @SortingColumn = '-shipByDate' THEN ShipByDate END DESC,

				CASE WHEN @SortingColumn = '+shrinkSleeveLayFlat' THEN ShrinkSleeveLayFlat END,
				CASE WHEN @SortingColumn = '-shrinkSleeveLayFlat' THEN ShrinkSleeveLayFlat END DESC,

				CASE WHEN @SortingColumn = '+sizeAround' THEN SizeAround END,
				CASE WHEN @SortingColumn = '-sizeAround' THEN SizeAround END DESC,

				CASE WHEN @SortingColumn = '+sourceCustomerId' THEN SourceCustomerId END,
				CASE WHEN @SortingColumn = '-sourceCustomerId' THEN SourceCustomerId END DESC,

				CASE WHEN @SortingColumn = '+tab' THEN Tab END,
				CASE WHEN @SortingColumn = '-tab' THEN Tab END DESC,

				CASE WHEN @SortingColumn = '+ticketId' THEN TicketId END,
				CASE WHEN @SortingColumn = '-ticketId' THEN TicketId END DESC,

				CASE WHEN @SortingColumn = '+ticketNotes' THEN TicketNotes END,
				CASE WHEN @SortingColumn = '-ticketNotes' THEN TicketNotes END DESC,

				CASE WHEN @SortingColumn = '+ticketNumber' THEN TicketNumber END,
				CASE WHEN @SortingColumn = '-ticketNumber' THEN TicketNumber END DESC,

				CASE WHEN @SortingColumn = '+ticketPoints' THEN TicketPoints END,
				CASE WHEN @SortingColumn = '-ticketPoints' THEN TicketPoints END DESC,

				CASE WHEN @SortingColumn = '+priority' THEN TicketPriority END,
				CASE WHEN @SortingColumn = '-priority' THEN TicketPriority END DESC,

				CASE WHEN @SortingColumn = '+status' THEN TicketStatus END,
				CASE WHEN @SortingColumn = '-status' THEN TicketStatus END DESC,

				CASE WHEN @SortingColumn = '+stockTicketType' THEN StockTicketType END,
				CASE WHEN @SortingColumn = '-stockTicketType' THEN StockTicketType END DESC,

				CASE WHEN @SortingColumn = '+ticketType' THEN TicketType END,
				CASE WHEN @SortingColumn = '-ticketType' THEN TicketType END DESC,

				CASE WHEN @SortingColumn = '+useTurretRewinder' THEN UseTurretRewinder END,
				CASE WHEN @SortingColumn = '-useTurretRewinder' THEN UseTurretRewinder END DESC,

				CASE WHEN @SortingColumn = '+itsName' THEN ITSName END,
				CASE WHEN @SortingColumn = '-itsName' THEN ITSName END DESC,

				CASE WHEN @SortingColumn = '+otsName' THEN OTSName END,
				CASE WHEN @SortingColumn = '-otsName' THEN OTSName END DESC,

				CASE WHEN @SortingColumn = '+artWorkComplete' THEN ArtWorkComplete END,
				CASE WHEN @SortingColumn = '-artWorkComplete' THEN ArtWorkComplete END DESC,

				CASE WHEN @SortingColumn = '+toolsReceived' THEN ToolsReceived END,
				CASE WHEN @SortingColumn = '-toolsReceived' THEN ToolsReceived END DESC,

				CASE WHEN @SortingColumn = '+inkReceived' THEN InkReceived END,
				CASE WHEN @SortingColumn = '-inkReceived' THEN InkReceived END DESC,

				CASE WHEN @SortingColumn = '+stockReceived' THEN StockReceived END,
				CASE WHEN @SortingColumn = '-stockReceived' THEN StockReceived END DESC,

				CASE WHEN @SortingColumn = '+plateComplete' THEN PlateComplete END,
				CASE WHEN @SortingColumn = '-plateComplete' THEN PlateComplete END DESC,

				CASE WHEN @SortingColumn = '+consecutiveNumber' THEN ConsecutiveNumber END,
				CASE WHEN @SortingColumn = '-consecutiveNumber' THEN ConsecutiveNumber END DESC,

				CASE WHEN @SortingColumn = '+quantity' THEN Quantity END,
				CASE WHEN @SortingColumn = '-quantity' THEN Quantity END DESC,

				CASE WHEN @SortingColumn = '+actualQuantity' THEN ActualQuantity END,
				CASE WHEN @SortingColumn = '-actualQuantity' THEN ActualQuantity END DESC,

				CASE WHEN @SortingColumn = '+sizeAcross' THEN SizeAcross END,
				CASE WHEN @SortingColumn = '-sizeAcross' THEN SizeAcross END DESC,

				CASE WHEN @SortingColumn = '+columnSpace' THEN ColumnSpace END,
				CASE WHEN @SortingColumn = '-columnSpace' THEN ColumnSpace END DESC,

				CASE WHEN @SortingColumn = '+rowSpace' THEN RowSpace END,
				CASE WHEN @SortingColumn = '-rowSpace' THEN RowSpace END DESC,

				CASE WHEN @SortingColumn = '+numAcross' THEN NumAcross END,
				CASE WHEN @SortingColumn = '-numAcross' THEN NumAcross END DESC,

				CASE WHEN @SortingColumn = '+numAroundPlate' THEN NumAroundPlate END,
				CASE WHEN @SortingColumn = '-numAroundPlate' THEN NumAroundPlate END DESC,

				CASE WHEN @SortingColumn = '+labelRepeat' THEN LabelRepeat END,
				CASE WHEN @SortingColumn = '-labelRepeat' THEN LabelRepeat END DESC,

				CASE WHEN @SortingColumn = '+finishedNumAcross' THEN FinishedNumAcross END,
				CASE WHEN @SortingColumn = '-finishedNumAcross' THEN FinishedNumAcross END DESC,

				CASE WHEN @SortingColumn = '+finishedNumLabels' THEN FinishedNumLabels END,
				CASE WHEN @SortingColumn = '-finishedNumLabels' THEN FinishedNumLabels END DESC,

				CASE WHEN @SortingColumn = '+coresize' THEN Coresize END,
				CASE WHEN @SortingColumn = '-coresize' THEN Coresize END DESC,

				CASE WHEN @SortingColumn = '+estimatedLength' THEN EstimatedLength END,
				CASE WHEN @SortingColumn = '-estimatedLength' THEN EstimatedLength END DESC,

				CASE WHEN @SortingColumn = '+overRunLength' THEN OverRunLength END,
				CASE WHEN @SortingColumn = '-overRunLength' THEN OverRunLength END DESC,

				CASE WHEN @SortingColumn = '+noOfPlateChanges' THEN NoOfPlateChanges END,
				CASE WHEN @SortingColumn = '-noOfPlateChanges' THEN NoOfPlateChanges END DESC,

				CASE WHEN @SortingColumn = '+shippedOnDate' THEN ShippedOnDate END,
				CASE WHEN @SortingColumn = '-shippedOnDate' THEN ShippedOnDate END DESC,

				CASE WHEN @SortingColumn = '+shipVia' THEN ShipVia END,
				CASE WHEN @SortingColumn = '-shipVia' THEN ShipVia END DESC,

				CASE WHEN @SortingColumn = '+dueOnsiteDate' THEN DueOnsiteDate END,
				CASE WHEN @SortingColumn = '-dueOnsiteDate' THEN DueOnsiteDate END DESC,

				CASE WHEN @SortingColumn = '+shippingStatus' THEN ShippingStatus END,
				CASE WHEN @SortingColumn = '-shippingStatus' THEN ShippingStatus END DESC,

				CASE WHEN @SortingColumn = '+shippingAddress' THEN ShippingAddress END,
				CASE WHEN @SortingColumn = '-shippingAddress' THEN ShippingAddress END DESC,

				CASE WHEN @SortingColumn = '+shippingcity' THEN Shippingcity END,
				CASE WHEN @SortingColumn = '-shippingcity' THEN Shippingcity END DESC,

				CASE WHEN @SortingColumn = '+taskFeasible' THEN TaskFeasible END,
				CASE WHEN @SortingColumn = '-taskFeasible' THEN TaskFeasible END DESC,

				CASE WHEN @SortingColumn = '+schedulingNotes' THEN SchedulingNotes END,
				CASE WHEN @SortingColumn = '-schedulingNotes' THEN SchedulingNotes END DESC,

				CASE WHEN @SortingColumn = '+columnPerf' THEN ColumnPerf END,
				CASE WHEN @SortingColumn = '-columnPerf' THEN ColumnPerf END DESC,

				CASE WHEN @SortingColumn = '+rowPerf' THEN rowPerf END,
				CASE WHEN @SortingColumn = '-rowPerf' THEN rowPerf END DESC,

				CASE WHEN @SortingColumn = '+iTSAssocNum' THEN iTSAssocNum END,
				CASE WHEN @SortingColumn = '-iTSAssocNum' THEN iTSAssocNum END DESC,

				CASE WHEN @SortingColumn = '+oTSAssocNum' THEN oTSAssocNum END,
				CASE WHEN @SortingColumn = '-oTSAssocNum' THEN oTSAssocNum END DESC,

				CASE WHEN @SortingColumn = '+shippingInstruc' THEN shippingInstruc END,
				CASE WHEN @SortingColumn = '-shippingInstruc' THEN shippingInstruc END DESC,

				CASE WHEN @SortingColumn = '+dateDone' THEN dateDone END,
				CASE WHEN @SortingColumn = '-dateDone' THEN dateDone END DESC,

				CASE WHEN @SortingColumn = '+shipAttnEmailAddress' THEN shipAttnEmailAddress END,
				CASE WHEN @SortingColumn = '-shipAttnEmailAddress' THEN shipAttnEmailAddress END DESC,

				CASE WHEN @SortingColumn = '+shipLocation' THEN shipLocation END,
				CASE WHEN @SortingColumn = '-shipLocation' THEN shipLocation END DESC,

				CASE WHEN @SortingColumn = '+shipZip' THEN shipZip END,
				CASE WHEN @SortingColumn = '-shipZip' THEN shipZip	 END DESC,

				CASE WHEN @SortingColumn = '+billAddr1' THEN billAddr1 END,
				CASE WHEN @SortingColumn = '-billAddr1' THEN billAddr1 END DESC,

				CASE WHEN @SortingColumn = '+billAddr2' THEN billAddr2 END,
				CASE WHEN @SortingColumn = '-billAddr2' THEN billAddr2 END DESC,

				CASE WHEN @SortingColumn = '+billCity' THEN billCity END,
				CASE WHEN @SortingColumn = '-billCity' THEN billCity END DESC,

				CASE WHEN @SortingColumn = '+billZip' THEN billZip END,
				CASE WHEN @SortingColumn = '-billZip' THEN billZip END DESC,

				CASE WHEN @SortingColumn = '+billCountry' THEN billCountry END,
				CASE WHEN @SortingColumn = '-billCountry' THEN billCountry END DESC,

				CASE WHEN @SortingColumn = '+isStockAllocated' THEN isStockAllocated END,
				CASE WHEN @SortingColumn = '-isStockAllocated' THEN isStockAllocated END DESC,

				CASE WHEN @SortingColumn = '+endUserPO' THEN endUserPO END,
				CASE WHEN @SortingColumn = '-endUserPO' THEN endUserPO END DESC,

				CASE WHEN @SortingColumn = '+tool1Descr' THEN tool1Descr END,
				CASE WHEN @SortingColumn = '-tool1Descr' THEN tool1Descr END DESC,

				CASE WHEN @SortingColumn = '+tool2Descr' THEN tool2Descr END,
				CASE WHEN @SortingColumn = '-tool2Descr' THEN tool2Descr END DESC,

				CASE WHEN @SortingColumn = '+tool3Descr' THEN tool3Descr END,
				CASE WHEN @SortingColumn = '-tool3Descr' THEN tool3Descr END DESC,

				CASE WHEN @SortingColumn = '+tool4Descr' THEN tool4Descr END,
				CASE WHEN @SortingColumn = '-tool4Descr' THEN tool4Descr END DESC,

				CASE WHEN @SortingColumn = '+tool5Descr' THEN tool5Descr END,
				CASE WHEN @SortingColumn = '-tool5Descr' THEN tool5Descr END DESC,

				CASE WHEN @SortingColumn = '+actFootage' THEN actFootage END,
				CASE WHEN @SortingColumn = '-actFootage' THEN actFootage END DESC,

				CASE WHEN @SortingColumn = '+estPackHrs' THEN estPackHrs END,
				CASE WHEN @SortingColumn = '-estPackHrs' THEN estPackHrs END DESC,

				CASE WHEN @SortingColumn = '+actPackHrs' THEN actPackHrs END,
				CASE WHEN @SortingColumn = '-actPackHrs' THEN actPackHrs END DESC,

				CASE WHEN @SortingColumn = '+inkStatus' THEN inkStatus END,
				CASE WHEN @SortingColumn = '-inkStatus' THEN inkStatus END DESC,

				CASE WHEN @SortingColumn = '+billState' THEN billState END,
				CASE WHEN @SortingColumn = '-billState' THEN billState END DESC,

				CASE WHEN @SortingColumn = '+custContact' THEN custContact END,
				CASE WHEN @SortingColumn = '-custContact' THEN custContact END DESC,

				CASE WHEN @SortingColumn = '+coreType' THEN coreType END,
				CASE WHEN @SortingColumn = '-coreType' THEN coreType END DESC,

				CASE WHEN @SortingColumn = '+rollLength' THEN rollLength END,
				CASE WHEN @SortingColumn = '-rollLength' THEN rollLength END DESC,

				CASE WHEN @SortingColumn = '+rollUnit' THEN rollUnit END,
				CASE WHEN @SortingColumn = '-rollUnit' THEN rollUnit END DESC,

				CASE WHEN @SortingColumn = '+finishNotes' THEN finishNotes END,
				CASE WHEN @SortingColumn = '-finishNotes' THEN finishNotes END DESC,

				CASE WHEN @SortingColumn = '+shipCounty' THEN shipCounty END,
				CASE WHEN @SortingColumn = '-shipCounty' THEN shipCounty END DESC,

				CASE WHEN @SortingColumn = '+stockNotes' THEN stockNotes END,
				CASE WHEN @SortingColumn = '-stockNotes' THEN stockNotes END DESC,

				CASE WHEN @SortingColumn = '+creditHoldOverride' THEN creditHoldOverride END,
				CASE WHEN @SortingColumn = '-creditHoldOverride' THEN creditHoldOverride END DESC,

				CASE WHEN @SortingColumn = '+shrinkSleeveOverLap' THEN shrinkSleeveOverLap END,
				CASE WHEN @SortingColumn = '-shrinkSleeveOverLap' THEN shrinkSleeveOverLap END DESC,

				CASE WHEN @SortingColumn = '+shrinkSleeveCutHeight' THEN shrinkSleeveCutHeight END,
				CASE WHEN @SortingColumn = '-shrinkSleeveCutHeight' THEN shrinkSleeveCutHeight END DESC,

				CASE WHEN @SortingColumn = '+stockDesc1' THEN stockDesc1 END,
				CASE WHEN @SortingColumn = '-stockDesc1' THEN stockDesc1 END DESC,

				CASE WHEN @SortingColumn = '+stockDesc2' THEN stockDesc2 END,
				CASE WHEN @SortingColumn = '-stockDesc2' THEN stockDesc2 END DESC,

				CASE WHEN @SortingColumn = '+stockDesc3' THEN stockDesc3 END,
				CASE WHEN @SortingColumn = '-stockDesc3' THEN stockDesc3 END DESC,

				CASE WHEN @SortingColumn = '+proofComplete' THEN ProofComplete END,
				CASE WHEN @SortingColumn = '-proofComplete' THEN ProofComplete END DESC,

				CASE WHEN @SortingColumn = '+stockStatus' THEN StockStatus END,
				CASE WHEN @SortingColumn = '-stockStatus' THEN StockStatus END DESC,

				CASE WHEN @SortingColumn = '+wipValue' THEN WIPValue END,
				CASE WHEN @SortingColumn = '-wipValue' THEN WIPValue END DESC

			OFFSET (@PageNumber-1) * @RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY;
	

			INSERT INTO #TicketsInCurrentPage
            SELECT DISTINCT TicketId
            FROM #DeduplicatedUnscheduledTickets;
		END
	END
  
   ---- Default sorting
    IF(@SortingColumn = 'default')
    BEGIN
    	INSERT INTO #SortedPaginatedReport
    	SELECT *, ''
    	FROM #DeduplicatedUnscheduledTickets
    	ORDER BY ShipByDate, TicketNumber
    	OFFSET (@PageNumber-1) * @RowsOfPage ROWS
    	FETCH NEXT @RowsOfPage ROWS ONLY;


    	INSERT INTO #TicketsInCurrentPage
        SELECT DISTINCT TicketId
        FROM #DeduplicatedUnscheduledTickets;
    END


	----- unscheduled tickets
	SELECT *, 'tbl_unscheduledTickets' AS __dataset_tableName
    FROM #SortedPaginatedReport
    ORDER BY RowNumber;

	----- csr
	SELECT DISTINCT ITSName AS CSR , 'tbl_csr' AS __dataset_tableName
    FROM #DeduplicatedUnscheduledTickets;

	----- sales person
	SELECT DISTINCT OTSName AS SalesPerson , 'tbl_salesPerson' AS __dataset_tableName
    FROM #DeduplicatedUnscheduledTickets;

	---- Ticket numbers
	SELECT DISTINCT(TicketNumber) AS TicketNumber , 'tbl_ticketNumbers' AS __dataset_tableName
    FROM #DeduplicatedUnscheduledTickets;

	---- CustomerNames
	SELECT DISTINCT(CustomerName) AS CustomerName , 'tbl_customerNames' AS __dataset_tableName
	FROM #DeduplicatedUnscheduledTickets; 

	---- Facilities
	SELECT DISTINCT(FacilityId) AS FacilityId , 'tbl_facilities' AS __dataset_tableName
	FROM #UnscheduledTickets;

	---- workcenter
	SELECT WorkcenterId AS WorkcenterId, Max(WorkcenterName) AS WorkcenterName, 'tbl_workcenters' AS __dataset_tableName
	FROM #UnscheduledTickets
    GROUP BY WorkcenterId;

	---- valuestreams
	SELECT DISTINCT
        EM.FacilityId,
        EVS.ValueStreamId,
        VS.NAME AS ValueStreamName,
        EM.ID AS EquipmentID,
        EM.WorkcenterTypeId AS WorkcenterId,
        'tbl_valueStreams' AS __dataset_tableName
	FROM EquipmentValueStream EVS WITH (NOLOCK)
	    INNER JOIN #FilteredEquipments EM ON EM.ID = EVS.EquipmentId
	    INNER JOIN ValueStream VS WITH (NOLOCK) ON EVS.ValueStreamId = VS.Id
	WHERE EM.IsEnabled = 1 AND EM.AvailableForPlanning = 1 AND EM.AvailableForScheduling = 1;


	SELECT
	    FR.TicketId AS TicketId,
	    TaskId AS TaskId,
	    TT.TaskName AS TaskName,
	    EM.ID AS EquipmentId,
	    EM.SourceEquipmentId AS EquipmentName,
	    FR.RouteFeasible AS RouteFeasible,
	    FR.ConstraintDescription AS ConstraintDescription,
	    TT.Sequence AS Sequence,
	    EM.FacilityId AS FacilityId,
	    'tbl_openRoutes' AS __dataset_tableName 
	FROM FeasibleRoutes FR WITH (NOLOCK)
	    INNER JOIN #DeduplicatedUnscheduledTickets DUT ON DUT.TicketId = FR.TicketId 
	    INNER JOIN TicketTask TT WITH (NOLOCK) ON FR.TaskId = TT.Id
	    INNER JOIN EquipmentMaster EM ON EM.ID = FR.EquipmentId
	ORDER BY TT.Sequence;


	SELECT
		TT.TicketId AS TicketId, 
		TT.TaskName AS TaskName,
		TT.[Sequence] AS Sequence,
		TT.Id AS TaskId,
		TT.IsComplete AS IsComplete,
		EM.FacilityId AS FacilityId,
		CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE CEILING(TT.EstTotalHours  * 60) END AS EstTotalHours,
		CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited,
		CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited,
		'tbl_ticketTasks' AS __dataset_tableName 
	FROM TicketTask TT WITH (NOLOCK)
        INNER JOIN #DeduplicatedUnscheduledTickets DUT ON TT.TicketId = DUT.TicketId
	    INNER JOIN EquipmentMaster EM ON EM.ID = TT.OriginalEquipmentId
        LEFT JOIN TicketTaskOverride TTO WITH (NOLOCK) ON TT.TicketId = TTO.TicketId AND TT.TaskName = TTO.TaskName
	ORDER BY Sequence;


	SELECT 
		TT.TicketId, 
		TM.SourceTicketId, 
		TM.CustomerName, 
		TM.ITSName AS CSR, 
		TM.OTSName AS SalesPerson,
		EM.WorkcenterTypeId AS WorkCenterId,
		EM.WorkCenterName AS WorkcenterName,
		EM.FacilityId,
		EM.FacilityName,
		EVS.ValueStreamId,
		VS.NAME AS ValueStreamName,
		'tbl_UnscheduledTicketFilters' AS __dataset_tableName 
	FROM TicketMaster TM WITH (NOLOCK)
		INNER JOIN TicketTask TT WITH (NOLOCK) ON TM.ID = TT.TicketId
		INNER JOIN TicketPreProcess TPP WITH (NOLOCK) ON TT.TicketId = TPP.TicketId
		INNER JOIN TicketDimensions TD WITH (NOLOCK) ON TT.TicketId = TD.TicketId
		INNER JOIN TicketShipping TS WITH (NOLOCK) ON TS.TicketId = TM.ID
		INNER JOIN TicketScore TSC WITH (NOLOCK) ON TSC.TicketId = TM.ID
		INNER JOIN #FilteredEquipments EM ON EM.SourceEquipmentId IN (TM.Press, TM.EquipId, TM.Equip2Id, TM.Equip3Id, TM.Equip4Id, TM.RewindEquipNum, TM.Equip6Id, Equip7Id)
		LEFT JOIN EquipmentValueStream EVS WITH (NOLOCK) ON EVS.EquipmentId = EM.ID
		LEFT JOIN ValueStream VS WITH (NOLOCK) ON EVS.ValueStreamId = VS.Id
		LEFT JOIN ScheduleOverride SO WITH (NOLOCK) ON TT.TicketId = SO.TicketId AND TT.TaskName = SO.TaskName 
		LEFT JOIN ScheduleReport SR WITH (NOLOCK) ON SR.SourceTicketId = TM.SourceTicketId AND SR.TaskName = TT.TaskName
	WHERE
		((IsProductionReady = 0 AND  SR.Id IS NULL) OR (IsProductionReady = 1 AND (SO.IsScheduled = 0 OR SR.Id IS NULL)))
		AND TT.IsComplete = 0
		AND (SELECT Count(1) FROM @userAssignedFacilities) = 0  OR EM.FacilityId  IN (SELECT field FROM @userAssignedFacilities)
	GROUP BY TT.TicketId, TM.SourceTicketId, TM.CustomerName, TM.ITSName, TM.OTSName, EM.WorkcenterTypeId, EM.WorkCenterName, EM.FacilityId, EM.FacilityName, EVS.ValueStreamId, VS.NAME;


	SELECT
        SO.TicketId AS TicketId,
	    MAX(SO.Notes) AS Notes,
	    Max(CAST(SO.IsScheduled AS INT)) AS IsScheduled,
	    'tbl_ScheduleOverride' AS __dataset_tableName 
	FROM ScheduleOverride SO WITH (NOLOCK)
        INNER JOIN #DeduplicatedUnscheduledTickets DUT ON SO.TicketId = DUT.TicketId
    GROUP BY SO.TicketId;


	SELECT  TAV.TicketId, TAV.NAME, TAV.Value,'tbl_ticketAttributeValues' AS __dataset_tableName 
	FROM #TicketsInCurrentPage S 
	INNER JOIN TicketAttributeValues TAV WITH (NOLOCK) ON S.TicketId COLLATE DATABASE_DEFAULT = TAV.TicketId COLLATE DATABASE_DEFAULT AND TAV.NAME IN (SELECT Field FROM @ticketAttributeNames) 


	----- TicketDependency projection
	SELECT (CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END) AS IsTicketDependencyEnabled, 'tbl_ticketDependency' AS __dataset_tableName
	FROM TaskRules TR WITH (NOLOCK)
	    INNER JOIN TaskInfo TI WITH (NOLOCK) ON TR.TaskInfoId = TI.Id
	WHERE TI.IsEnabled = 1 AND TR.RuleName = 'TicketDependency' AND TR.RuleText <> '' AND TR.RuleText <> N'NULL'


	----- EnableAutomaticStockAvailability projection
	SELECT 
	    CASE
            WHEN @IsStockAvailabilityEnabled = 1 THEN 'True'
            ELSE 'False'
        END AS isAutomaticStockAvailabilityEnabled,
	    'tbl_isAutomaticStockAvailabilityEnabled' AS __dataset_tableName;
	
	
	----- EnableMultiFacilityScheduling projection
	SELECT 
	    CASE
            WHEN @IsMultiFacilitySchedulingEnabled = 1 THEN 'True'
            ELSE 'False'
        END AS isMultiFacilitySchedulingEnabled,
	    'tbl_isMultiFacilitySchedulingEnabled' AS __dataset_tableName;


    DROP TABLE IF EXISTS #FilteredEquipments;
    DROP TABLE IF EXISTS #TicketDependentRaw;
    DROP TABLE IF EXISTS #TicketTaskRaw;
    DROP TABLE IF EXISTS #TicketTaskFeasiblility;
    DROP TABLE IF EXISTS #ScheduleOverrideNotes;
    DROP TABLE IF EXISTS #TicketsInSchedule;
    DROP TABLE IF EXISTS #ColumnPerfData;
    DROP TABLE IF EXISTS #RowPerfData;
    DROP TABLE IF EXISTS #TicketToolData;
    DROP TABLE IF EXISTS #TicketStockData;
    DROP TABLE IF EXISTS #TempTicketGeneralNotesCount;
    DROP TABLE IF EXISTS #RecentSchedules;
    DROP TABLE IF EXISTS #DistinctScheduledTickets;
    DROP TABLE IF EXISTS #UnscheduledTickets;
    DROP TABLE IF EXISTS #DeduplicatedUnscheduledTickets;
    DROP TABLE IF EXISTS #SortedPaginatedReport;
    DROP TABLE IF EXISTS #TicketAttribute;
    DROP TABLE IF EXISTS #TicketsInCurrentPage;

END