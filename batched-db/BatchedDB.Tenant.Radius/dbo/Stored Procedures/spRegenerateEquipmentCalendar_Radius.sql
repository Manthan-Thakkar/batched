CREATE PROCEDURE [dbo].[spRegenerateEquipmentCalendar]
	@EquipmentIds udt_equipmentInfo READONLY,
	@StartDate date = NULL,
	@EndDate date = NULL
AS			
BEGIN
	SET NOCOUNT ON;
		
	BEGIN TRANSACTION;

	Begin TRY	
	
		DECLARE @batch_startDate  date =  DateAdd(Day, -7,  CONVERT(date, GETDATE()));
		DECLARE @batch_endDate  date =  DATEADD(DAY, 180, CONVERT(date, GETDATE())); 
		
		DECLARE @custom_dates bit = IIF(@StartDate IS NOT NULL OR @EndDate IS NOT NULL, 1, 0);
		DECLARE @casted_startDate datetime;
		DECLARE @casted_EndDate datetime;
		DECLARE @EquipmentCount int = (SELECT COUNT(EquipmentId) FROM @EquipmentIds)

		--Make a full copy of MinutewiseCalendar records with time indexes
		SELECT
			C.TheDate,
			MWC.TheDateTime, 
			MWC.TimeIndex,
			C.TheDayName as [DayOfWeek]
		into #scopedMinutewiseCalendar
		FROM MinutewiseCalendar MWC 
			INNER JOIN Calendar C on C.TheDate = MWC.TheDate
		WHERE C.TheDate BETWEEN @batch_startDate and @batch_endDate
		OPTION(RECOMPILE)

		CREATE NONCLUSTERED INDEX [IX_ScopedMinutewiseCalendar_Tmp] ON #scopedMinutewiseCalendar (TheDate)  INCLUDE (TheDateTime,TimeIndex);

		--master equipment list
		Create table #masterEquipments(ID varchar(36), SourceEquipmentId nvarchar(4000), FacilityId varchar(36))

		INSERT INTO #masterEquipments(ID, SourceEquipmentId, FacilityId)
			Select EM.ID, EM.SourceEquipmentId, EM.FacilityId FROM EquipmentMaster EM
			WHERE 
				EM.IsEnabled = 1
				AND EM.AvailableForScheduling  = 1 
				AND (@EquipmentCount = 0 OR EM.ID IN (SELECT EquipmentId FROM @EquipmentIds))

		CREATE NONCLUSTERED INDEX [IX_MasterEquipments_Tmp] ON #masterEquipments (ID) INCLUDE (SourceEquipmentId,  FacilityId);

        CREATE TABLE #EquipmentMinuteWiseShiftCalender(EquipmentID varchar(36), SourceEquipmentId nvarchar(4000),TheDateTime datetime, TimeIndex int, Available int, DowntimeReason VarChar(500), seq int)

		--FOR EACH EQUIPMENT
		WHILE EXISTS (SELECT TOP 1 1 FROM #masterEquipments)
		BEGIN

			Declare @currentBatchEquipment varchar(36);
			Declare @currentBatchFacility varchar(36);
			Declare @currentBatchSourceEquipment varchar(36);
			
			Select top 1
				@currentBatchEquipment = Id,
				@currentBatchFacility = FacilityId,
				@currentBatchSourceEquipment = SourceEquipmentId
			FROM #masterEquipments;

			--Extract ShiftCalendarSchedule for active Equipments
			SELECT distinct 
					ESM.EquipmentId,
					C.TheDate,
					SCP.starttime,
					SCP.endtime,
					1 AS Available,
					'ShiftCalendar schedule' AS Reason, 
					1 AS [Priority]
				INTO #equipmentDayWiseShiftCalender
				FROM ShiftCalendarScheduleV2 SCS 
					INNER JOIN ShiftCalendarV2 SCV2 ON SCS.Id = SCV2.ShiftCalendarScheduleId
					INNER JOIN EquipmentScheduleMapping ESM ON ESM.ShiftCalendarScheduleId = SCS.Id
					INNER JOIN ShiftCalendarDatesV2 SCD on SCV2.Id = SCD.ShiftCalendarId
					INNER JOIN ShiftCalendarPatternV2 SCP on SCP.ShiftCalendarId = SCV2.Id
					INNER JOIN Calendar C on (C.TheDate between @batch_startDate and @batch_endDate) and (C.TheDayName = SCP.[DayOfWeek]) and (C.TheDate between SCD.startDate and SCD.endDate)
				Where ESM.EquipmentId = @currentBatchEquipment
		
			--Extract FacilityHoliday for active Equipments
			INSERT INTO #equipmentDayWiseShiftCalender
			SELECT 
				@currentBatchEquipment as EquipmentId ,
				HS.[Date] as TheDate,
				'00:00:00' as starttime,
				'23:59:00' as endtime,
				0 as Available,
				'Facility holiday' as Reason, 
				2 as [Priority]
			FROM FacilityHoliday FH 
				inner join HolidaySchedule HS on FH.HolidayId = HS.Id
			WHERE HS.[Date] between @batch_startDate and @batch_endDate
				AND FH.FacilityId = @currentBatchFacility

	
		--Extract ShiftOverride for active Equipments
			INSERT INTO #equipmentDayWiseShiftCalender
			SELECT   
				SO.EquipmentId as EquipmentId,
				SO.ExceptionDate as TheDate,
				SOT.StartTime as starttime,
				SOT.EndTime as endtime,
				1 as Available,
				'Shift override' as Reason,
				3 as [Priority]
			FROM ShiftOverride SO 
				inner join ShiftOverrideTimes SOT on SO.Id = SOT.ShiftOverrideId
			WHERE
				SO.IsEnabled=1 
				AND SO.EquipmentId = @currentBatchEquipment
				AND SO.ExceptionDate between @batch_startDate and @batch_endDate

			MERGE #equipmentDayWiseShiftCalender AS Target
				USING (SELECT  EquipmentId, TheDate, [Priority] 
						From (SELECT EquipmentId, TheDate, [Priority], ROW_NUMBER() OVER (PARTITION BY EquipmentId, TheDate ORDER BY [Priority] DESC) as ROW_NUM
							From #equipmentDayWiseShiftCalender EDWSC) as dataset  WHERE ROW_NUM = 1
						) AS Source
					ON Source.EquipmentId = Target.EquipmentId and Source.TheDate = Target.TheDate and Source.[Priority] = Target.[Priority]
    
				WHEN NOT MATCHED By Source THEN
					DELETE;

			--Extract EquipmentDowntime for active Equipments
			SELECT 
				ED.EquipmentId as EquipmentId, 
				C.TheDate, 
				CASE WHEN CONVERT(date, ED.StartsOn) = C.TheDate
						THEN CONVERT(time, ED.StartsOn)
					ELSE
						'00:00:00'
					END as StartTime,
				CASE WHEN CONVERT(date, ED.EndsAt) = C.TheDate
						THEN CONVERT(time, ED.EndsAt)
					ELSE
						'23:59:00'
					END as EndTime,
				0 as Available,
				'EquipmentDowntime' as Reason,
				4 as [Priority]
			INTO #equipmentDowntime
			FROM EquipmentDowntime ED 
			INNER JOIN Calendar C on (C.TheDate between @batch_startDate and @batch_endDate) AND (C.TheDate between CONVERT(date, ED.StartsOn) and CONVERT(date, ED.EndsAt))
			WHERE ED.EquipmentId = @currentBatchEquipment
			
			--Added one layer more of filtering on day level 
			--Below output may contain conflictig schedule which is filtered in transformation to timeIndex layer
			MERGE #equipmentDayWiseShiftCalender AS Target
				USING #equipmentDowntime AS Source
					ON Source.EquipmentId = Target.EquipmentId and Source.TheDate = Target.TheDate
					AND Target.StartTime between Source.StartTime and Source.EndTime
					AND Target.EndTime between Source.StartTime and Source.EndTime
    
				WHEN MATCHED THEN
					DELETE;
					
			INSERT INTO #equipmentDayWiseShiftCalender
			SELECT EquipmentId, TheDate, starttime, endtime, Available, Reason, [Priority] FROM #equipmentDowntime
			
			--Transforming Day level of equipment to minute/TimeIndex Level
			insert into #EquipmentMinuteWiseShiftCalender
				SELECT @currentBatchEquipment as EquipmentID,
					@currentBatchSourceEquipment as SourceEquipmentId,
					SMWC.TheDateTime,
					SMWC.TimeIndex,
					EDWSC.Available,
					case when EDWSC.Available = 0
						Then EDWSC.Reason 
						ELSE    
							NULL
					END as DowntimeReason, 
					ROW_NUMBER() OVER (PARTITION BY SMWC.TheDateTime ORDER BY EDWSC.[Priority] DESC) as seq
				FROM Calendar C
				INNER JOIN #scopedMinutewiseCalendar SMWC on SMWC.TheDate = C.TheDate
				INNER JOIN #equipmentDayWiseShiftCalender EDWSC on EDWSC.TheDate = C.TheDate
				WHERE
                	CONVERT(time, SMWC.TheDateTime) between EDWSC.StartTime and EDWSC.EndTime

			
			DELETE FROM #masterEquipments WHERE Id = @currentBatchEquipment;

			DROP TABLE IF EXISTS #equipmentDayWiseShiftCalender
			DROP TABLE IF EXISTS #masterEquipmentCalendar
			DROP TABLE IF EXISTS #equipmentDowntime
		END

		IF(@EquipmentCount > 0)
		BEGIN

			DECLARE @partitionIds varchar(MAX);
			select @partitionIds= STRING_AGG(partition_number,',') from (
			select distinct rv.value AS PartitionFunctionValue, p.partition_number
				from sys.indexes i WITH(NOLOCK)  
				join sys.partitions p WITH(NOLOCK) ON i.object_id=p.object_id AND i.index_id=p.index_id  
				join sys.partition_schemes ps WITH(NOLOCK) on ps.data_space_id = i.data_space_id  
				join sys.partition_functions pf WITH(NOLOCK) on pf.function_id = ps.function_id  
				left join sys.partition_range_values rv WITH(NOLOCK) on rv.function_id = pf.function_id AND rv.boundary_id = p.partition_number
			where i.object_id = object_id('EquipmentCalendar')
			AND rv.value in (SELECT EquipmentId FROM @EquipmentIds)) res

			DECLARE @sqlcmd nvarchar(max);
			SET @sqlcmd = N'truncate table EquipmentCalendar with (partitions(' + @partitionIds + '))' ;
			EXEC SP_EXECUTESQL @sqlcmd

			--DELETE ALL RECORDS FOR AN EQUIPMENT OR DATE RANGE
			-- DELETE FROM EquipmentCalendar
			-- 	WHERE EquipmentId IN (SELECT EquipmentId FROM @EquipmentIds)
			-- OPTION(RECOMPILE);

		END
		ELSE
		BEGIN
			
			EXEC [spRepartitionEquipmentCalendar]
			ALTER INDEX ALL ON EquipmentCalendar DISABLE
		END
     
        INSERT INTO EquipmentCalendar (EquipmentId,SourceEquipmentId,TheDateTime,TimeIndex,AdjustedTimeIndex,Available,DowntimeReason) 
            SELECT EquipmentId,
                SourceEquipmentId,
                TheDateTime,
                TimeIndex,
                CASE WHEN Available = 1
                    THEN 
                        ROW_NUMBER() OVER (PARTITION BY Dataset.EquipmentId, DataSet.Available ORDER BY DataSet.TimeIndex ASC)
                    ELSE 
                        NULL
                    END as AdjustedTimeIndex,
                Available,
                DowntimeReason
            FROM #EquipmentMinuteWiseShiftCalender DataSet
            WHERE DataSet.seq = 1
            --OPTION(RECOMPILE)
		
		IF(@EquipmentCount = 0)
		BEGIN
			ALTER INDEX ALL ON EquipmentCalendar REBUILD
		END
		
		DROP TABLE IF EXISTS #EquipmentMinuteWiseShiftCalender
		DROP TABLE IF EXISTS #masterEquipments
		DROP TABLE IF EXISTS #scopedMinutewiseCalendar

		COMMIT;
	END TRY
	Begin CATCH
		DROP TABLE IF EXISTS #equipmentDayWiseShiftCalender
		DROP TABLE IF EXISTS #masterEquipmentCalendar
		DROP TABLE IF EXISTS #equipmentDowntime
		DROP TABLE IF EXISTS #masterEquipments
		DROP TABLE IF EXISTS #scopedMinutewiseCalendar

		Rollback;
	END CATCH
END


