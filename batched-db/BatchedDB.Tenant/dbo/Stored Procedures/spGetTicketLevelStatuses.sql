CREATE   PROCEDURE [dbo].[spGetTicketLevelStatuses]
    @startDate					AS DATETIME = NULL,
    @endDate					AS DATETIME = NULL,
    @facilities					AS UDT_SINGLEFIELDFILTER readonly,
    @valuestreams				AS UDT_SINGLEFIELDFILTER readonly,
    @customers					AS UDT_SINGLEFIELDFILTER readonly,
    @csr						AS UDT_SINGLEFIELDFILTER readonly,
    @salesPerson				AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers		AS UDT_SINGLEFIELDFILTER readonly,
    @poNumbers					AS UDT_SINGLEFIELDFILTER readonly,
	@CorelationId				AS VARCHAR(36) = NULL,
	@TenantId					AS VARCHAR(36) = NULL
AS
BEGIN
	
	DECLARE @tenantLocalTime DATETIME;
	SELECT @tenantLocalTime = SYSDATETIMEOFFSET() AT TIME ZONE (SELECT cv.Value
																FROM ConfigurationValue cv
																INNER JOIN ConfigurationMaster cm on cm.Id = cv.ConfigId
																Where cm.Name = 'Timezone');

	WITH OpenTicketsData AS (
	SELECT 
		distinct 
		TT.TicketId, 
		CASE WHEN TS.ShipByDateTime  IS NULL THEN GETUTCDATE()
		ELSE TS.ShipByDateTime END AS ShipByDateTime,
		EM.FacilityId, 
		EVS.ValueStreamId
	FROM TicketTask TT WITH (NOLOCK)--- All the tickets which have generated Ticket tasks pass the applicability rule by default
	INNER JOIN EquipmentMaster EM WITH (NOLOCK) ON TT.OriginalEquipmentId = EM.Id
	INNER JOIN TicketShipping TS WITH(NOLOCK) ON TT.TicketId = TS.TicketId
	LEFT JOIN EquipmentValueStream EVS ON EVS.EquipmentId = EM.ID
 	),
	-- Latest task times calculation
	WaitingForShipping as (
		SELECT  TicketId 
		FROM TicketTask with (nolock) group by TicketId having count(1) = sum(cast( iscomplete as int))
	)

	SELECT 
		DISTINCT
		OT.TicketId,
		OT.ShipByDateTime AS ShipByDate,
		CASE
			WHEN US.TicketId IS NOT NULL then 'Unscheduled'  --- Unscheduled
			WHEN TW.TicketId IS NOT NULL then TW.TicketStatus  --- Scheduled worst case status
			WHEN WS.TicketId is not null then 'Waiting to Ship' --- Done but waiting for shipping
			ELSE Tm.SourceStatus 
		END AS Status,
		'tbl_ticketLevelStatuses' AS __dataset_tableName
		FROM OpenTicketsData OT 
		INNER JOIN TicketMaster TM with(nolock) on OT.TicketId = TM.ID
		LEFT JOIN dbo.[view_ticketWorstCaseStatus] TW on Ot.TicketId = TW.TicketId
		LEFT JOIN dbo.[view_TicketTaskRaw] US on OT.TicketId = US.TicketId -- Unscheduled tickets
		LEFT JOIN WaitingForShipping WS on OT.TicketId = WS.TicketId
		WHERE  OT.ShipByDateTime IS NOT NULL  
			AND (OT.ShipByDateTime>=DATEADD(d, -30, GETDATE()) 
			AND (TM.IsOpen = 1 Or TM.IsOnHold =1)) 
			AND TM.SourceTicketType in (0, 1, 3)
			AND TM.SourceStockTicketType != 1 
			AND ((CAST(@startDate AS DATE) = CAST(@tenantLocalTime AS DATE) AND OT.ShipByDateTime < @startDate) OR
				(@startDate IS NULL OR CAST(OT.ShipByDateTime AS DATE) >= CAST(@startDate AS DATE)))
			AND (@endDate IS NULL OR CAST(OT.ShipByDateTime AS DATE) <= CAST(@endDate AS DATE))
			AND	((SELECT Count(1) FROM @facilities) = 0  OR OT.FacilityId IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @valuestreams) = 0  OR OT.ValueStreamId IN (SELECT field FROM @valuestreams))
			AND ((SELECT Count(1) FROM @salesPerson) = 0  OR TM.OTSName IN (SELECT field FROM @salesPerson))
			AND ((SELECT Count(1) FROM @csr) = 0  OR TM.ITSName IN (SELECT field FROM @csr))
			AND ((SELECT Count(1) FROM @customers) = 0  OR TM.CustomerName IN (SELECT field FROM @customers))
			AND ((SELECT Count(1) FROM @sourceTicketNumbers) = 0  OR TM.SourceTicketId IN (SELECT field FROM @sourceTicketNumbers))
			AND ((SELECT Count(1) FROM @poNumbers) = 0  OR TM.CustomerPO IN (SELECT field FROM @poNumbers))
END
