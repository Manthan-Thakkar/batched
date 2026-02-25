CREATE  PROCEDURE [dbo].[spGetAllInkRequirement]
	@pageNumber AS INT = 1,
	@pageSize AS INT = 100,
	@sortBy AS VARCHAR(100) = 'default',
    @startDate AS DATE = NULL,
    @endDate AS DATE = NULL,
    @facilities AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN
	
	select * into #schedulereport from ScheduleReport with(nolock);


	select DISTINCT 
		EM.Name Press, 
		SR.TaskName Task, 
		SR.SourceTicketId Number, 
		TM.CustomerName CustomerName, 
		TII.TicketId,
		SR.StartsAt StartTime, 
		TD.EsitmatedLength EstFootage,
		SR.EquipmentId
	into #TicketInfo
	from TicketItemInfo TII 
	inner join TicketMaster TM on TII.TicketId = TM.Id
	inner join TicketDimensions TD on TM.Id = TD.TicketId
	inner join #schedulereport SR on TM.SourceTicketId = SR.SourceTicketId 
	inner join TicketTask Tt on TM.Id =  TT.TicketId and SR.TaskName = TT.TaskName and TT.Sequence = 1
	inner join EquipmentMaster EM on SR.EquipmentId = EM.Id
	WHERE 
		--CAST(SR.StartsAt as DATE) between @startDate AND @endDate
		(SR.StartsAt >= @startDate or @startDate is null) AND (SR.StartsAt <= @endDate or @endDate is null)
		AND ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
		AND ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  SR.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))


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

	SELECT TI.*, TC.Colors, TP.PlateId 
	INTO #finalresult
	FROM #TicketInfo TI
	LEFT JOIN #TicketColors TC on TI.TicketId = TC.TicketId
	LEFT JOIN #TicketPlates TP on TI.TicketId = TP.TicketId

	select *, COUNT(1) OVER () as TotalCount, 'tbl_InkRequirementReport' AS __dataset_tableName  from #finalresult
	order by 
		CASE WHEN @sortBy = '+press'  THEN Press END ,
		CASE WHEN @sortBy = '-press'  THEN Press END DESC,
		CASE WHEN @sortBy = '+task'  THEN Task END ,
		CASE WHEN @sortBy = '-task'  THEN Task END DESC,
		CASE WHEN @sortBy = '+number'  THEN Number END ,
		CASE WHEN @sortBy = '-number'  THEN Number END DESC,
		CASE WHEN @sortBy = '+customer'  THEN CustomerName END ,
		CASE WHEN @sortBy = '-customer'  THEN CustomerName END DESC,
		CASE WHEN @sortBy = '+startTime'  THEN StartTime END ,
		CASE WHEN @sortBy = '-startTime'  THEN StartTime END DESC,
		CASE WHEN @sortBy = '+estfootage'  THEN EstFootage END ,
		CASE WHEN @sortBy = '-estfootage'  THEN EstFootage END DESC,
		CASE WHEN @sortBy = '+plates'  THEN PlateId END ,
		CASE WHEN @sortBy = '-plates'  THEN PlateId END DESC,
		CASE WHEN @sortBy = '+colors'  THEN Colors END ,
		CASE WHEN @sortBy = '-colors'  THEN Colors END DESC,
		CASE WHEN @sortBy = 'default'  THEN Press END,
		CASE WHEN @sortBy = 'default'  THEN StartTime END
	OFFSET (@pageNumber-1)*@pageSize ROWS
	FETCH NEXT @pageSize ROWS ONLY
	

	SELECT distinct(Number) as TicketNumber , 'tbl_ticketNumbers' AS __dataset_tableName
	from #finalresult s 
	inner join EquipmentMaster em WITH(NOLOCK) ON em.id = s.equipmentid
	WHERE ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))

	--select @startDate as StartDate, @endDate as EndDate , 'tbl_timeWindow' AS __dataset_tableName;

	SELECT min(StartTime) as StartDate, max(StartTime) as EndDate, 'tbl_timeWindow' AS __dataset_tableName
	from #finalresult 

	Select distinct(FacilityId) As FacilityId , 'tbl_facilities' AS __dataset_tableName  
	from #finalresult s 
	inner join EquipmentMaster em WITH(NOLOCK) ON em.id = s.equipmentid
	
	SELECT ISNULL(SUM(EstFootage),0) TotalCount, 'tbl_EstFootageSum' AS __dataset_tableName FROM #finalresult;

	SELECT MAX(CreatedOn) LastSchedulingDate, 'tbl_LastSchedulingDate' AS __dataset_tableName FROM #schedulereport;


	drop table if exists #schedulereport;
	drop table if exists #finalresult;
	drop table if exists #TicketPlates;
	drop table if exists #TicketColors;
	drop table if exists #TicketInfo;

END