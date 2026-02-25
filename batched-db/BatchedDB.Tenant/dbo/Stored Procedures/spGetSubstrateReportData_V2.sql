CREATE PROCEDURE [dbo].[spGetSubstrateReportData_V2]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 100,
	@SortingColumn AS VARCHAR(100) = 'default',
	@startDate AS DATETIME = NULL,
	@endDate AS DATETIME = NULL,
	@sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly,
	@ticketAttributeNames AS UDT_SINGLEFIELDFILTER readonly,
	@facilities AS UDT_SINGLEFIELDFILTER readonly,
	@valuestreams AS UDT_SINGLEFIELDFILTER readonly,
	@workcenters AS UDT_SINGLEFIELDFILTER readonly,
	@equipments AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN 

		IF @endDate is null
		SET @endDate = getdate()

		select @endDate

		;with SubstrateLocations as(
		
			Select  
				TM.SourceTicketId, SI.Location
			from ScheduleReport SR 
				inner join TicketMaster TM on SR.SourceTicketId =  TM.SourceTicketId
				inner Join TicketTask TT on TM.ID = TT.TicketId and tt.TaskName = sr.TaskName
				LEFT join TicketStock TS on Tm.ID = TS.TicketId and (TS.StockType = 'Substrate' OR TS.StockType = 'Face Stock') --- sequence 2 is substrate
				LEFT JOIN StockInventory SI on  SI.StockMaterialId = TS.StockMaterialId and SI.Width = TS.Width and SI.StockUsed = 0
			where TT.Sequence = 1
			group by Tm.SourceTicketId , SI.Location
		),
		SubstrateLocationCalc as (

			select SourceTicketId , STRING_AGG(Location, ',')  as Location
			from SubstrateLocations
			Group by SourceTicketId
		)

		
		select * into #SubstrateLocationCalculation from SubstrateLocationCalc

		select SourceTicketId ,MIN(StartsAt)  as EarliestStartTime
		into #StartTimeData
		from ScheduleReport SR 
		where SourceTicketId in (select distinct SourceTicketId from #SubstrateLocationCalculation)
		group by SourceTicketId 



		select distinct Id as TicketId into #TicketsInSchedule from #SubstrateLocationCalculation SC inner join TicketMaster TM on SC.SourceTicketId = TM.SourceTicketId

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

		select em.FacilityId, evs.EquipmentId, string_agg(evs.ValueStreamId,', ') as Valuestreams
			into #equipmentValueStreams
			from EquipmentValueStream evs with (nolock)
			join EquipmentMaster em on em.ID = evs.EquipmentId
			where ((SELECT Count(1) FROM @valuestreams) = 0  OR evs.ValueStreamId in (SELECT field FROM @valuestreams))
			AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @equipments) = 0  OR em.ID in (SELECT field FROM @equipments))
			AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
			group by FacilityId,evs.EquipmentId
			
		select 
			DISTINCT
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

				EM.Name AS EquipmentName,
				SM.SourceStockId AS StockNum2,
				SC.Location AS SubstrateLocation,
				TSS.Width AS Stock2Width,
				TT.EstMeters AS TaskMeters,
				SD.EarliestStartTime as StartsAt,
				EM.FacilityName as FacilityName,
				EM.FacilityId as FacilityId,
				evsTempTable.Valuestreams as Valuestreams,
				EM.ID as EquipmentId,
				EM.WorkcenterTypeId as WorkCenterId,
				EM.WorkCenterName as WorkCenter,
				COALESCE(1 - (CAST(TD.ActualQuantity AS REAL) / NULLIF(CAST(TD.Quantity AS REAL), 0)), 0) * TM.EstTotalRevenue as WIPValue

		Into #SubstrateReportData
		from
				#SubstrateLocationCalculation SC 
				inner join ScheduleReport SR on SC.SourceTicketId = sr.SourceTicketId
				inner join TicketMaster TM on SR.SourceTicketId =  TM.SourceTicketId
				inner join TicketPreProcess TPP with (nolock) on TM.ID = TPP.TicketId
				inner join TicketDimensions TD with (nolock) on TM.ID = TD.TicketId
				inner join TicketShipping TS with (nolock) on TS.TicketId = TM.ID
				inner join TicketScore TSC with (nolock) on TSC.TicketId = TM.ID
				LEFT JOIN #StartTimeData SD on SR.SourceTicketId = SD.SourceTicketId
				LEFT join EquipmentMaster EM on SR.EquipmentId = EM.ID
				LEFT join TicketStock TSS on Tm.ID = TSS.TicketId and TSS.StockType = 'Substrate' --- sequence 2 is substrate
				LEFT join StockMaterial SM on TSS.StockMaterialId = SM.Id 
				LEFT Join TicketTask TT on TM.ID = TT.TicketId and tt.TaskName = sr.TaskName-- sequence 1 is for Press
				LEFT JOIN #ColumnPerfData CD on TM.ID = CD.TicketId
				LEFT JOIN #RowPerfData RD on TM.ID = RD.TicketId
				LEFT JOIN #TicketToolData TTD on TM.ID = TTD.TicketId
				LEFT JOIN #TicketStockData TSD on TM.ID = TSD.TicketId
				LEFT JOIN EquipmentValueStream evs ON EM.ID = evs.EquipmentId 
				LEFT JOIN #equipmentValueStreams evsTempTable ON EM.ID = evsTempTable.EquipmentId 
			    
		where TT.Sequence = 1
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.FacilityId IN (SELECT field FROM @facilities))
		AND ((SELECT Count(1) FROM @equipments) = 0  OR em.ID in (SELECT field FROM @equipments))
		AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
		AND ((SELECT Count(1) FROM @valuestreams) = 0  OR evs.ValueStreamId in (SELECT field FROM @valuestreams))
	

		--- Paginated fetch
		select	*, 
				'tbl_SubstrateReport' AS __dataset_tableName,
				COUNT(1) OVER () as TotalCount,
				Sum(TaskMeters) OVER() as TotalTaskMeters
				into #FinalResult
		from #SubstrateReportData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))




    	 Create table #TicketsInCurrentPage(
	 TicketId nvarchar(36)
	 )
	if(@SortingColumn <> 'default')

	BEGIN

		----- Sorting by a Ticket attribute value
		IF EXISTS ( select 1 from @ticketAttributeNames where Field = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1))
			Begin 
						--- Get Ticket attribute data type
						Declare @TicketAttributeType varchar(50)
						select @TicketAttributeType = DataType from TicketAttribute where name = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1)

						Select distinct Ticketid into #Tickets from #finalresult

						--- Get Ticket attribute value of the sorting column
						select TTR.TicketId,TAV.Value as Value
						into #TicketAttribute
						from 
						#Tickets TTR with (nolock)
						inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = RIGHT(@SortingColumn, LEN(@SortingColumn) - 1)
						
						--- Add the sorting attribute value in projection 
						SELECT S.* ,Ta.Value
						FROM #finalresult S
						left join #TicketAttribute TA on S.TicketId = TA.TicketId 
							ORDER BY

							---- order by attribute value
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@sortingColumn, 1) = '+'  THEN CAST( TA.Value as bit ) end,
							CASE  WHEN @TicketAttributeType = 'boolean' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as bit ) end DESC,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@SortingColumn, 1) = '+'  THEN CAST( TA.Value as real ) end,
							CASE  WHEN @TicketAttributeType = 'decimal' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as real ) end DESC,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@SortingColumn, 1) = '+'  THEN CAST( TA.Value as varchar ) end,
							CASE  WHEN @TicketAttributeType = 'string' and LEFT(@SortingColumn, 1) = '-'  THEN CAST( TA.Value as varchar ) end DESC
							OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY

			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
			END

				ELSE
		BEGIN ---- Sorting by Table fields

				 -- tbl_ScheduleReport


					SELECT *
					FROM #finalresult
					Order by 

						CASE WHEN @SortingColumn = '+backStageColorStrategy'  THEN BackStageColorStrategy END ,
						CASE WHEN @SortingColumn = '-backStageColorStrategy'  THEN BackStageColorStrategy END DESC,
						CASE WHEN @SortingColumn = '+createdOn'  THEN CreatedOn END ,
						CASE WHEN @SortingColumn = '-createdOn'  THEN CreatedOn END DESC,
						CASE WHEN @SortingColumn = '+customerName'  THEN CustomerName END ,
						CASE WHEN @SortingColumn = '-customerName'  THEN CustomerName END DESC,
						CASE WHEN @SortingColumn = '+customerPO'  THEN CustomerPO END ,
						CASE WHEN @SortingColumn = '-customerPO'  THEN CustomerPO END DESC,
						CASE WHEN @SortingColumn = '+endUserName'  THEN EndUserName END ,
						CASE WHEN @SortingColumn = '-endUserName'  THEN EndUserName END DESC,
						CASE WHEN @SortingColumn = '+endUserNum'  THEN EndUserNum END ,
						CASE WHEN @SortingColumn = '-endUserNum'  THEN EndUserNum END DESC,
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
						CASE WHEN @SortingColumn = '+tab'  THEN Tab END ,
						CASE WHEN @SortingColumn = '-tab'  THEN Tab END DESC,
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
						CASE WHEN @SortingColumn = '+plateComplete'  THEN PlateComplete END ,
						CASE WHEN @SortingColumn = '-plateComplete'  THEN PlateComplete END DESC,
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

						CASE WHEN @SortingColumn = '+equipmentName'  THEN EquipmentName END ,
						CASE WHEN @SortingColumn = '-equipmentName'  THEN EquipmentName END DESC,
						CASE WHEN @SortingColumn = '+startsAt'  THEN startsAt END ,
						CASE WHEN @SortingColumn = '-startsAt'  THEN startsAt END DESC,
						CASE WHEN @SortingColumn = '+substrateLocation'  THEN substrateLocation END ,
						CASE WHEN @SortingColumn = '-substrateLocation'  THEN substrateLocation END DESC,
						CASE WHEN @SortingColumn = '+stock2Width'  THEN stock2Width END ,
						CASE WHEN @SortingColumn = '-stock2Width'  THEN stock2Width END DESC,
						CASE WHEN @SortingColumn = '+taskMeters'  THEN taskMeters END ,
						CASE WHEN @SortingColumn = '-taskMeters'  THEN taskMeters END DESC,
						CASE WHEN @SortingColumn = '+stockNum2'  THEN stockNum2 END ,
						CASE WHEN @SortingColumn = '-stockNum2'  THEN stockNum2 END DESC,
						CASE WHEN @SortingColumn = '+wipValue'  THEN WIPValue END ,
						CASE WHEN @SortingColumn = '-wipValue'  THEN WIPValue END DESC

						OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY

			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
			
					   						
		END	
				
