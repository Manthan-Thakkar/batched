CREATE PROCEDURE [dbo].[spGetAllEquipmentSchedule]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 10,
	@SortingColumn AS VARCHAR(100) = 'default',
    @startDate AS DATETIME = NULL,
    @endDate AS DATETIME = NULL,
    @equipments AS UDT_SINGLEFIELDFILTER readonly,
    @facilities AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly,
    @workcenters AS UDT_SINGLEFIELDFILTER readonly,
    @numberOfTimeCardDays AS INT = 15,
	@currentLocalDate as Datetime  = null,
	@CorelationId VARCHAR(40) = NULL,
	@TenantId VARCHAR(40) = NULL
AS
BEGIN
	DECLARE 
		@spName					VARCHAR(100) = 'spGetAllEquipmentSchedule',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000,
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;

	if(@currentLocalDate = null)
		set @currentLocalDate = GETDATE()

	IF(@CorelationId IS NULL)
		SET @CorelationId = NEWID()
	IF(@TenantId IS NULL)
		SELECT TOP 1 @TenantId = TenantId FROM TicketMaster

	SET @blockName = 'timecard'; SET @startTime = GETDATE();

        /** Calculate a DateTime value for latest scan **/
        SELECT
            tc.equipmentid,
            tc.sourceticketid
            , startedon AS StartDateTime -- to adjust time stored as integer in DB
		INTO #timecard
        FROM
            timecardinfo tc
        WHERE
             startedon > Dateadd(day,-@numberOfTimeCardDays,@currentLocalDate
    )
	CREATE NONCLUSTERED INDEX [IX_Timecard_Temp] ON #timecard (EquipmentId) INCLUDE (StartDateTime)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'latestruntime'; SET @startTime = GETDATE();
  
        /** Find latest scan for each press **/
        SELECT
            tc.equipmentid
            , Max(startdatetime) AS MaxStartDateTime
		INTO #latestruntime
        FROM
            #timecard tc
        GROUP BY
            tc.equipmentid

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	
	SET @blockName = 'lastrun'; SET @startTime = GETDATE();
        /** Find latest ticket run on each machine, load key attributes to identify possible changeovers **/
		SELECT
            lrt.equipmentid AS LastRunEquipmentId
            , Cast(tc.sourceticketid AS NVARCHAR(255)) AS LastRunSourceTicketId
		INTO #lastrun
        FROM
            #latestruntime LRT
        INNER JOIN
            #timecard tc
            ON LRT.equipmentid = tc.equipmentid
            AND LRT.maxstartdatetime = tc.startdatetime

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
     
	SET @blockName = 'tasktime'; SET @startTime = GETDATE();

		SELECT
           tt.EstMaxDueDateTime AS TaskDueTime, ts.shipbydatetime, ts.ticketid, iscomplete, tm.sourceticketid, tt.taskname
           , LAG(tt.IsComplete) OVER (PARTITION BY TT.TicketId ORDER BY tt.Sequence) PreviousIsComplete
		INTO #tasktime
        FROM
            tickettask tt
            INNER JOIN ticketshipping ts
                ON ts.ticketid = tt.ticketid
            INNER JOIN ticketmaster tm
                ON tm.id = tt.ticketid
        WHERE
            ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  tm.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
	
	CREATE NONCLUSTERED INDEX [IX_TaskTime_Temp] ON #tasktime (sourceticketid) INCLUDE (TaskDueTime,shipbydatetime,iscomplete)

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	
	SET @blockName = 'taskStatuses'; SET @startTime = GETDATE();
        SELECT
            sr.SourceTicketId,
            sr.TaskName,
			sr.Startsat,
			sr.endsat,
            CASE
                WHEN iscomplete=1 THEN 'Complete'
                --WHEN lr.lastrunsourceticketid IS NOT NULL THEN 'On Press'
                WHEN tm.shipbydatetime IS NULL THEN 'Late'
                WHEN sr.endsat IS NULL THEN 'Unscheduled'
                WHEN @currentLocalDate> tm.taskduetime OR sr.endsat > tm.taskduetime THEN 'Late'
                WHEN   Datediff(hh, @currentLocalDate, tm.taskduetime) < 4
                    OR Datediff(hh, sr.endsat, tm.taskduetime) < 4 THEN 'At Risk'
                WHEN @currentLocalDate >sr.endsat THEN 'Behind'
                ELSE 'On Track'
            END
                AS TaskStatus,
            CASE
                WHEN lr.lastrunsourceticketid IS NOT NULL THEN CAST(1 as bit)
                ELSE CAST(0 as bit)
            END AS IsOnPress      
			INTO #taskStatuses
            FROM schedulereport sr
            LEFT join TicketMaster TMM on sr.SourceTicketId = TMM.SourceTicketId
            LEFT JOIN #tasktime tm
                ON tm.sourceticketid = sr.sourceticketid
                AND tm.taskname = sr.taskname
            LEFT JOIN #lastrun lr
                ON lr.lastrunsourceticketid = tm.sourceticketid
                AND lr.lastrunequipmentid = sr.equipmentid
            LEFT JOIN TicketScore TSC on TMM.ID = TSC.TicketId
            WHERE
                ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
       
	   	CREATE NONCLUSTERED INDEX [IX_TaskStatus_Temp] ON #taskStatuses (sourceticketid) INCLUDE (TaskName,StartsAt,EndsAt,TaskStatus)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'taskGrouping'; SET @startTime = GETDATE();

		select SourceTicketId ,
		STRING_AGG( TaskName +'*,*'+convert(varchar, StartsAt,0 )+'*,*'+convert(varchar,EndsAt,0)+'*,*'+TaskStatus+'*,*'+CAST( IsOnPress as varchar),'|||') within group (order by [startsat] asc)  as TaskString
		INTO #taskGrouping
		from #taskStatuses group by SourceTicketId
		
		
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	
	SET @blockName = 'schedule'; SET @startTime = GETDATE();
     
            SELECT
            sr.*,
			TMM.ID as TicketId,
			tss.TaskStatus,
			tss.IsOnPress,
            Case When Sr.IsPinned = 1 Then  'Locked' Else 'Unlocked' END as LockStatus,
            Case When Sr.IsPinned = 1 Then  Sr.PinType Else NULL END as LockType,
            ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketPoints
            , CASE 
                WHEN PreviousIsComplete = 0 THEN CAST(1 as BIT)
                ELSE CAST(0 as BIT)
            END Highlight
            ,TaskString
            INTO #schedule
            FROM schedulereport sr
			inner join #taskStatuses tss on sr.SourceTicketId = tss.SourceTicketId and sr.TaskName = tss.TaskName 
			LEFT join #taskGrouping tg on sr.SourceTicketId = tg.SourceTicketId
            LEFT join TicketMaster TMM on sr.SourceTicketId = TMM.SourceTicketId
            LEFT JOIN #tasktime tm
                ON tm.sourceticketid = sr.sourceticketid
                AND tm.taskname = sr.taskname
            LEFT JOIN #lastrun lr
                ON lr.lastrunsourceticketid = tm.sourceticketid
                AND lr.lastrunequipmentid = sr.equipmentid
            LEFT JOIN TicketScore TSC on TMM.ID = TSC.TicketId
            WHERE
                ((SELECT Count(1) FROM @sourceTicketNumbers) = 0 OR  sr.sourceticketid IN (SELECT field FROM @sourceTicketNumbers))
                AND  ((SELECT Count(1) FROM @equipments) = 0 OR  sr.equipmentid IN (SELECT field FROM @equipments))
                AND (@startDate IS NULL OR @startDate <= sr.endsat)
                AND (@endDate IS NULL OR @endDate >= sr.startsat)
		
		CREATE NONCLUSTERED INDEX [IX_Schedule_Temp] ON #schedule (sourceticketid) INCLUDE (TaskName,StartsAt,EndsAt,TaskStatus)


	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Tickets Distinct'; SET @startTime = GETDATE();
	
		Select distinct Ticketid into #Tickets from #schedule
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Substrate'; SET @startTime = GETDATE();

		-- substrate calculation
		select TS.TicketId,SM.SourceStockId ,TS.Width as SubstrateWidth
		into #Substrate
		from TicketStock TS with (nolock) inner join #Tickets TR with (nolock) on TS.TicketId = TR.TicketId and TS.Sequence =2
		inner join StockMaterial SM  with (nolock)on TS.StockMaterialId =  SM.Id

		CREATE NONCLUSTERED INDEX [IX_Substrate_Temp] ON #Substrate (ticketId) INCLUDE (SourceStockId, SubstrateWidth)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	
	SET @blockName = 'TicketTool'; SET @startTime = GETDATE();
		--- TicketTool calculation
		select TT.TicketId,TI.SourceToolingId
		into #TicketTool
		from TicketTool TT with (nolock) inner join #Tickets TR with (nolock)on TT.TicketId = TR.TicketId and TT.Sequence =1
		inner join ToolingInventory TI with (nolock) on TT.ToolingId = TI.ID

		CREATE NONCLUSTERED INDEX [IX_TicketTool_Temp] ON #TicketTool (ticketId) INCLUDE (SourceToolingId)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Colors'; SET @startTime = GETDATE();

		--- Colors calculation Temp
		select TTR.TicketId,TAV.Value as Colors
		into #Colors
		from 
		#Tickets TTR with (nolock) inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = 'Colors'

		CREATE NONCLUSTERED INDEX [IX_Colors_Temp] ON #Colors (ticketId) INCLUDE (Colors)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Varnish'; SET @startTime = GETDATE();

		--- Varnish calculation Temp
		select TTR.TicketId,TAV.Value as Varnish
		into #Varnish
		from 
		#Tickets TTR with (nolock) inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = 'Varnish'

		CREATE NONCLUSTERED INDEX [IX_Varnish_Temp] ON #Varnish (ticketId) INCLUDE (Varnish)

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'schedulereportdetail'; SET @startTime = GETDATE();

        SELECT
			DISTINCT
            s.*,
			(CASE WHEN s.MasterRollNumber is not null THEN CAST(1 as BIT) ELSE CAST(0 as BIT) END) isMasterRoll,
            em.NAME AS EquipmentName,
            em.displayname AS EquipmentDisplayName,
            em.workcentertypeid,
            em.workcentername,
            em.facilityid,
			TS.SourceStockId AS Substrate,
			CAST(TS.SubstrateWidth AS nvarchar(30)) AS StockWidth,
			TT.SourceToolingId as MainTool,
			TM.CustomerName as Customer,
			TSS.ShipByDateTime  AS ShipByDate,
			CAST(TTT.EstMeters AS decimal(38, 4)) as TaskMeters,
			TTT.TaskName as Task,
			TM.GeneralDescription as GeneralDescription,
			CASE WHEN SO.ID is not null THEN 1 ELSE 0 END as IsManuallyScheduled,
			SO.Notes as SchedulingNotes,
			 CASE 
				WHEN s.MasterRollNumber is not null AND (TTT.Sequence <> 1 OR s.MasterRollNumber like 'PRINTED_%') THEN (CAST(1 as bit))
				ELSE (CAST(0 as bit))
			END IsMasterRollGroup,
			TD.CoreSize as CoreSize,
			TD.CalcNumLeftoverRolls as NumberOfCores,
            Varnish.Varnish as Varnish,
			Color.Colors as Colors,
            0 as IsRollingLock ---- this limited to showing indicator / Currently set to false always
        INTO #schedulereportdetail
        FROM #schedule s
        INNER JOIN equipmentmaster em
            ON em.id = s.equipmentid
			
			INNER JOIN TicketMaster TM on s.SourceTicketId = TM.SourceTicketId
			LEFT join ScheduleOverride SO on TM.ID = SO.TicketId and s.TaskName = SO.TaskName and SO.IsScheduled = 1
			LEFT JOIN TicketTask TTT on Tm.ID = TTT.TicketId and s.TaskName = TTT.TaskName
			LEFT JOIN #Substrate TS on TS.TicketId = TM.ID 
			LEFT JOIN #TicketTool TT on TT.TicketId = Tm.ID
			LEFT JOIN TicketShipping TSS on TM.ID =  TSS.TicketId
			LEFT JOIN TicketDimensions TD on TM.ID = TD.TicketId
			LEFT JOIN #Varnish Varnish on TM.ID = Varnish.TicketId
			LEFT JOIN #Colors Color on TM.ID = Color.TicketId 
           WHERE
            ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
            AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

		

	if(@SortingColumn <> 'default')

	BEGIN
		SET @blockName = 'ordering schedule'; SET @startTime = GETDATE();

    -- tbl_ScheduleReport
		SELECT *, 'tbl_ScheduleReport' AS __dataset_tableName FROM #schedulereportdetail
		Order by 

			CASE WHEN @SortingColumn = '+status'  THEN TaskStatus END ,
			CASE WHEN @SortingColumn = '-status'  THEN TaskStatus END DESC,
			CASE WHEN @SortingColumn = '+workcenter'  THEN WorkCenterName END ,
			CASE WHEN @SortingColumn = '-workcenter'  THEN WorkCenterName END DESC,
			CASE WHEN @SortingColumn = '+equipment'  THEN EquipmentName END ,
			CASE WHEN @SortingColumn = '-equipment'  THEN EquipmentName END DESC,
			CASE WHEN @SortingColumn = '+customer'  THEN Customer END ,
			CASE WHEN @SortingColumn = '-customer'  THEN Customer END DESC,
			CASE WHEN @SortingColumn = '+substrate'  THEN Substrate END ,
			CASE WHEN @SortingColumn = '-substrate'  THEN Substrate END DESC,
			CASE WHEN @SortingColumn = '+stockwidth'  THEN StockWidth END ,
			CASE WHEN @SortingColumn = '-stockwidth'  THEN StockWidth END DESC,
			CASE WHEN @SortingColumn = '+mainTool'  THEN MainTool END ,
			CASE WHEN @SortingColumn = '-mainTool'  THEN MainTool END DESC,
			CASE WHEN @SortingColumn = '+taskMinutes'  THEN TaskMinutes END ,
			CASE WHEN @SortingColumn = '-taskMinutes'  THEN TaskMinutes END DESC,
			CASE WHEN @SortingColumn = '+changeoverTime'  THEN ChangeoverMinutes END ,
			CASE WHEN @SortingColumn = '-changeoverTime'  THEN ChangeoverMinutes END DESC,
			CASE WHEN @SortingColumn = '+shipByDate'  THEN ShipByDate END ,
			CASE WHEN @SortingColumn = '-shipByDate'  THEN ShipByDate END DESC,
			CASE WHEN @SortingColumn = '+startTime'  THEN StartsAt END ,
			CASE WHEN @SortingColumn = '-startTime'  THEN StartsAt END DESC,
			CASE WHEN @SortingColumn = '+endTime'  THEN EndsAt END ,
			CASE WHEN @SortingColumn = '-endTime'  THEN EndsAt END DESC,
			CASE WHEN @SortingColumn = '+number'  THEN SourceTicketId END ,
			CASE WHEN @SortingColumn = '-number'  THEN SourceTicketId END DESC,
			CASE WHEN @SortingColumn = '+taskMeters'  THEN TaskMeters END ,
			CASE WHEN @SortingColumn = '-taskMeters'  THEN TaskMeters END DESC,
			CASE WHEN @SortingColumn = '+task'  THEN TaskName END ,
			CASE WHEN @SortingColumn = '-task'  THEN TaskName END DESC,
			CASE WHEN @SortingColumn = '+generalDescription'  THEN GeneralDescription END ,
			CASE WHEN @SortingColumn = '-generalDescription'  THEN GeneralDescription END DESC,
			CASE WHEN @SortingColumn = '+lockStatus'  THEN LockStatus END ,
			CASE WHEN @SortingColumn = '-lockStatus'  THEN LockStatus END DESC,
			CASE WHEN @SortingColumn = '+ticketPoints'  THEN TicketPoints END ,
			CASE WHEN @SortingColumn = '-ticketPoints'  THEN TicketPoints END DESC

			OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY
			
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

		END

	if(@SortingColumn = 'default')

	BEGIN
		SET @blockName = 'ordering schedule by default'; SET @startTime = GETDATE();

		SELECT *, 'tbl_ScheduleReport' AS __dataset_tableName FROM #schedulereportdetail
		Order by EquipmentName,StartsAt
		OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY
	
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END


	SET @blockName = 'SR count of records'; SET @startTime = GETDATE();

	Select count(1) as TotalCount,'tbl_ScheduleReport_count' AS __dataset_tableName	
	from #schedule s 
	inner join EquipmentMaster em 
	ON em.id = s.equipmentid
	WHERE
        ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
        AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'schedule report into temp'; SET @startTime = GETDATE();
	
	-- Temporary ScheduleReport data 
	SELECT * INTO #ScheduleReport FROM ScheduleReport WITH(NOLOCK);
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'TicketNumbers'; SET @startTime = GETDATE();

	---- TicketNumbers
    SELECT distinct(SourceTicketId) as TicketNumber, 'tbl_ticketNumbers' AS __dataset_tableName
	from #ScheduleReport s 
	inner join EquipmentMaster em ON em.id = s.equipmentid
	WHERE
            ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
            AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))
            AND ((SELECT Count(1) FROM @equipments) = 0  OR em.ID in (SELECT field FROM @equipments))

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Time window'; SET @startTime = GETDATE();

	---------- Time window
	select IIF(@startDate is NULL, min(StartsAt), @startDate) as StartDate, IIF(@endDate is NULL, max(EndsAt), @endDate) as EndDate , 'tbl_timeWindow' AS __dataset_tableName
	from #schedule s 
	inner join EquipmentMaster em 
	ON em.id = s.equipmentid
	WHERE
        ((SELECT Count(1) FROM @facilities) = 0  OR em.facilityid  IN (SELECT field FROM @facilities))
        AND ((SELECT Count(1) FROM @workcenters) = 0  OR em.WorkcenterTypeId in (SELECT field FROM @workcenters))

   	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Facilities'; SET @startTime = GETDATE();
	----------- Facilities
	Select distinct(FacilityId) As FacilityId , 'tbl_facilities' AS __dataset_tableName  
	from #schedule s 
	inner join EquipmentMaster em ON em.id = s.equipmentid

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	------ Workcenters
	SET @blockName = 'Workcenters'; SET @startTime = GETDATE();

    Select DISTINCT WorkcenterTypeId As WorkcenterId, WorkCenterName as WorkcenterName , 'tbl_workcenters' AS __dataset_tableName 
	from EquipmentMaster
	where IsEnabled = 1 and AvailableForPlanning = 1 and AvailableForScheduling = 1
	 and ((SELECT Count(1) FROM @facilities) = 0  OR facilityid  IN (SELECT field FROM @facilities))
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	----- Equipments

	SET @blockName = 'Equipments'; SET @startTime = GETDATE();
	
	Select DISTINCT ID As EquipmentId, Name as EquipmentName, WorkcenterTypeId WorkcenterId,FacilityId FacilityId, 'tbl_equipments' AS __dataset_tableName 
	from EquipmentMaster
	where IsEnabled = 1 and AvailableForPlanning = 1 and AvailableForScheduling = 1
    and
        ((SELECT Count(1) FROM @facilities) = 0  OR facilityid  IN (SELECT field FROM @facilities))
        AND ((SELECT Count(1) FROM @workcenters) = 0  OR WorkcenterTypeId in (SELECT field FROM @workcenters))
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Schedule Run Status'; SET @startTime = GETDATE();
    
	SELECT [Status],
	CASE WHEN (ExpiryTimeStamp <= GetUTCDATE()) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS isExpired, 'tbl_scheduleRunStatus' AS __dataset_tableName
	FROM scheduleRunStatus
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'Drop Temp tables'; SET @startTime = GETDATE();

	
	DROP TABLE IF EXISTS #schedulereportdetail ;
	DROP TABLE IF EXISTS #timecard;
	DROP TABLE IF EXISTS #latestruntime;
	DROP TABLE IF EXISTS #lastrun;
	DROP TABLE IF EXISTS #tasktime;
	DROP TABLE IF EXISTS #taskStatuses;
	DROP TABLE IF EXISTS #taskGrouping;
	DROP TABLE IF EXISTS #schedule;
	DROP TABLE IF EXISTS #ScheduleReport;
	DROP TABLE IF EXISTS #Colors 
	DROP TABLE IF EXISTS #Varnish
	DROP TABLE IF EXISTS #TicketTool
	DROP TABLE IF EXISTS #Substrate;
	DROP TABLE IF EXISTS #Tickets;
	DROP TABLE IF EXISTS #DistinctEquipmentId;
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog order by TimeTakenInMs desc;

END