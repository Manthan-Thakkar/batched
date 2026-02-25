CREATE PROCEDURE [dbo].[spGetShipingScheduleData]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 100,
	@SortingColumn AS VARCHAR(100) = 'default',
	@startDate AS DATETIME = NULL,
	@endDate AS DATETIME = NULL,
	@customers AS [UDT_SINGLEFIELDFILTER] readonly,
	@sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN 

		IF @endDate is null
		SET @endDate = getdate()

		select @endDate

		--- Remaining task calculation
		;with remainingTasks as (
					select 
							Tm.ID as TicketId ,
							IIF(count(TT.Id) > 0 ,1,0) AS IsTaskPending
					from TicketMaster TM 
						 Left join TicketTask TT on TM.ID = TT.TicketId and TT.IsComplete = 0
						 INNER JOIN TicketShipping TS on TM.ID = TS.TicketId
				Where  TS.ShipByDateTime IS NOT NULL  
					   AND (TS.ShipByDateTime>=DATEADD(d, -30, GETDATE()) 
					   AND (TM.IsOpen = 1 Or TM.IsOnHold =1)) 
					   AND TM.SourceTicketType in (0, 1, 3)
						
					Group by TM.ID 
		),

		-- Latest task times calculation
		LatestTaskTimes as (
					select RT.*, 
						Case 
							When TM.SourceStatus = 'Done' Then Ts.ShippedOnDate
							Else (MAX(SR.EndsAt)) 
						End AS LatestTaskTime
					from remainingTasks RT 
						 inner join TicketMaster TM on RT.TicketId = TM.ID
						 inner join TicketShipping Ts on TM.ID = TS.TicketId
						 LEFT JOIN ScheduleReport SR on Tm.SourceTicketId = SR.SourceTicketId
					group by RT.TicketId, RT.IsTaskPending, TM.SourceStatus,TS.ShippedOnDate
		)

		--- All Data
		select RT.* ,
				   Case 
				        When Tm.SourceStatus='Done' Then TS.ShippedOnDate
		                When TM.SourceTicketType=0 Then 
		                     (Case When Tm.SourceStatus = 'Done' Then TS.ShipByDateTime
		                          When TS.ShipByDateTime < GETDATE() OR TS.ShipByDateTime IS NULL Then CAST(GETDATE() as Date)
		                          Else TS.ShipByDateTime
		                       End) -- Updated due date
		                When RT.LatestTaskTime IS NULL and RT.IsTaskPending > 0 Then NULL
		                When RT.LatestTaskTime IS NULL Then cast(getdate() as Date)
		                Else cast(LatestTaskTime as Date)
		           End as EstimatedCompletionDate,
				   TM.SourceTicketId AS TicketNumber,
		           TM.SourceStatus AS TicketStatus,
		           Tm.SourceTicketType AS TicketType,
		           Tm.CustomerName as CustomerName,
		           TS.ShipByDateTime as ShipTime,
		           TM.SourceFinishType as FinishType,
		           TS.SourceShipVia as ShipVia,
		           TS.ShippingAddress as ShipAddress,
		           TS.SourceShipAddressId as AddressId,
		           TS.ShippingCity as ShipCity,
		           Ts.ShippingStatus as ShippingStatus,
		           TM.EndUserName as EndUserName,
				   COALESCE(1-( cast( TD.ActualQuantity as real) / NULLIF(cast (TD.Quantity as real) ,0)), 0) * TM.EstTotalRevenue as WIPValue
				   
		into #CompletionDates
		from LatestTaskTimes RT 
			 inner join TicketMaster TM on RT.TicketId = TM.ID
			 inner join TicketShipping Ts on TM.ID = TS.TicketId
			 inner join TicketDimensions TD on TD.TicketId = TM.ID

		-- SimilarShippingTickets calculation
		SELECT 
				   Distinct CD.TicketId, 
				   STRING_AGG(CD1.TicketNumber, ',') AS SimilarShippingTickets
		into #TicketConcat
		FROM #CompletionDates CD WITH(NOLOCK)
			 LEFT JOIN #CompletionDates CD1 with(nolock) 
			 on CD.ShipVia = CD1.ShipVia 
			 and CD1.TicketNumber <> CD.TicketNumber 
			 and CD.EstimatedCompletionDate = CD1.EstimatedCompletionDate 
			 and CD.AddressId = CD1.AddressId
	
		group by CD.TicketId
		
		---- Paginated select
		select 
				  CD.*,
				  TC.SimilarShippingTickets ,
				  'tbl_ScheduleReport' AS __dataset_tableName,
				  COUNT(1) OVER () as TotalCount,
				  Sum(CD.WIPValue ) over() as TotalWIPValue
		from #CompletionDates CD
			 left join #TicketConcat TC on CD.TicketId = TC.TicketId
		Where (((@startDate IS NULL OR @startDate <= CD.EstimatedCompletionDate)
		      AND (@endDate IS NULL OR CD.EstimatedCompletionDate <= @endDate))
			   OR CD.EstimatedCompletionDate is NULL)
			  AND  ((SELECT Count(1) FROM @customers) = 0 OR CustomerName IN (SELECT field FROM @customers))
			  AND  ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))
		Order by 
		
		
		CASE WHEN @SortingColumn = '+number'  THEN CD.TicketNumber END ,
		CASE WHEN @SortingColumn = '-number'  THEN CD.TicketNumber END desc,
		CASE WHEN @SortingColumn = '+status'  THEN CD.TicketStatus END ,
		CASE WHEN @SortingColumn = '-status'  THEN CD.TicketStatus END desc,
		CASE WHEN @SortingColumn = '+ticketType'  THEN CD.TicketType END ,
		CASE WHEN @SortingColumn = '-ticketType'  THEN CD.TicketType END desc,
		CASE WHEN @SortingColumn = '+customer'  THEN CD.CustomerName END ,
		CASE WHEN @SortingColumn = '-customer'  THEN CD.CustomerName END desc,
		CASE WHEN @SortingColumn = '+shiptime'  THEN CD.ShipTime END ,
		CASE WHEN @SortingColumn = '-shiptime'  THEN CD.ShipTime END desc,
		CASE WHEN @SortingColumn = '+finishType'  THEN CD.FinishType END ,
		CASE WHEN @SortingColumn = '-finishType'  THEN CD.FinishType END desc,
		CASE WHEN @SortingColumn = '+shipVia'  THEN CD.ShipVia END ,
		CASE WHEN @SortingColumn = '-shipVia'  THEN CD.ShipVia END desc,
		CASE WHEN @SortingColumn = '+shipAddress'  THEN CD.ShipAddress END ,
		CASE WHEN @SortingColumn = '-shipAddress'  THEN CD.ShipAddress END desc,
		CASE WHEN @SortingColumn = '+shipCity'  THEN CD.ShipCity END ,
		CASE WHEN @SortingColumn = '-shipCity'  THEN CD.ShipCity END desc,
		CASE WHEN @SortingColumn = '+latestTaskTime'  THEN CD.LatestTaskTime END ,
		CASE WHEN @SortingColumn = '-latestTaskTime'  THEN CD.LatestTaskTime END desc,
		CASE WHEN @SortingColumn = '+estimatedCompletionDate'  THEN CD.EstimatedCompletionDate END ,
		CASE WHEN @SortingColumn = '-estimatedCompletionDate'  THEN CD.EstimatedCompletionDate END desc,
		CASE WHEN @SortingColumn = '+endUserName'  THEN CD.EndUserName END ,
		CASE WHEN @SortingColumn = '-endUserName'  THEN CD.EndUserName END desc,
		CASE WHEN @SortingColumn = '+wipValue'  THEN CD.WIPValue END ,
		CASE WHEN @SortingColumn = '-wipValue'  THEN CD.WIPValue END desc,

		CASE WHEN @SortingColumn = 'default'  THEN EstimatedCompletionDate END desc,
		CASE WHEN @SortingColumn = 'default'  THEN CD.ShipAddress END,
		CASE WHEN @SortingColumn = 'default'  THEN  CD.ShipVia END
		
	
			OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY


	-- Start and end date
	SELECT min(EstimatedCompletionDate) as StartDate, max(EstimatedCompletionDate) as EndDate, 'tbl_timeWindow' AS __dataset_tableName FROM #CompletionDates
	Where (((@startDate IS NULL OR @startDate <= EstimatedCompletionDate)
		      AND (@endDate IS NULL OR EstimatedCompletionDate <= @endDate))
			   OR EstimatedCompletionDate is NULL)
			  AND  ((SELECT Count(1) FROM @customers) = 0 OR CustomerName IN (SELECT field FROM @customers))
			  AND  ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))

	-- customers in current filter
	SELECT distinct CustomerName AS CustomerName, 'tbl_customers' AS __dataset_tableName FROM #CompletionDates
	Where (((@startDate IS NULL OR @startDate <= EstimatedCompletionDate)
		      AND (@endDate IS NULL OR EstimatedCompletionDate <= @endDate))
			   OR EstimatedCompletionDate is NULL)
			  AND  ((SELECT Count(1) FROM @customers) = 0 OR CustomerName IN (SELECT field FROM @customers))
			  AND  ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))

	-- tickets in current filter
	SELECT distinct TicketNumber AS TicketNumber, 'tbl_sourceTicketNumbers' AS __dataset_tableName FROM #CompletionDates
	Where (((@startDate IS NULL OR @startDate <= EstimatedCompletionDate)
		      AND (@endDate IS NULL OR EstimatedCompletionDate <= @endDate))
			   OR EstimatedCompletionDate is NULL)
			  AND  ((SELECT Count(1) FROM @customers) = 0 OR CustomerName IN (SELECT field FROM @customers))
			  AND  ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR TicketNumber IN (SELECT field FROM @sourceTicketNumbers))

 
	DROP TABLE IF EXISTS #CompletionDates;
	DROP TABLE IF EXISTS #TicketConcat;
END