End


  
   ---- Default sorting
if(@SortingColumn = 'default')

BEGIN
	
			SELECT *
			FROM #finalresult
				Order by EquipmentName , StartsAt
				OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY

			
			insert into #TicketsInCurrentPage Select distinct TicketId from #finalresult
END


		SELECT min(StartsAt) as StartDate, max(StartsAt) as EndDate, 'tbl_timeWindow' AS __dataset_tableName
		FRom #SubstrateReportData
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))

		SELECT distinct TicketNumber AS TicketNumber, 'tbl_sourceTicketNumbers' AS __dataset_tableName
		FRom #SubstrateReportData
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))

				Select  TAV.TicketId,TAV.Name, TAV.Value,'tbl_ticketAttributeValues' AS __dataset_tableName 
	from #TicketsInCurrentPage S 
	inner join TicketAttributeValues TAV on  S.TicketId COLLATE DATABASE_DEFAULT = TAV.TicketId COLLATE DATABASE_DEFAULT and TAV.Name in (select field from @ticketAttributeNames) 


		-----------Facility
		SELECT distinct SRD.facilityId as FacilityId, SRD.facilityName AS FacilityName, 'tbl_facilities' AS __dataset_tableName
		FRom #SubstrateReportData SRD
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))

		
		----------- ValueStreams
		SELECT distinct VS.Id  As ValueStreamID, VS.Name AS ValueStreamName, 'tbl_valueStreams' AS __dataset_tableName
			FROM #SubstrateReportData SRD
			JOIN EquipmentValueStream EVS on SRD.equipmentId = EVS.EquipmentId
			JOIN ValueStream VS on EVS.ValueStreamId = VS.Id
			Where 
			((SELECT Count(1) FROM @sourceTicketNumbers) = 0
			OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
			AND (((@startDate IS NULL OR @startDate <= StartsAt)
			AND (@endDate IS NULL OR StartsAt <= @endDate)))
			AND ((SELECT Count(1) FROM @facilities) = 0  OR FacilityId  IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @valuestreams) = 0  OR ValueStreamID in (SELECT field FROM @valuestreams))
			AND ((SELECT Count(1) FROM @equipments) = 0  OR EVS.EquipmentId in (SELECT field FROM @equipments))
			AND ((SELECT Count(1) FROM @workcenters) = 0  OR SRD.workCenterId in (SELECT field FROM @workcenters))

		----------- WorkCenter
		SELECT distinct SRD.workCenterId as WorkCenterId, SRD.workCenter AS WorkCenterName, 'tbl_workcenters' AS __dataset_tableName
		FRom #SubstrateReportData SRD
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))

		----------- Equipments
		SELECT distinct SRD.equipmentId as EquipmentId, SRD.EquipmentName AS EquipmentName, 'tbl_equipments' AS __dataset_tableName
		FRom #SubstrateReportData SRD
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= StartsAt)
			    AND (@endDate IS NULL OR StartsAt <= @endDate)))

	
	DROP TABLE IF EXISTS #SubstrateReportData;
	DROP TABLe IF EXISTS #SubstrateLocationCalculation
	DROp Table If exists #StartTimeData

	Drop Table if exists #TicketsInCurrentPage
	DROP TABLE IF EXISTS #ColumnPerfData
	DROP TABLE IF EXISTS #RowPerfData

	DROP TABLE IF EXISTS #TicketToolData	
	DROP TABLE IF EXISTS #TicketsInSchedule
	DROP TABLe IF EXISTs #TicketStockData
END