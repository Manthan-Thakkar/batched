CREATE PROCEDURE [dbo].[spGetCoreRequirementReportData]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 100,
	@SortingColumn AS VARCHAR(100) = 'default',
	@startDate AS DATETIME = NULL,
	@endDate AS DATETIME = NULL,
	@sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly,
    @equipments AS [UDT_SINGLEFIELDFILTER] readonly
AS
BEGIN 

		IF @endDate is null
		SET @endDate = getdate()

		--- Remaining task calculation
		;with lastTasks as (
	 
			select SourceTicketId,MAX(StartsAt) as StartDateTime from ScheduleReport
          group by SourceTicketId
		)
		, LastTaskSchedule as (
				select SR.*
				from ScheduleReport SR  
				inner JOIN lastTasks LT on SR.SourceTicketId = LT.SourceTicketId and LT.StartDateTime = SR.StartsAt
		)
		
		select * into #LastTaskSchedule from LastTaskSchedule

		select SourceTicketId ,MIN(StartsAt)  as EarliestStartTime
		into #StartTimeData
		from ScheduleReport SR 
		where SourceTicketId in (select distinct SourceTicketId from #LastTaskSchedule)
		group by SourceTicketId 


		select 
				EM.ID AS EquipmentId,
				EM.Name AS Machine,
				LD.SourceTicketId AS Number,
				SD.EarliestStartTime as StartTime,
				TD.Quantity AS Quantity,
				TD.CoreSize as CoreSize,
				TD.CalcCoreWidth as CoreWidth,
				TD.CalcNumLeftoverRolls as RemainingCores
		INTO #LastTaskData
		from #LastTaskSchedule LD 
		INNER join TicketMaster Tm on LD.SourceTicketId = TM.SourceTicketId
		LEFT JOIN #StartTimeData SD on LD.SourceTicketId = SD.SourceTicketId
		LEFT join TicketDimensions TD on Td.TicketId = TM.ID
		LEFT join EquipmentMaster EM on LD.EquipmentId = EM.ID
		
		
	    select	*, 
				'tbl_CoreRequirementReport' AS __dataset_tableName,
				COUNT(1) OVER () as TotalCount ,
				SUM(Quantity) OVER () as TotalQuantity,
				SUM(RemainingCores) OVER () as TotalCores
		from #LastTaskData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR Number IN (SELECT field FROM @sourceTicketNumbers))
				 AND  ((SELECT Count(1) FROM @equipments) = 0 OR  equipmentid IN (SELECT field FROM @equipments))
				AND (((@startDate IS NULL OR @startDate <= StartTime)
			    AND (@endDate IS NULL OR StartTime <= @endDate)))
			Order by 

			CASE WHEN @SortingColumn = '+equipment'  THEN Machine END ,
			CASE WHEN @SortingColumn = '-equipment'  THEN Machine END DESC,
			CASE WHEN @SortingColumn = '+number'  THEN Number END ,
			CASE WHEN @SortingColumn = '-number'  THEN Number END DESC,
			CASE WHEN @SortingColumn = '+startTime'  THEN StartTime END ,
			CASE WHEN @SortingColumn = '-startTime'  THEN StartTime END DESC,
			CASE WHEN @SortingColumn = '+quantity'  THEN Quantity END ,
			CASE WHEN @SortingColumn = '-quantity'  THEN Quantity END DESC,
			CASE WHEN @SortingColumn = '+coreSize'  THEN CoreSize END ,
			CASE WHEN @SortingColumn = '-coreSize'  THEN CoreSize END DESC,
			CASE WHEN @SortingColumn = '+coreWidth'  THEN CoreWidth END ,
			CASE WHEN @SortingColumn = '-coreWidth'  THEN CoreWidth END DESC,
			CASE WHEN @SortingColumn = '+remainingCores'  THEN RemainingCores END ,
			CASE WHEN @SortingColumn = '-remainingCores'  THEN RemainingCores END DESC,
			CASE WHEN @SortingColumn = 'default'  THEN Machine END,
			CASE WHEN @SortingColumn = 'default'  THEN StartTime END

		OFFSET (@PageNumber-1)*@RowsOfPage ROWS
		FETCH NEXT @RowsOfPage ROWS ONLY

		SELECT min(StartTime) as StartDate, max(StartTime) as EndDate, 'tbl_timeWindow' AS __dataset_tableName
		from #LastTaskData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR Number IN (SELECT field FROM @sourceTicketNumbers))
				AND  ((SELECT Count(1) FROM @equipments) = 0 OR  equipmentid IN (SELECT field FROM @equipments))
				AND (((@startDate IS NULL OR @startDate <= StartTime)
			    AND (@endDate IS NULL OR StartTime <= @endDate)))

		SELECT distinct Number AS TicketNumber, 'tbl_sourceTicketNumbers' AS __dataset_tableName
		from #LastTaskData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR Number IN (SELECT field FROM @sourceTicketNumbers))
				AND  ((SELECT Count(1) FROM @equipments) = 0 OR  equipmentid IN (SELECT field FROM @equipments))
				AND (((@startDate IS NULL OR @startDate <= StartTime)
			    AND (@endDate IS NULL OR StartTime <= @endDate)))

		SELECT EquipmentId As EquipmentId, MAX(Machine) as EquipmentName , 'tbl_equipments' AS __dataset_tableName
		from #LastTaskData 
		Where 
				((SELECT Count(1) FROM @sourceTicketNumbers) = 0
				OR Number IN (SELECT field FROM @sourceTicketNumbers))
				AND  ((SELECT Count(1) FROM @equipments) = 0 OR  equipmentid IN (SELECT field FROM @equipments))
				AND (((@startDate IS NULL OR @startDate <= StartTime)
			    AND (@endDate IS NULL OR StartTime <= @endDate)))
		Group by EquipmentId

		
	DROP TABLE IF EXISTS #LastTasksData
	DROP TABLE IF EXISTS #LastTaskSchedule;
	DROP TABLE IF EXISTS #StartTimeData
END
