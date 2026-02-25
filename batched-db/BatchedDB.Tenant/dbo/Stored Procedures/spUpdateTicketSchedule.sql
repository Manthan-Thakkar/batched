CREATE  PROCEDURE [dbo].[spUpdateTicketSchedule]
	@scheduleId varchar(36),
	@equipmentId varchar(36),
	@startDate datetime,
	@endDate datetime,
	@overrideContraint bit
AS	
BEGIN
	DECLARE 
		@oldEquipmentId varchar(36),
		@feasibleCount int = 0,
		@downtimeCount int = 0,
		@holidayCount int = 0,
		@rangeStart datetime = null,
		@rangeEnd datetime = null,
		@outOfRange bit = 0;

	DROP TABLE IF EXISTS #ScheduleReport;
	
	-- Fetch schedule record from 
	-- return an the table with 0 value against 'Records' and do not process further
	SELECT SR.*, EM.FacilityId, TM.ID TicketId
	INTO #ScheduleReport 
	FROM ScheduleReport SR WITH(NOLOCK) 
	INNER JOIN TicketMaster TM WITH(NOLOCK) on SR.SourceTicketId = TM.SourceTicketId
	INNER JOIN EquipmentMaster EM WITH(NOLOCK)  ON EM.ID = SR.EquipmentId
	WHERE SR.SourceTicketId = (SELECT SourceTicketId FROM ScheduleReport WITH(NOLOCK) WHERE Id = @scheduleId)

	-- If no Schedule record found,
	-- return an the table with 0 value against 'Records' and do not process further
	IF(NOT EXISTS (SELECT 1 FROM #ScheduleReport WHERE Id = @scheduleId))
		BEGIN

			SELECT 
				@feasibleCount FeasibleRoutes,
				@downtimeCount Downtimes,
				@holidayCount Holidays,
				(SELECT COUNT(1) FROM #ScheduleReport WHERE Id = @scheduleId) Records,
				'tbl_TicketMovementFeasibility' as __dataset_tableName
		END
	ELSE
		BEGIN
		
			-- Fetch old equipment id for overriding the override constraint check
			-- when movement is done on same equipment
			SET @oldEquipmentId = (SELECT EquipmentId FROM #ScheduleReport WHERE Id = @scheduleId)

			-- Feasible Routes Count
			SELECT @feasibleCount = COUNT(1) 
			FROM FeasibleRoutes WITH(NOLOCK)
			WHERE RouteFeasible = 1 and EquipmentId = @equipmentId
			AND TicketId = (SELECT TicketId FROM #ScheduleReport WHERE Id = @scheduleId);


			select @rangeStart = MAX(EndsAt) from #ScheduleReport SR
			where EndsAt <= (Select StartsAt from #ScheduleReport WHERE Id = @scheduleId)

			select @rangeEnd = MIN(StartsAt) from #ScheduleReport SR
			where StartsAt >= (Select EndsAt from #ScheduleReport WHERE Id = @scheduleId)

			IF NOT ((@rangeStart <= @startDate or @rangeStart is null) AND (@rangeEnd >= @endDate or @rangeEnd is null))
			BEGIN
				SET @outOfRange = 1;
			END
			
			
			-- Downtimes Count
			SELECT @downtimeCount = COUNT(1) 
			FROM EquipmentDowntime WITH(NOLOCK)
			WHERE EquipmentId = @equipmentId
			AND @startDate <= EndsAt AND @endDate >= StartsOn; -- condition that suffices for all overlapping dates
			
			-- Holidays Count
			SELECT @holidayCount = COUNT(1) 
			FROM FacilityHoliday FH WITH(NOLOCK)
			INNER JOIN HolidaySchedule HS WITH(NOLOCK) on FH.HolidayId = HS.Id
			WHERE
				(HS.Date between CAST(@startDate as date) and CAST(@endDate as date))
				AND FH.FacilityId IN (SELECT FacilityId FROM #ScheduleReport WHERE Id = @scheduleId)

		
			IF(
				-- Allow entry if there are feasible routes available
				-- Allow entry when there are no feasible routes, but the override constraint is applied
				-- Allow entry when feasible routes are not found, and constraint override is also not applied, because ticket movement is done on same equipment
				-- Do not allow entry if any of the above conditions fail or there are Downtimes or Holidays in given date range
				(@feasibleCount > 0 OR @overrideContraint = 1 OR @oldEquipmentId = @equipmentId) 
				AND @downtimeCount = 0 AND @holidayCount = 0 AND @outOfRange = 0
			)
			BEGIN		
				BEGIN TRY
					BEGIN TRANSACTION;
					
					UPDATE SR
					SET
						SR.EquipmentId = @equipmentId,
						SR.StartsAt = @startDate,
						SR.EndsAt = @endDate,
						SR.IsPinned = 1,
						SR.PinType = 'time',
						SR.IsUpdated = 1,
						SR.FeasibilityOverride = (CASE 
													-- when there are no feasible routes, but the override constraint is applied
													WHEN @overrideContraint = 1 AND @feasibleCount = 0 THEN 1 
													-- when there are feasible routes and earlier data had override flag as true 
													WHEN @feasibleCount > 0 AND SR.FeasibilityOverride = 1 THEN 0
													-- ELSE let the previous value be as is
													ELSE SR.FeasibilityOverride 
													END),
						SR.ModifiedOn = GETUTCDATE()
					FROM ScheduleReport SR
					WHERE SR.Id = @scheduleId;

					COMMIT TRANSACTION;
				END TRY
				Begin CATCH
					-- Transaction uncommittable
					IF (XACT_STATE()) = -1
						ROLLBACK TRANSACTION;
 
					-- Transaction committable
					IF (XACT_STATE()) = 1
						COMMIT TRANSACTION;
				END CATCH
			END
			ELSE
			BEGIN
				SELECT 
					@feasibleCount FeasibleRoutes,
					@downtimeCount Downtimes,
					@holidayCount Holidays,
					(SELECT COUNT(1) FROM #ScheduleReport WHERE Id = @scheduleId) Records,
					@outOfRange OutOfRange,
					'tbl_TicketMovementFeasibility' as __dataset_tableName

			END

		END
	-- END OF ELSE

	
	DROP TABLE IF EXISTS #ScheduleReportDetail;

END
