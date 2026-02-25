CREATE PROCEDURE [dbo].[spGetWorkcenterMaterialTicketsStatus]
	@ticketIds AS UDT_TICKETINFO READONLY
AS
BEGIN 
	
		;WITH workcenterMaterialConsumingTickets AS 
		(
			SELECT est.TicketId, 
			CASE 
				WHEN est.EstTimeOfArrival > est.FirstTaskDueDateTime THEN 0 
				ELSE 1 
			END AS IsCompletingOnTime
			FROM
			(
				SELECT 
					DISTINCT tsa.TicketId, 
					tsa.FirstAvailableTime AS EstTimeOfArrival,
					ROW_NUMBER() OVER(PARTITION BY tsa.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
					tt.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM TicketStockAvailability tsa
				INNER JOIN TicketStockAvailabilityRawMaterialTickets tsarmt
					ON tsa.Id = tsarmt.TicketStockAvailabilityId
				INNER JOIN TicketTask tt
					ON tsa.TicketId = tt.TicketId
				WHERE ((SELECT Count(1) FROM @ticketIds) = 0  OR tsa.TicketId IN (SELECT TicketId FROM @ticketIds))
			) est
			WHERE est.Rno = 1
		)

		SELECT 
			TicketId,
			IsCompletingOnTime, 
			2 AS WorkcenterMaterialTicketCategory,
			'tbl_wcmConsumingTicketsStatus' as __dataset_tableName
		FROM workcenterMaterialConsumingTickets;
		
		WITH wcmPTArrivalTime AS
		(
			SELECT TicketId, EstTimeOfArrival 
			FROM 
			(
				SELECT
					tti.TicketId AS TicketId,
					ROW_NUMBER() OVER(PARTITION BY tti.TicketId ORDER BY tsa.FirstAvailableTime DESC) AS Rno,
					tsa.FirstAvailableTime AS EstTimeOfArrival
				FROM TicketStockAvailabilityRawMaterialTickets rmt
				INNER JOIN TicketItemInfo tti 
					ON rmt.TicketItemInfoId = tti.Id
				INNER JOIN TicketStockAvailability tsa
					ON rmt.TicketStockAvailabilityId = tsa.Id
				WHERE ((SELECT Count(1) FROM @ticketIds) = 0  OR tti.TicketId IN (SELECT TicketId FROM @ticketIds))
			) t
			WHERE  t.Rno = 1
		),
		workcenterMaterialProducingTickets AS
		(
			SELECT 
				DISTINCT TicketId,  
				CASE 
					WHEN t.EstTimeOfArrival > t.FirstTaskDueDateTime THEN 0 
					ELSE 1 
				END AS IsCompletingOnTime
			FROM
			(
				SELECT 
					pt.TicketId, 
					pt.EstTimeOfArrival,  
					ROW_NUMBER() OVER(PARTITION BY pt.TicketId ORDER BY tt.EstMaxDueDateTime) AS Rno,
					tt.EstMaxDueDateTime AS FirstTaskDueDateTime
				FROM wcmPTArrivalTime pt
				INNER JOIN TicketItemInfo tii
					ON pt.TicketId = tii.TicketId
				INNER JOIN TicketStockAvailabilityRawMaterialTickets rmt
					ON tii.Id = rmt.TicketItemInfoId
				INNER JOIN TicketStockAvailability tsa
					ON rmt.TicketStockAvailabilityId = tsa.Id
				INNER JOIN TicketTask tt
					ON tsa.TicketId = tt.TicketId
			) t
			WHERE t.Rno = 1
		)

		SELECT
			TicketId,
			IsCompletingOnTime,
			1 AS WorkcenterMaterialTicketCategory,
			'tbl_wcmProducingTicketsStatus' as __dataset_tableName
		FROM workcenterMaterialProducingTickets;
END