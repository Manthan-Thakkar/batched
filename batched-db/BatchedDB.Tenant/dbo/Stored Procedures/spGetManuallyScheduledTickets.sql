CREATE PROCEDURE [dbo].[spGetManuallyScheduledTickets]
    @workcenters AS [UDT_SINGLEFIELD] READONLY,
    @facilities AS UDT_SINGLEFIELDFILTER READONLY,
    @ticketAttributeNames AS UDT_SINGLEFIELDFILTER readonly
 
AS
BEGIN
 
	DECLARE 
		@spName					VARCHAR(100) = 'spGetManuallyScheduledTickets',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000,
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME,
		@IsStockAvailabilityEnabled BIT = 0,
		@CorelationId			NVARCHAR(4000) = null,
		@TenantId				VARCHAR(40) = NULL;


    DROP TABLE IF EXISTS [dbo].[#InfeasibleProdReadyTasks];
    DROP TABLE IF EXISTS [dbo].[#TicketToolData];
    DROP TABLE IF EXISTS [dbo].[#TicketStockData];
    DROP TABLE IF EXISTS [dbo].[#manuallyScheduledTickets];

 
    SELECT @IsStockAvailabilityEnabled = CV.Value  
    FROM ConfigurationValue CV
    INNER JOIN ConfigurationMaster CM on CM.Id = CV.ConfigId
    Where CM.Name = 'EnableAutomaticStockAvailability' 
    

    SET @blockName = 'Perf, Stock, and Tool Data'; SET @startTime = GETDATE();

        SELECT Tt.TicketId
        INTO #InfeasibleProdReadyTasks
            FROM TicketTask TT WITH (NOLOCK) LEFT JOIN FeasibleRoutes FR WITH (NOLOCK)   ON FR.TaskId = TT.Id
            WHERE FR.ID IS NULL AND Tt.IsComplete =0 AND TT.IsProductionReady = 1
            GROUP BY Tt.ticketId;


        SELECT DISTINCT [TicketId]
        INTO [dbo].[#DistinctTicketsWithTasks]
        FROM [dbo].[TicketTask] WITH (NOLOCK);

        ;WITH [TempTicketStocks] AS (
			SELECT
				[TicketId],
				[Sequence],
				[Notes]
			FROM [dbo].[TicketStock] WITH (NOLOCK)
			WHERE RoutingNo IS NULL
		)
        SELECT
            [TM].[ID] AS [TicketId],
            MAX([TS1].[Notes]) AS [Stock1Desc],
            MAX([TS2].[Notes]) AS [Stock2Desc],
            MAX([TS3].[Notes]) AS [Stock3Desc]
        INTO [dbo].[#TicketStockData]
        FROM [dbo].[TicketMaster] AS [TM] WITH (NOLOCK)
            INNER JOIN [dbo].[#DistinctTicketsWithTasks] AS [DTWT] ON [DTWT].[TicketId] = [TM].[Id]
            LEFT JOIN [TempTicketStocks] AS [TS1] WITH (NOLOCK) ON [TS1].[TicketId] = [TM].[Id]
            LEFT JOIN [TempTicketStocks] AS [TS2] WITH (NOLOCK) ON [TS2].[TicketId] = [TM].[Id]
            LEFT JOIN [TempTicketStocks] AS [TS3] WITH (NOLOCK) ON [TS3].[TicketId] = [TM].[Id]
        GROUP BY [TM].[ID];


        ;WITH [TempTicketTools] AS (
    	    SELECT
    		    [TicketId],
    		    [Sequence],
    		    [Description]
    	    FROM [dbo].[TicketTool] WITH (NOLOCK)
    	    WHERE [RoutingNumber] IS NULL
        )
    	    SELECT
    		    [TM].[ID] AS [TicketId],
    		    [TT1].[Description] AS [Tool1Desc], 
    		    [TT2].[Description] AS [Tool2Desc],
    		    [TT3].[Description] AS [Tool3Desc],
    		    [TT4].[Description] AS [Tool4Desc],
    		    [TT5].[Description] AS [Tool5Desc]
    	    INTO [dbo].[#TicketToolData]
    	    FROM [dbo].[TicketMaster] AS [TM] WITH (NOLOCK)
                INNER JOIN [dbo].[#DistinctTicketsWithTasks] AS [DTWT] ON [DTWT].[TicketId] = [TM].[Id]
    		    LEFT JOIN [TempTicketTools] AS [TT1] ON [TT1].[TicketId] = [TM].[ID] AND [TT1].[Sequence] = 1
    		    LEFT JOIN [TempTicketTools] AS [TT2] ON [TT2].[TicketId] = [TM].[ID] AND [TT2].[Sequence] = 2
    		    LEFT JOIN [TempTicketTools] AS [TT3] ON [TT3].[TicketId] = [TM].[ID] AND [TT3].[Sequence] = 3
    		    LEFT JOIN [TempTicketTools] AS [TT4] ON [TT4].[TicketId] = [TM].[ID] AND [TT4].[Sequence] = 4
    		    LEFT JOIN [TempTicketTools] AS [TT5] ON [TT5].[TicketId] = [TM].[ID] AND [TT5].[Sequence] = 5;


        SELECT 
                TM.GeneralDescription as GeneralDescription,
                TM.OrderDate as OrderDate,
                TM.SourceCustomerId as SourceCustomerId,
                TM.CustomerPO as CustomerPO,
                TM.SourcePriority as TicketPriority,
                TM.SourceFinishType as FinishType,
                TM.isBackSidePrinted as IsBackSidePrinted,
                TM.IsSlitOnRewind as IsSlitOnRewind,
                TM.UseTurretRewinder as UseTurretRewinder,
                TM.EstTotalRevenue as EstTotalRevenue,
                TM.SourceTicketType AS TicketType,
                TM.PriceMode as PriceMode,
                TM.FinalUnwind as FinalUnwind,
                TM.SourceStatus as TicketStatus,
                TM.BackStageColorStrategy as BackStageColorStrategy,
                TM.Pinfeed as Pinfeed,
                TM.IsPrintReversed as IsPrintReversed,
                TM.SourceTicketNotes as TicketNotes,
                TM.EndUserNum  as EndUserNum,
                TM.EndUserName as EndUserName,
                TM.SourceCreatedOn as CreatedOn,
                TM.SourceModifiedOn as ModifiedOn,
                TM.Tab as Tab,
                TM.SizeAround as SizeAround,
                TM.ShrinkSleeveLayFlat as ShrinkSleeveLayFlat,
                TM.Shape as Shape,
                TM.SourceStockTicketType as StockTicketType,
                TM.ITSName as ITSName,
                TM.OTSName as OTSName,
                TM.TicketCategory AS TicketCategory, -- 0 - Default, 1 - Parent, 2 - SubTicket
                TM.ITSAssocNum as ITSAssocNum,
                TM.OTSAssocNum as OTSAssocNum,
                TM.DateDone as DateDone,
                TM.IsStockAllocated as IsStockAllocated,
                TM.EndUserPO as EndUserPO,
                TM.EstPackHrs as EstPackHrs,
                TM.ActPackHrs as ActPackHrs,
                TM.InkStatus as InkStatus,
                TM.StockNotes as StockNotes,
                TM.CreditHoldOverride as CreditHoldOverride,
                TM.ShrinkSleeveOverLap as ShrinkSleeveOverLap,
                TM.ShrinkSleeveCutHeight as ShrinkSleeveCutHeight,
                TM.CustContact as CustContact,
                TM.FinishNotes as FinishNotes,
    
                TS.ShippedOnDate as ShippedOnDate,
                TS.SourceShipVia as ShipVia,
                TS.DueOnsiteDate as DueOnsiteDate,
                TS.ShippingStatus as ShippingStatus,
                TS.ShippingAddress as ShippingAddress,
                TS.Shippingcity as Shippingcity,
                TS.ShippingInstruc as ShippingInstruc,
                TS.ShipAttnEmailAddress as ShipAttnEmailAddress,
                TS.ShipLocation as ShipLocation,
                TS.ShipZip as ShipZip,
                TS.BillAddr1 as BillAddr1,
                TS.BillAddr2 as BillAddr2,
                TS.BillCity as BillCity,
                TS.BillZip as BillZip,
                TS.BillCountry as BillCountry,
                TS.ShipCounty as ShipCounty,
                TS.BillState as BillState,
    
                SO.Notes as SchedulingNotes,
                EM.WorkCenterName as WorkcenterName,
                NULL as TicketPoints, --ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketPoints,
                TPP.ArtWorkComplete as ArtWorkComplete,
                TPP.InkReceived  as InkReceived,
                TPP.ProofComplete as ProofComplete,
                TPP.PlateComplete as PlateComplete,
                TPP.ToolsReceived as ToolsReceived,
                Case when Tpp.StockReceived like '%In%' THEN 1 ELSE 0 END as StockReceived ,
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
                TD.ActFootage as ActFootage,
                TD.CoreType as CoreType,
                TD.RollUnit as RollUnit,
                TD.RollLength as RollLength,
                NULL as ColumnPerf,
                NULL as RowPerf,
                TTD.Tool1Desc as Tool1Descr,
                TTD.Tool2Desc as Tool2Descr,
                TTD.Tool3Desc as Tool3Descr,
                TTD.Tool4Desc as Tool4Descr,
                TTD.Tool5Desc as Tool5Descr,
                TSD.Stock1Desc as StockDesc1,
                TSD.Stock2Desc as StockDesc2,
                TSD.Stock3Desc as StockDesc3,
    
                CASE 
                    WHEN @IsStockAvailabilityEnabled = 1 THEN TM.StockStatus
                    ELSE NULL
                END as StockStatus,
    
                SO.Id AS OverrideId,
                TT.TicketId AS TicketId,
                TM.SourceTicketId AS Number, --TicketNumber
                TT.TaskName AS TaskName,
                SO.EquipmentName AS EquipmentName,
                SO.EquipmentId AS EquipmentId,
                SO.StartsAt AS StartsAt,
                SO.EndsAt AS EndsAt,
                TS.ShipByDateTime AS ShipByDate,
                TM.CustomerName AS Customer, --CustomerName
                TT.EstMeters AS EstLength, -- TaskEstimatedMeters
                TT.EstMeters AS TaskMeters,
                TT.WorkcenterId AS Workcenter,
                EM.FacilityId,
                CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END AS TaskMinutes
    
        INTO #manuallyScheduledTickets
        from TicketTask TT WITH (NOLOCK)
            INNER JOIN TicketMaster TM WITH (NOLOCK) ON TT.TicketId = TM.Id
            INNER JOIN TicketShipping TS WITH (NOLOCK) ON  TM.ID = TS.TicketId
            LEFT JOIN ScheduleOverride SO WITH (NOLOCK)  ON TM.Id = SO.TicketId AND SO.TaskName = TT.TaskName
            LEFT JOIN  ScheduleReport SR WITH (NOLOCK) ON TM.SourceTicketId = SR.SourceTicketId AND SR.TaskName = TT.TaskName
            LEFT JOIN Equipmentmaster EM WITH (NOLOCK) ON TT.WorkcenterId = EM.WorkcenterTypeId AND TT.OriginalEquipmentId = EM.id
            LEFT JOIN #TicketStockData TSD WITH (NOLOCK) on TM.ID = TSD.TicketId
            LEFT JOIN #TicketToolData TTD WITH (NOLOCK) on TM.ID = TTD.TicketId
            LEFT JOIN TicketDimensions TD WITH (NOLOCK) on TM.ID = TD.TicketId
            LEFT JOIN TicketPreProcess TPP WITH (NOLOCK) on TPP.TicketId = TM.Id
    
        WHERE
            ((SR.Id IS NULL  AND  TT.IsProductionReady = 0 AND SO.IsScheduled = 1) --- Not part of report / Manually scheduled
            OR (SR.Id IS NULL  AND  TT.IsProductionReady = 1 AND ( SO.IsScheduled IS NULL OR SO.IsScheduled = 1)))--- By Default production ready but not part of scheduled report
            AND tt.IsComplete = 0 -- Manually scheduled OR by default production ready
            AND TT.TicketId not in (select TicketId from #InfeasibleProdReadyTasks)
            AND (NOT EXISTS (SELECT 1 FROM @workcenters) OR TT.WorkcenterId IN (SELECT field FROM @workcenters))
            AND (NOT EXISTS (SELECT 1 FROM @facilities) OR EM.facilityid IN (SELECT field FROM @facilities))
        
        ORDER BY  TT.TicketId, TT.Sequence;


    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    

    SET @blockName = 'selecting PR tickets'; SET @startTime = GETDATE();

        ----- Production ready tickets
        select *,'tbl_ProductionReadyTickets' AS __dataset_tableName from #manuallyScheduledTickets
	    --Where ((SELECT Count(1) FROM @workcenters) = 0 OR  Workcenter in (SELECT field FROM @workcenters))
        --AND ((SELECT Count(1) FROM @facilities) = 0  OR facilityid  IN (SELECT field FROM @facilities))
 
    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


    SET @blockName = 'selecting TicketAttribute of PR tickets'; SET @startTime = GETDATE();

        ----- TicketAttributeValues projection
        Select  TAV.TicketId,TAV.Name, TAV.Value,'tbl_ticketAttributeValues' AS __dataset_tableName 
        from #manuallyScheduledTickets MST 
            inner join TicketAttributeValues TAV WITH (NOLOCK) on MST.TicketId  = TAV.TicketId
            inner join @ticketAttributeNames TA on TA.field = tav.name 
            
    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    

    DROP TABLE IF EXISTS [dbo].[#InfeasibleProdReadyTasks];
    DROP TABLE IF EXISTS [dbo].[#TicketToolData];
    DROP TABLE IF EXISTS [dbo].[#TicketStockData];
    DROP TABLE IF EXISTS [dbo].[#manuallyScheduledTickets];
 
    SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;

END