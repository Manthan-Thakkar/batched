CREATE PROCEDURE [dbo].[spGetOrderStatusKPI]
    @startDate					AS DATETIME = NULL,
    @endDate					AS DATETIME = NULL,
    @facilities					AS UDT_SINGLEFIELDFILTER readonly,
    @valuestreams				AS UDT_SINGLEFIELDFILTER readonly,
    @customers					AS UDT_SINGLEFIELDFILTER readonly,
    @csr						AS UDT_SINGLEFIELDFILTER readonly,
    @salesPerson				AS UDT_SINGLEFIELDFILTER readonly,
    @sourceTicketNumbers		AS UDT_SINGLEFIELDFILTER readonly,
    @poNumbers					AS UDT_SINGLEFIELDFILTER readonly,
	@TicketStatuses				AS UDT_SINGLEFIELDFILTER readonly,
	@CorelationId				AS VARCHAR(36) = NULL,
	@TenantId					AS VARCHAR(36) = NULL
AS
BEGIN
	DECLARE
		@spName					VARCHAR(100) = 'spGetOrderStatusKPI',
		@totalTickets           INT,
		@lateTickets			INT,
		@atRiskTickets			INT,
		@onTimeTickets			INT,
		@behindTickets	        INT,
		@unscheduled			INT;

	WITH OpenTicketsData AS (
	SELECT distinct TicketId, EM.FacilityId, EVS.ValueStreamId
	FROM TicketTask TT WITH (NOLOCK)--- All the tickets which have generated Ticket tasks pass the applicability rule by default
	INNER JOIN EquipmentMaster EM WITH (NOLOCK) ON TT.OriginalEquipmentId = EM.Id
	LEFT JOIN EquipmentValueStream EVS ON EVS.EquipmentId = EM.ID
 	),
	-- Latest task times calculation
	WaitingForShipping as (
		SELECT  TicketId 
		FROM TicketTask with (nolock) group by TicketId having count(1) = sum(cast( iscomplete as int))
	)

	SELECT 
		OT.TicketId,
		CASE
			WHEN US.TicketId IS NOT NULL then 'Unscheduled'  --- Unscheduled
			WHEN TW.TicketId IS NOT NULL then TW.TicketStatus  --- Scheduled worst case status
			WHEN WS.TicketId is not null then 
			       CASE WHEN GETDATE() <= TS.ShipByDateTime THEN 'On Track'
				   ELSE 'Late' END     -- waiting for shipping but assigning status based on its ship by date
			ELSE Tm.SourceStatus 
		END AS TicketStatus
		INTO #OrderStatusTicketData
		FROM OpenTicketsData OT 
		INNER JOIN TicketMaster TM with(nolock) on OT.TicketId = TM.ID
		INNER JOIN TicketShipping TS WITH(NOLOCK) ON OT.TicketId = TS.TicketId
		LEFT JOIN dbo.[view_ticketWorstCaseStatus] TW on Ot.TicketId = TW.TicketId
		LEFT JOIN dbo.[view_TicketTaskRaw] US on OT.TicketId = US.TicketId -- Unscheduled tickets
		LEFT JOIN WaitingForShipping WS on OT.TicketId = WS.TicketId
		WHERE (@startDate IS NULL OR TS.ShipByDateTime >= @startDate) 
			AND (@endDate IS NULL OR TS.ShipByDateTime <= @endDate)
			AND	((SELECT Count(1) FROM @facilities) = 0  OR OT.FacilityId IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @valuestreams) = 0  OR OT.ValueStreamId IN (SELECT field FROM @valuestreams))
			AND ((SELECT Count(1) FROM @salesPerson) = 0  OR TM.OTSName IN (SELECT field FROM @salesPerson))
			AND ((SELECT Count(1) FROM @csr) = 0  OR TM.ITSName IN (SELECT field FROM @csr))
			AND ((SELECT Count(1) FROM @customers) = 0  OR TM.CustomerName IN (SELECT field FROM @customers))
			AND ((SELECT Count(1) FROM @sourceTicketNumbers) = 0  OR TM.SourceTicketId IN (SELECT field FROM @sourceTicketNumbers))
			AND ((SELECT Count(1) FROM @poNumbers) = 0  OR TM.CustomerPO IN (SELECT field FROM @poNumbers))
			
	SELECT @totalTickets = COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses))

	SELECT @lateTickets = COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData 
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses))
			AND TicketStatus = 'Late' 

	SELECT @atRiskTickets = COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData 
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses)) 
			AND TicketStatus = 'At Risk' 

	SELECT @onTimeTickets = COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData 
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses)) 
			AND TicketStatus = 'On Track' 

	SELECT @behindTickets= COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData 
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses)) 
			AND TicketStatus = 'Behind' 

	SELECT @unscheduled = COUNT(DISTINCT(TicketId)) FROM #OrderStatusTicketData 
	WHERE ((SELECT Count(1) FROM @TicketStatuses) = 0  OR TicketStatus IN (SELECT field FROM @TicketStatuses)) 
			AND TicketStatus = 'Unscheduled' 

	DROP TABLE IF EXISTS #OrderStatusTicketData

	SELECT 
		@totalTickets AS TotalTickets,
		@lateTickets AS LateTickets,
		@atRiskTickets AS AtRiskTickets,
		@onTimeTickets AS OnTimeTickets,
		@behindTickets AS BehindTickets,
		@unscheduled AS UnscheduledTickets,
		'tbl_orderStatusKpi' AS __dataset_tableName

END