CREATE PROCEDURE [dbo].[spGetOrderStatusFilters]
    @startDate					AS DATETIME = NULL,
    @endDate					AS DATETIME = NULL,
    @facilities					AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN
	
	DECLARE @tenantLocalTime DATETIME;
	SELECT @tenantLocalTime = SYSDATETIMEOFFSET() AT TIME ZONE (SELECT cv.Value
																FROM ConfigurationValue cv
																INNER JOIN ConfigurationMaster cm on cm.Id = cv.ConfigId
																Where cm.Name = 'Timezone');
	WITH OpenTicketsData AS (
	SELECT 
		TicketId, 
		TM.SourceTicketId AS TicketNumber,
		EM.FacilityId, 
		F.Name AS FacilityName,
		EM.WorkcenterTypeId AS WorkcenterId,
		EM.WorkCenterName,
		EVS.ValueStreamId,
		VS.Name AS ValueStreamName,
		TM.OTSName AS SalesRep,
		TM.ITSName AS CSR,
		TM.CustomerName AS Customer,
		TM.CustomerPO AS PONumber
	FROM TicketTask TT WITH (NOLOCK)--- All the tickets which have generated Ticket tasks pass the applicability rule by default
	INNER JOIN TicketMaster TM WITH (NOLOCK) ON TM.ID = TT.TicketID
	INNER JOIN EquipmentMaster EM WITH (NOLOCK) ON TT.OriginalEquipmentId = EM.Id
	LEFT JOIN EquipmentValueStream EVS WITH (NOLOCK) ON EVS.EquipmentId = EM.ID
	LEFT JOIN ValueStream VS WITH (NOLOCK) ON VS.Id = EVS.ValueStreamId
	LEFT JOIN Facility F WITH (NOLOCK) ON F.Id = EM.FacilityId
 	),
	-- Latest task times calculation
	WaitingForShipping as (
		SELECT  TicketId 
		FROM TicketTask with (nolock) group by TicketId having count(1) = sum(cast( iscomplete as int))
	)

	SELECT 
		DISTINCT
		OT.TicketId,
		OT.TicketNumber,
		OT.FacilityId,
		OT.FacilityName,
		OT.WorkcenterId,
		OT.WorkCenterName,
		OT.ValueStreamId,
		OT.ValueStreamName,
		OT.SalesRep,
		OT.CSR,
		OT.Customer,
		OT.PONumber,
		CASE
			WHEN US.TicketId is not null then 'Unscheduled'  --- Unscheduled
			WHEN TW.TicketId is not null then TW.TicketStatus  --- Scheduled worst case status
			WHEN WS.TicketId is not null then 'Waiting to Ship' --- Done but waiting for shipping
			ELSE Tm.SourceStatus 
		END as TicketStatus
		INTO #OrderStatusTicketData
		FROM OpenTicketsData OT 
		INNER JOIN TicketMaster TM with(nolock) on OT.TicketId = TM.ID
		INNER JOIN TicketShipping TS WITH(NOLOCK) ON OT.TicketId = TS.TicketId
		LEFT JOIN dbo.[view_ticketWorstCaseStatus] TW on Ot.TicketId = TW.TicketId
		LEFT JOIN  dbo.[view_LatestTaskTimes] TL on OT.TicketId =  TL.TicketId
		LEFT JOIN dbo.[view_TicketTaskRaw] US on OT.TicketId = US.TicketId -- Unscheduled tickets
		LEFT JOIN WaitingForShipping WS on OT.TicketId = WS.TicketId
		WHERE  ((CAST(@startDate AS DATE) = CAST(@tenantLocalTime AS DATE) AND TS.ShipByDateTime < @startDate) OR
				(@startDate IS NULL OR CAST(TS.ShipByDateTime AS DATE) >= CAST(@startDate AS DATE)))
			AND (@endDate IS NULL OR CAST(TS.ShipByDateTime AS DATE) <= CAST(@endDate AS DATE))
			AND	((SELECT Count(1) FROM @facilities) = 0  OR OT.FacilityId IN (SELECT field FROM @facilities))

	SELECT 
		* ,'tbl_orderStatusFilterData' AS __dataset_tableName
	FROM #OrderStatusTicketData
	
	DROP TABLE IF EXISTS #OrderStatusTicketData
END
