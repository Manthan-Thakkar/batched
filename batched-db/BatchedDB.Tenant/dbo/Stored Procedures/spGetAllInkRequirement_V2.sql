CREATE PROCEDURE [dbo].[spGetAllInkRequirement_V2]
	@pageNumber AS INT = 1,
	@pageSize AS INT = 100,
	@sortBy AS VARCHAR(100) = 'default',
    @startDate AS DATETIME = NULL,
    @endDate AS DATETIME = NULL,
    @facilities AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly,
	@ticketAttributeNames AS UDT_SINGLEFIELDFILTER readonly,
	@equipments AS UDT_SINGLEFIELDFILTER readonly,
	@workcenters AS UDT_SINGLEFIELDFILTER readonly,
	@valuestreams AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN
	
	select * into #schedulereport from ScheduleReport with(nolock);

	select em.FacilityId, evs.EquipmentId, string_agg(evs.ValueStreamId,', ') as valuestreams
			into #equipmentValueStreams
			from EquipmentValueStream evs with (nolock)
			join EquipmentMaster em on em.ID = evs.EquipmentId
			where ((SELECT Count(1) FROM @valuestreams) = 0  OR evs.ValueStreamId in (SELECT field FROM @valuestreams))
			and ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
			and ((SELECT Count(1) FROM @equipments) = 0  OR em.ID IN (SELECT field FROM @equipments))
			AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId  IN (SELECT field FROM @workcenters))
			group by FacilityId,evs.EquipmentId

	select DISTINCT 
		EM.Name Press, 
		SR.TaskName Task, 
		SR.SourceTicketId Number, 
		TM.CustomerName CustomerName, 
		TII.TicketId,
		SR.StartsAt StartTime, 
		TD.EsitmatedLength EstFootage,
		SR.EquipmentId,
		EM.WorkcenterTypeId,
		EM.WorkCenterName,
		evsTempTable.valuestreams as Valuestreams
	into #TicketInfo
	from TicketItemInfo TII 
	inner join TicketMaster TM on TII.TicketId = TM.Id
	inner join TicketDimensions TD on TM.Id = TD.TicketId
	inner join #schedulereport SR on TM.SourceTicketId = SR.SourceTicketId 
	inner join TicketTask Tt on TM.Id =  TT.TicketId and SR.TaskName = TT.TaskName and TT.Sequence = 1
	inner join EquipmentMaster EM on SR.EquipmentId = EM.Id
	left join #equipmentValueStreams evsTempTable on evsTempTable.EquipmentId = EM.ID
	left join EquipmentValueStream EVS ON evsTempTable.EquipmentId = EVS.equipmentId

	WHERE 
		--CAST(SR.StartsAt as DATE) between @startDate AND @endDate
		(SR.StartsAt >= @startDate or @startDate is null) AND (SR.StartsAt <= @endDate or @endDate is null)
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
		AND ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  SR.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
		AND ((SELECT Count(1) FROM @equipments) = 0  OR em.ID  IN (SELECT field FROM @equipments))
		AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId  IN (SELECT field FROM @workcenters))
		AND ((SELECT Count(1) FROM @valuestreams) = 0  OR EVS.ValueStreamId in (SELECT field FROM @valuestreams))

		;with TempColor as (
		
		SELECT DISTINCT 
		TI.TicketId, 
		PCI.SourceColor,
		PCI.SourceInkType

			FROM ProductColorInfo PCI WITH(NOLOCK)
			INNER JOIN TicketItemInfo TI with(nolock) on PCI.ProductId = TI.ProductId
			WHERE TI.TicketId in (select distinct TicketId from #TicketInfo)
		)

	SELECT DISTINCT 
		TicketId, 
		STRING_AGG(SourceColor + ' (' + ISNULL(SourceInkType,'N/A') + ')', ', ') AS Colors
	INTO #TicketColors
	FROM TempColor
	group by TicketId

	SELECT DISTINCT 
		TI.TicketId, 
		STRING_AGG(PM.PlateId, ', ') AS PlateId
	INTO #TicketPlates
	FROM ProductMaster PM WITH(NOLOCK)
	INNER JOIN TicketItemInfo TI with(nolock) on PM.Id = TI.ProductId
	WHERE TI.TicketId in (select distinct TicketId from #TicketInfo)
	group by TI.TicketId


	select distinct TicketId into #TicketsInSchedule from #TicketInfo

		;with ColumnPERFCalc as (
		Select distinct TI.TicketId, P.ColumnPerf as ColumnPerf from TicketItemInfo TI 
		inner join #TicketsInSchedule T on TI.TicketId = T.TicketId
		left join ProductMaster P on TI.ProductId = P.Id
		)

			   
		Select TicketId, STRING_AGG(ColumnPerf,',') as ColumnPerf into #ColumnPerfData from ColumnPERFCalc
		Group by TicketId

		;with RowPERFCalc as (
		Select distinct TI.TicketId, P.RowPerf as RowPerf from TicketItemInfo TI 
		inner join #TicketsInSchedule T on TI.TicketId = T.TicketId
		left join ProductMaster P on TI.ProductId = P.Id
		)

	    Select TicketId, STRING_AGG(RowPerf,',') as RowPerf into #RowPerfData from RowPERFCalc
		Group by TicketId


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
	--- Ticket Fields 
			TM.SourceTicketId as TicketNumber,
			TM.ID as TicketId,
			TM.CustomerName as CustomerName,
			TM.GeneralDescription as GeneralDescription,
			ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketPoints,
			TS.ShipByDateTime as ShipByDate,
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
			Case when Tpp.StockReceived like '%In%' THEN 1 ELSE 0 END as StockReceived ,

			--- New fields added
			CD.ColumnPerf as ColumnPerf,
			RD.RowPerf as RowPerf,
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

			--- Ink report specific fields
			TI.Press as EquipmentName,
			TI.Task as TaskName,
			TP.PlateId as Plates,
			TC.Colors as Colors,
			TI.StartTime as StartsAt,
			TI.EquipmentId as EquipmentId,
			TI.WorkcenterTypeId as WorkCenterId,
			TI.WorkCenterName as WorkCenter,
			TI.Valuestreams as Valuestreams,
			COALESCE(1 - (CAST(TD.ActualQuantity AS REAL) / NULLIF(CAST(TD.Quantity AS REAL), 0)), 0) * TM.EstTotalRevenue as WIPValue,

			COUNT(1) OVER () as TotalCount,
			'tbl_InkRequirementReport' AS __dataset_tableName

	INTO #finalresult
	FROM #TicketInfo TI
	inner join  TicketMaster TM with (nolock) on TI.TicketId = TM.ID
	inner join TicketPreProcess TPP with (nolock) on TI.TicketId = TPP.TicketId
	inner join TicketDimensions TD with (nolock) on TI.TicketId = TD.TicketId
	inner join TicketShipping TS with (nolock) on TS.TicketId = TM.ID
	inner join TicketScore TSC with (nolock) on TSC.TicketId = TM.ID
	LEFT JOIN #TicketColors TC on TI.TicketId = TC.TicketId
	LEFT JOIN #TicketPlates TP on TI.TicketId = TP.TicketId
	LEFT JOIN #ColumnPerfData CD on TM.ID = CD.TicketId
	LEFT JOIN #RowPerfData RD on TM.ID = RD.TicketId
	LEFT JOIN #TicketToolData TTD on TM.ID = TTD.TicketId
	LEFT JOIN #TicketStockData TSD on TM.ID = TSD.TicketId



		 Create table #TicketsInCurrentPage(
	 TicketId nvarchar(36)
	 )
	if(@sortBy <> 'default')

	BEGIN

		----- Sorting by a Ticket attribute value
		IF EXISTS ( select 1 from @ticketAttributeNames where Field = RIGHT(@sortBy, LEN(@sortBy) - 1))
			Begin 
						--- Get Ticket attribute data type
						Declare @TicketAttributeType varchar(50)
						select @TicketAttributeType = DataType from TicketAttribute where name = RIGHT(@sortBy, LEN(@sortBy) - 1)

						Select distinct Ticketid into #Tickets from #finalresult

						--- Get Ticket attribute value of the sorting column
						select TTR.TicketId,TAV.Value as Value
						into #TicketAttribute
						from 
						#Tickets TTR with (nolock)
						inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = RIGHT(@sortBy, LEN(@sortBy) - 1)
						
						--- Add the sorting attribute value in projection 
					SELECT S.* ,Ta.Value
						FROM #finalresult S
						left join #TicketAttribute TA on S.TicketId = TA.TicketId 
							ORDER BY

							---- order by attribute value
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@sortBy, 1) = '+'  THEN CAST( TA.Value as bit ) end,
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@sortBy, 1) = '-'  THEN CAST( TA.Value as bit ) end DESC,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@sortBy, 1) = '+'  THEN CAST( TA.Value as real ) end,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@sortBy, 1) = '-'  THEN CAST( TA.Value as real ) end DESC,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@sortBy, 1) = '+'  THEN CAST( TA.Value as varchar ) end,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@sortBy, 1) = '-'  THEN CAST( TA.Value as varchar ) end DESC
							OFFSET (@PageNumber-1)*@pageSize ROWS
			FETCH NEXT @pageSize ROWS ONLY

	
			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
			END

				ELSE
		BEGIN ---- Sorting by Table fields

				 -- tbl_ScheduleReport


			SELECT *
					FROM #finalresult
					Order by 

						CASE WHEN @sortBy = '+backStageColorStrategy'  THEN BackStageColorStrategy END ,
						CASE WHEN @sortBy = '-backStageColorStrategy'  THEN BackStageColorStrategy END DESC,
						CASE WHEN @sortBy = '+createdOn'  THEN CreatedOn END ,
						CASE WHEN @sortBy = '-createdOn'  THEN CreatedOn END DESC,
						CASE WHEN @sortBy = '+customerName'  THEN CustomerName END ,
						CASE WHEN @sortBy = '-customerName'  THEN CustomerName END DESC,
						CASE WHEN @sortBy = '+customerPO'  THEN CustomerPO END ,
						CASE WHEN @sortBy = '-customerPO'  THEN CustomerPO END DESC,
						CASE WHEN @sortBy = '+endUserName'  THEN EndUserName END ,
						CASE WHEN @sortBy = '-endUserName'  THEN EndUserName END DESC,
						CASE WHEN @sortBy = '+endUserNum'  THEN EndUserNum END ,
						CASE WHEN @sortBy = '-endUserNum'  THEN EndUserNum END DESC,
						CASE WHEN @sortBy = '+estTotalRevenue'  THEN EstTotalRevenue END ,
						CASE WHEN @sortBy = '-estTotalRevenue'  THEN EstTotalRevenue END DESC,
						CASE WHEN @sortBy = '+finalUnwind'  THEN FinalUnwind END ,
						CASE WHEN @sortBy = '-finalUnwind'  THEN FinalUnwind END DESC,
						CASE WHEN @sortBy = '+finishType'  THEN FinishType END ,
						CASE WHEN @sortBy = '-finishType'  THEN FinishType END DESC,
						CASE WHEN @sortBy = '+generalDescription'  THEN GeneralDescription END ,
						CASE WHEN @sortBy = '-generalDescription'  THEN GeneralDescription END DESC,
						CASE WHEN @sortBy = '+isBackSidePrinted'  THEN IsBackSidePrinted END ,
						CASE WHEN @sortBy = '-isBackSidePrinted'  THEN IsBackSidePrinted END DESC,
						CASE WHEN @sortBy = '+isPrintReversed'  THEN IsPrintReversed END ,
						CASE WHEN @sortBy = '-isPrintReversed'  THEN IsPrintReversed END DESC,
						CASE WHEN @sortBy = '+isSlitOnRewind'  THEN IsSlitOnRewind END ,
						CASE WHEN @sortBy = '-isSlitOnRewind'  THEN IsSlitOnRewind END DESC,
						CASE WHEN @sortBy = '+modifiedOn'  THEN ModifiedOn END ,
						CASE WHEN @sortBy = '-modifiedOn'  THEN ModifiedOn END DESC,
						CASE WHEN @sortBy = '+orderDate'  THEN OrderDate END ,
						CASE WHEN @sortBy = '-orderDate'  THEN OrderDate END DESC,
						CASE WHEN @sortBy = '+pinfeed'  THEN Pinfeed END ,
						CASE WHEN @sortBy = '-pinfeed'  THEN Pinfeed END DESC,
						CASE WHEN @sortBy = '+priceMode'  THEN PriceMode END ,
						CASE WHEN @sortBy = '-priceMode'  THEN PriceMode END DESC,
						CASE WHEN @sortBy = '+shape'  THEN Shape END ,
						CASE WHEN @sortBy = '-shape'  THEN Shape END DESC,
						CASE WHEN @sortBy = '+shipByDate'  THEN ShipByDate END ,
						CASE WHEN @sortBy = '-shipByDate'  THEN ShipByDate END DESC,
						CASE WHEN @sortBy = '+shrinkSleeveLayFlat'  THEN ShrinkSleeveLayFlat END ,
						CASE WHEN @sortBy = '-shrinkSleeveLayFlat'  THEN ShrinkSleeveLayFlat END DESC,
						CASE WHEN @sortBy = '+sizeAround'  THEN SizeAround END ,
						CASE WHEN @sortBy = '-sizeAround'  THEN SizeAround END DESC,
						CASE WHEN @sortBy = '+sourceCustomerId'  THEN SourceCustomerId END ,
						CASE WHEN @sortBy = '-sourceCustomerId'  THEN SourceCustomerId END DESC,
						CASE WHEN @sortBy = '+tab'  THEN Tab END ,
						CASE WHEN @sortBy = '-tab'  THEN Tab END DESC,
						CASE WHEN @sortBy = '+ticketId'  THEN TicketId END ,
						CASE WHEN @sortBy = '-ticketId'  THEN TicketId END DESC,
						CASE WHEN @sortBy = '+ticketNotes'  THEN TicketNotes END ,
						CASE WHEN @sortBy = '-ticketNotes'  THEN TicketNotes END DESC,
						CASE WHEN @sortBy = '+ticketNumber'  THEN TicketNumber END ,
						CASE WHEN @sortBy = '-ticketNumber'  THEN TicketNumber END DESC,
						CASE WHEN @sortBy = '+ticketPoints'  THEN TicketPoints END ,
						CASE WHEN @sortBy = '-ticketPoints'  THEN TicketPoints END DESC,
						CASE WHEN @sortBy = '+priority'  THEN TicketPriority END ,
						CASE WHEN @sortBy = '-priority'  THEN TicketPriority END DESC,
						CASE WHEN @sortBy = '+status'  THEN TicketStatus END ,
						CASE WHEN @sortBy = '-status'  THEN TicketStatus END DESC,
						CASE WHEN @sortBy = '+stockTicketType'  THEN StockTicketType END ,
						CASE WHEN @sortBy = '-stockTicketType'  THEN StockTicketType END DESC,
						CASE WHEN @sortBy = '+ticketType'  THEN TicketType END ,
						CASE WHEN @sortBy = '-ticketType'  THEN TicketType END DESC,
						CASE WHEN @sortBy = '+useTurretRewinder'  THEN UseTurretRewinder END ,
						CASE WHEN @sortBy = '-useTurretRewinder'  THEN UseTurretRewinder END DESC,
						CASE WHEN @sortBy = '+itsName'  THEN ITSName END ,
						CASE WHEN @sortBy = '-itsName'  THEN ITSName END DESC,
						CASE WHEN @sortBy = '+otsName'  THEN OTSName END ,
						CASE WHEN @sortBy = '-otsName'  THEN OTSName END DESC,
						CASE WHEN @sortBy = '+artWorkComplete'  THEN ArtWorkComplete END ,
						CASE WHEN @sortBy = '-artWorkComplete'  THEN ArtWorkComplete END DESC,
						CASE WHEN @sortBy = '+toolsReceived'  THEN ToolsReceived END ,
						CASE WHEN @sortBy = '-toolsReceived'  THEN ToolsReceived END DESC,
						CASE WHEN @sortBy = '+inkReceived'  THEN InkReceived END ,
						CASE WHEN @sortBy = '-inkReceived'  THEN InkReceived END DESC,
						CASE WHEN @sortBy = '+stockReceived'  THEN StockReceived END ,
						CASE WHEN @sortBy = '-stockReceived'  THEN StockReceived END DESC,
						CASE WHEN @sortBy = '+plateComplete'  THEN PlateComplete END ,
						CASE WHEN @sortBy = '-plateComplete'  THEN PlateComplete END DESC,
						CASE WHEN @sortBy = '+consecutiveNumber'  THEN ConsecutiveNumber END ,
						CASE WHEN @sortBy = '-consecutiveNumber'  THEN ConsecutiveNumber END DESC,
						CASE WHEN @sortBy = '+quantity'  THEN Quantity END ,
						CASE WHEN @sortBy = '-quantity'  THEN Quantity END DESC,
						CASE WHEN @sortBy = '+actualQuantity'  THEN ActualQuantity END ,
						CASE WHEN @sortBy = '-actualQuantity'  THEN ActualQuantity END DESC,
						CASE WHEN @sortBy = '+sizeAcross'  THEN SizeAcross END ,
						CASE WHEN @sortBy = '-sizeAcross'  THEN SizeAcross END DESC,
						CASE WHEN @sortBy = '+columnSpace'  THEN ColumnSpace END ,
						CASE WHEN @sortBy = '-columnSpace'  THEN ColumnSpace END DESC,
						CASE WHEN @sortBy = '+rowSpace'  THEN RowSpace END ,
						CASE WHEN @sortBy = '-rowSpace'  THEN RowSpace END DESC,
						CASE WHEN @sortBy = '+numAcross'  THEN NumAcross END ,
						CASE WHEN @sortBy = '-numAcross'  THEN NumAcross END DESC,
						CASE WHEN @sortBy = '+numAroundPlate'  THEN NumAroundPlate END ,
						CASE WHEN @sortBy = '-numAroundPlate'  THEN NumAroundPlate END DESC,
						CASE WHEN @sortBy = '+labelRepeat'  THEN LabelRepeat END ,
						CASE WHEN @sortBy = '-labelRepeat'  THEN LabelRepeat END DESC,
						CASE WHEN @sortBy = '+finishedNumAcross'  THEN FinishedNumAcross END ,
						CASE WHEN @sortBy = '-finishedNumAcross'  THEN FinishedNumAcross END DESC,
						CASE WHEN @sortBy = '+finishedNumLabels'  THEN FinishedNumLabels END ,
						CASE WHEN @sortBy = '-finishedNumLabels'  THEN FinishedNumLabels END DESC,
						CASE WHEN @sortBy = '+coresize'  THEN Coresize END ,
						CASE WHEN @sortBy = '-coresize'  THEN Coresize END DESC,
						CASE WHEN @sortBy = '+estimatedLength'  THEN EstimatedLength END ,
						CASE WHEN @sortBy = '-estimatedLength'  THEN EstimatedLength END DESC,
						CASE WHEN @sortBy = '+overRunLength'  THEN OverRunLength END ,
						CASE WHEN @sortBy = '-overRunLength'  THEN OverRunLength END DESC,
						CASE WHEN @sortBy = '+noOfPlateChanges'  THEN NoOfPlateChanges END ,
						CASE WHEN @sortBy = '-noOfPlateChanges'  THEN NoOfPlateChanges END DESC,
						CASE WHEN @sortBy = '+shippedOnDate'  THEN ShippedOnDate END ,
						CASE WHEN @sortBy = '-shippedOnDate'  THEN ShippedOnDate END DESC,
						CASE WHEN @sortBy = '+shipVia'  THEN ShipVia END ,
						CASE WHEN @sortBy = '-shipVia'  THEN ShipVia END DESC,
						CASE WHEN @sortBy = '+dueOnsiteDate'  THEN DueOnsiteDate END ,
						CASE WHEN @sortBy = '-dueOnsiteDate'  THEN DueOnsiteDate END DESC,
						CASE WHEN @sortBy = '+shippingStatus'  THEN ShippingStatus END ,
						CASE WHEN @sortBy = '-shippingStatus'  THEN ShippingStatus END DESC,
						CASE WHEN @sortBy = '+shippingAddress'  THEN ShippingAddress END ,
						CASE WHEN @sortBy = '-shippingAddress'  THEN ShippingAddress END DESC,
						CASE WHEN @sortBy = '+shippingcity'  THEN Shippingcity END ,
						CASE WHEN @sortBy = '-shippingcity'  THEN Shippingcity END DESC,

						CASE WHEN @sortBy = '+equipmentName'  THEN EquipmentName END ,
						CASE WHEN @sortBy = '-equipmentName'  THEN EquipmentName END DESC,
						CASE WHEN @sortBy = '+taskName'  THEN TaskName END ,
						CASE WHEN @sortBy = '-taskName'  THEN TaskName END DESC,
						CASE WHEN @sortBy = '+plates'  THEN Plates END ,
						CASE WHEN @sortBy = '-plates'  THEN Plates END DESC,
						CASE WHEN @sortBy = '+colors'  THEN Colors END ,
						CASE WHEN @sortBy = '-colors'  THEN Colors END DESC,
						CASE WHEN @sortBy = '+startsAt'  THEN StartsAt END ,
						CASE WHEN @sortBy = '-startsAt'  THEN StartsAt END DESC,

						CASE WHEN @sortBy = '+columnPerf'  THEN ColumnPerf END ,
						CASE WHEN @sortBy = '-columnPerf'  THEN ColumnPerf END DESC,
						CASE WHEN @sortBy = '+rowPerf'  THEN rowPerf END ,
						CASE WHEN @sortBy = '-rowPerf'  THEN rowPerf END DESC,
						CASE WHEN @sortBy = '+iTSAssocNum'  THEN iTSAssocNum END ,
						CASE WHEN @sortBy = '-iTSAssocNum'  THEN iTSAssocNum END DESC,
						CASE WHEN @sortBy = '+oTSAssocNum'  THEN oTSAssocNum END ,
						CASE WHEN @sortBy = '-oTSAssocNum'  THEN oTSAssocNum END DESC,
						CASE WHEN @sortBy = '+shippingInstruc'  THEN shippingInstruc END ,
						CASE WHEN @sortBy = '-shippingInstruc'  THEN shippingInstruc END DESC,
						CASE WHEN @sortBy = '+dateDone'  THEN dateDone END ,
						CASE WHEN @sortBy = '-dateDone'  THEN dateDone END DESC,
						CASE WHEN @sortBy = '+shipAttnEmailAddress'  THEN shipAttnEmailAddress END ,
						CASE WHEN @sortBy = '-shipAttnEmailAddress'  THEN shipAttnEmailAddress END DESC,
						CASE WHEN @sortBy = '+shipLocation'  THEN shipLocation END ,
						CASE WHEN @sortBy = '-shipLocation'  THEN shipLocation END DESC,
						CASE WHEN @sortBy = '+shipZip'  THEN shipZip END ,
						CASE WHEN @sortBy = '-shipZip'  THEN shipZip	 END DESC,
						CASE WHEN @sortBy = '+billAddr1'  THEN billAddr1 END ,
						CASE WHEN @sortBy = '-billAddr1'  THEN billAddr1 END DESC,
						CASE WHEN @sortBy = '+billAddr2'  THEN billAddr2 END ,
						CASE WHEN @sortBy = '-billAddr2'  THEN billAddr2 END DESC,
						CASE WHEN @sortBy = '+billCity'  THEN billCity END ,
						CASE WHEN @sortBy = '-billCity'  THEN billCity END DESC,
						CASE WHEN @sortBy = '+billZip'  THEN billZip END ,
						CASE WHEN @sortBy = '-billZip'  THEN billZip END DESC,
						CASE WHEN @sortBy = '+billCountry'  THEN billCountry END ,
						CASE WHEN @sortBy = '-billCountry'  THEN billCountry END DESC,
						CASE WHEN @sortBy = '+isStockAllocated'  THEN isStockAllocated END ,
						CASE WHEN @sortBy = '-isStockAllocated'  THEN isStockAllocated END DESC,
						CASE WHEN @sortBy = '+endUserPO'  THEN endUserPO END ,
						CASE WHEN @sortBy = '-endUserPO'  THEN endUserPO END DESC,
						CASE WHEN @sortBy = '+tool1Descr'  THEN tool1Descr END ,
						CASE WHEN @sortBy = '-tool1Descr'  THEN tool1Descr END DESC,
						CASE WHEN @sortBy = '+tool2Descr'  THEN tool2Descr END ,
						CASE WHEN @sortBy = '-tool2Descr'  THEN tool2Descr END DESC,
						CASE WHEN @sortBy = '+tool3Descr'  THEN tool3Descr END ,
						CASE WHEN @sortBy = '-tool3Descr'  THEN tool3Descr END DESC,
						CASE WHEN @sortBy = '+tool4Descr'  THEN tool4Descr END ,
						CASE WHEN @sortBy = '-tool4Descr'  THEN tool4Descr END DESC,
						CASE WHEN @sortBy = '+tool5Descr'  THEN tool5Descr END ,
						CASE WHEN @sortBy = '-tool5Descr'  THEN tool5Descr END DESC,
						CASE WHEN @sortBy = '+actFootage'  THEN actFootage END ,
						CASE WHEN @sortBy = '-actFootage'  THEN actFootage END DESC,
						CASE WHEN @sortBy = '+estPackHrs'  THEN estPackHrs END ,
						CASE WHEN @sortBy = '-estPackHrs'  THEN estPackHrs END DESC,
						CASE WHEN @sortBy = '+actPackHrs'  THEN actPackHrs END ,
						CASE WHEN @sortBy = '-actPackHrs'  THEN actPackHrs END DESC,
						CASE WHEN @sortBy = '+inkStatus'  THEN inkStatus END ,
						CASE WHEN @sortBy = '-inkStatus'  THEN inkStatus END DESC,
						CASE WHEN @sortBy = '+billState'  THEN billState END ,
						CASE WHEN @sortBy = '-billState'  THEN billState END DESC,
						CASE WHEN @sortBy = '+custContact'  THEN custContact END ,
						CASE WHEN @sortBy = '-custContact'  THEN custContact END DESC,
						CASE WHEN @sortBy = '+coreType'  THEN coreType END ,
						CASE WHEN @sortBy = '-coreType'  THEN coreType END DESC,
						CASE WHEN @sortBy = '+rollLength'  THEN rollLength END ,
						CASE WHEN @sortBy = '-rollLength'  THEN rollLength END DESC,
						CASE WHEN @sortBy = '+rollUnit'  THEN rollUnit END ,
						CASE WHEN @sortBy = '-rollUnit'  THEN rollUnit END DESC,
						CASE WHEN @sortBy = '+finishNotes'  THEN finishNotes END ,
						CASE WHEN @sortBy = '-finishNotes'  THEN finishNotes END DESC,
						CASE WHEN @sortBy = '+shipCounty'  THEN shipCounty END ,
						CASE WHEN @sortBy = '-shipCounty'  THEN shipCounty END DESC,
						CASE WHEN @sortBy = '+stockNotes'  THEN stockNotes END ,
						CASE WHEN @sortBy = '-stockNotes'  THEN stockNotes END DESC,
						CASE WHEN @sortBy = '+creditHoldOverride'  THEN creditHoldOverride END ,
						CASE WHEN @sortBy = '-creditHoldOverride'  THEN creditHoldOverride END DESC,
						CASE WHEN @sortBy = '+shrinkSleeveOverLap'  THEN shrinkSleeveOverLap END ,
						CASE WHEN @sortBy = '-shrinkSleeveOverLap'  THEN shrinkSleeveOverLap END DESC,
						CASE WHEN @sortBy = '+shrinkSleeveCutHeight'  THEN shrinkSleeveCutHeight END ,
						CASE WHEN @sortBy = '-shrinkSleeveCutHeight'  THEN shrinkSleeveCutHeight END DESC,
						CASE WHEN @sortBy = '+stockDesc1'  THEN stockDesc1 END ,
						CASE WHEN @sortBy = '-stockDesc1'  THEN stockDesc1 END DESC,
						CASE WHEN @sortBy = '+stockDesc2'  THEN stockDesc2 END ,
						CASE WHEN @sortBy = '-stockDesc2'  THEN stockDesc2 END DESC,
						CASE WHEN @sortBy = '+stockDesc3'  THEN stockDesc3 END ,
						CASE WHEN @sortBy = '-stockDesc3'  THEN stockDesc3 END DESC,
						CASE WHEN @sortBy = '+wipValue'  THEN WIPValue END ,
						CASE WHEN @sortBy = '-wipValue'  THEN WIPValue END DESC

						OFFSET (@PageNumber-1)*@pageSize ROWS
			FETCH NEXT @pageSize ROWS ONLY
	
		
			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
			
					   						
		END	
				
