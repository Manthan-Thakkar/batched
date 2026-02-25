CREATE VIEW [dbo].[view_OrderStatusTicketDetail]
AS	
    WITH OpenTicketsData as (
	SELECT distinct TicketId, f.Id as FacilityId
	FROM TicketTask TT WITH (NOLOCK)--- All the tickets which have generated Ticket tasks pass the applicability rule by default
	INNER JOIN EquipmentMaster EM WITH (NOLOCK) ON TT.OriginalEquipmentId = EM.Id
	LEFT JOIN Facility f with (nolock) ON em.FacilityId = f.ID
 	),
	-- Latest task times calculation
	WaitingForShipping as (
		SELECT  TicketId 
		FROM TicketTask with (nolock) group by TicketId having count(1) = sum(cast( iscomplete as int))
	)

	SELECT 
		OT.TicketId,
		TM.SourceTicketId as TicketNumber,
		CASE
			WHEN US.TicketId is not null then 'Unscheduled'  --- Unscheduled
			WHEN TW.TicketId is not null then TW.TicketStatus  --- Scheduled worst case status
			WHEN WS.TicketId is not null then 'Waiting to Ship' --- Done but waiting for shipping
			ELSE Tm.SourceStatus 
		END as TicketStatus,
		TM.CustomerName as Customer,
		TM.CustomerPO as PONumber,
		TM.ITSName as CSR,
		TS.ShipByDateTime as ShipByDate,
		TL.LatestTaskTime as EstCompletionDate,
		Tm.GeneralDescription as GeneralDescription,
		TD.Quantity  as OrderedQuantity,
		TD.ActualQuantity  as ShippedQuantity,
		tm.EstTotalRevenue as RemainingSaleAmt,
		TM.OTSName as SalesRep,
		OT.FacilityId as FacilityId,
		'tbl_orderStatusDetail' AS __dataset_tableName

		from OpenTicketsData OT 
		INNER JOIN TicketMaster TM with(nolock) on OT.TicketId = TM.ID
		INNER JOIN TicketShipping TS with(nolock) on OT.TicketId = TS.TicketId
		LEFT JOIN TicketDimensions TD on OT.TicketId = TD.TicketId
		LEFT JOIN dbo.[view_ticketWorstCaseStatus] TW on Ot.TicketId = TW.TicketId
		LEFT JOIN  dbo.[view_LatestTaskTimes] TL on OT.TicketId =  TL.TicketId
		LEFT JOIN dbo.[view_TicketTaskRaw] US on OT.TicketId = US.TicketId -- Unscheduled tickets
		LEFT JOIN WaitingForShipping WS on OT.TicketId = WS.TicketId
GO