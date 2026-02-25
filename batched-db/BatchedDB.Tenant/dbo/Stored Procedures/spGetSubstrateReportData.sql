CREATE PROCEDURE [dbo].[spGetSubstrateReportData]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 100,
	@SortingColumn AS VARCHAR(100) = 'default',
	@startDate AS DATETIME = NULL,
	@endDate AS DATETIME = NULL,
	@sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly
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
				LEFT join TicketStock TS on Tm.ID = TS.TicketId and TS.StockType = 'Substrate' --- sequence 2 is substrate
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
			

		select 
				SR.SourceTicketId as TicketNumber,
				EM.Name AS EquipmentName,
				SM.SourceStockId AS Substrate,
				SC.Location AS Location,
				TS.Width AS StockWidth,
				TT.EstMeters AS TotalRemainingMeters,
				SD.EarliestStartTime as EarliestTaskTime
		Into #SubstrateReportData
		from
				#SubstrateLocationCalculation SC 
				inner join ScheduleReport SR on SC.SourceTicketId = sr.SourceTicketId
				inner join TicketMaster TM on SR.SourceTicketId =  TM.SourceTicketId
				LEFT JOIN #StartTimeData SD on SR.SourceTicketId = SD.SourceTicketId
				LEFT join EquipmentMaster EM on SR.EquipmentId = EM.ID
				LEFT join TicketStock TS on Tm.ID = TS.TicketId and TS.StockType = 'Substrate' --- sequence 2 is substrate
				LEFT join StockMaterial SM on TS.StockMaterialId = SM.Id 
				inner Join TicketTask TT on TM.ID = TT.TicketId and tt.TaskName = sr.TaskName
		where TT.Sequence = 1
	

		--- Paginated fetch
		select	*, 
				'tbl_SubstrateReport' AS __dataset_tableName,
				COUNT(1) OVER () as TotalCount,
				Sum(TotalRemainingMeters) OVER() as TotalTaskMeters
		from #SubstrateReportData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= EarliestTaskTime)
			    AND (@endDate IS NULL OR EarliestTaskTime <= @endDate)))
		Order by

			CASE WHEN @SortingColumn = '+equipment'  THEN EquipmentName END ,
			CASE WHEN @SortingColumn = '-equipment'  THEN EquipmentName END DESC,
			CASE WHEN @SortingColumn = '+startTime'  THEN EarliestTaskTime END ,
			CASE WHEN @SortingColumn = '-startTime'  THEN EarliestTaskTime END DESC,
			CASE WHEN @SortingColumn = '+substrate'  THEN Substrate END ,
			CASE WHEN @SortingColumn = '-substrate'  THEN Substrate END DESC,
			CASE WHEN @SortingColumn = '+stockwidth'  THEN StockWidth END ,
			CASE WHEN @SortingColumn = '-stockwidth'  THEN StockWidth END DESC,
			CASE WHEN @SortingColumn = '+taskMeters'  THEN TotalRemainingMeters END ,
			CASE WHEN @SortingColumn = '-taskMeters'  THEN TotalRemainingMeters END DESC,
			CASE WHEN @SortingColumn = '+location'  THEN [Location] END ,
			CASE WHEN @SortingColumn = '-location'  THEN [Location] END DESC,
			CASE WHEN @SortingColumn = 'default'  THEN EquipmentName END ,
			CASE WHEN @SortingColumn = 'default'  THEN EarliestTaskTime END

		OFFSET (@PageNumber-1)*@RowsOfPage ROWS
		FETCH NEXT @RowsOfPage ROWS ONLY


		SELECT min(EarliestTaskTime) as StartDate, max(EarliestTaskTime) as EndDate, 'tbl_timeWindow' AS __dataset_tableName
		FRom #SubstrateReportData
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= EarliestTaskTime)
			    AND (@endDate IS NULL OR EarliestTaskTime <= @endDate)))

		SELECT distinct TicketNumber AS TicketNumber, 'tbl_sourceTicketNumbers' AS __dataset_tableName
		FRom #SubstrateReportData
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
				AND (((@startDate IS NULL OR @startDate <= EarliestTaskTime)
			    AND (@endDate IS NULL OR EarliestTaskTime <= @endDate)))


	DROP TABLE IF EXISTS #SubstrateReportData;
	DROP TABLe IF EXISTS #SubstrateLocationCalculation
	DROp Table If exists #StartTimeData
END