End


  
   ---- Default sorting
if(@sortBy = 'default')

BEGIN

			SELECT *
			FROM #finalresult
				Order by EquipmentName , StartsAt
				OFFSET (@PageNumber-1)*@pageSize ROWS
			FETCH NEXT @pageSize ROWS ONLY

	
			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
END


	

	SELECT distinct(TicketNumber) as TicketNumber , 'tbl_ticketNumbers' AS __dataset_tableName
	from #finalresult s 
	inner join EquipmentMaster em WITH(NOLOCK) ON em.id = s.equipmentid
	WHERE ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))

	--select @startDate as StartDate, @endDate as EndDate , 'tbl_timeWindow' AS __dataset_tableName;

	SELECT min(StartsAt) as StartDate, max(StartsAt) as EndDate, 'tbl_timeWindow' AS __dataset_tableName
	from #finalresult 

	Select distinct(FacilityId) As FacilityId , 'tbl_facilities' AS __dataset_tableName  
	from #finalresult s 
	inner join EquipmentMaster em WITH(NOLOCK) ON em.id = s.equipmentid

	-----------Equipments
	Select distinct FR.EquipmentId As EquipmentId, FR.EquipmentName as EquipmentName , 'tbl_equipments' AS __dataset_tableName  
	from #finalresult FR
	
	-----------WorkCenters
	Select distinct FR.WorkCenterId as WorkCenterId, FR.WorkCenter AS WorkCenterName, 'tbl_workcenters' AS __dataset_tableName  
	from #finalresult FR

	-----------ValueStreams
	Select DISTINCT vs.Id  As ValueStreamID, vs.Name AS ValueStreamName, 'tbl_valueStreams' AS __dataset_tableName  
	from #finalresult FR 
	inner join EquipmentMaster em ON em.id = FR.EquipmentId
	inner join EquipmentValueStream evs ON evs.EquipmentId = em.ID
	join ValueStream vs ON vs.Id = evs.ValueStreamId
	where em.IsEnabled = 1 and em.AvailableForPlanning = 1 and em.AvailableForScheduling = 1
		AND ((SELECT Count(1) FROM @facilities) = 0  OR FacilityId  IN (SELECT field FROM @facilities))
        AND ((SELECT Count(1) FROM @valuestreams) = 0  OR ValueStreamID in (SELECT field FROM @valuestreams))
		AND ((SELECT Count(1) FROM @equipments) = 0  OR em.ID in (SELECT field FROM @equipments))
		AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))

	
	SELECT ISNULL(SUM(EstimatedLength),0) TotalCount, 'tbl_EstFootageSum' AS __dataset_tableName FROM #finalresult;

	SELECT MAX(CreatedOn) LastSchedulingDate, 'tbl_LastSchedulingDate' AS __dataset_tableName FROM #schedulereport;


	
		Select  TAV.TicketId,TAV.Name, TAV.Value,'tbl_ticketAttributeValues' AS __dataset_tableName 
	from #TicketsInCurrentPage S 
	inner join TicketAttributeValues TAV on  S.TicketId COLLATE DATABASE_DEFAULT = TAV.TicketId COLLATE DATABASE_DEFAULT and TAV.Name in (select field from @ticketAttributeNames) 



	drop table if exists #schedulereport;
	drop table if exists #finalresult;
	drop table if exists #TicketPlates;
	drop table if exists #TicketColors;
	drop table if exists #TicketInfo;

	Drop Table if exists #TicketsInCurrentPage

	DROP TABLE IF EXISTS #ColumnPerfData
	DROP TABLE IF EXISTS #RowPerfData

	DROP TABLE IF EXISTS #TicketToolData	
	DROP TABLE IF EXISTS #TicketsInSchedule
	DROP TABLe IF EXISTs #TicketStockData

END