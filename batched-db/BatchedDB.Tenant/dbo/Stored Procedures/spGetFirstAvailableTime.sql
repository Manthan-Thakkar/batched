CREATE PROCEDURE [dbo].[spGetFirstAvailableTime]
	@ticketItemInfoIds AS udt_singleField readonly
AS
BEGIN 
	
		;WITH tblParent AS 
		(
		    SELECT t.Field AS TicketInfoId, TM.ID AS TicketId, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				INNER JOIN TicketItemInfo tii
				ON TM.ID = tii.TicketId
				INNER JOIN @ticketItemInfoIds t
				ON tii.Id = t.Field
		    UNION ALL
		    SELECT T2.TicketInfoId, T1.ID AS TicketId, T2.ExecutionOrder + 1 AS ExecutionOrder
		        FROM TicketMaster T1
				inner join TicketTaskData ttd on t1.ID = ttd.TicketId
				inner join TicketTaskDependency ttdep on ttd.Id = ttdep.TicketTaskDataId
				inner join TicketTaskData ttd2 on ttdep.DependentTicketTaskDataId = ttd2.Id
		        INNER JOIN tblParent T2  
		            ON ttd2.TicketId = T2.TicketId
		),

		parentTickets AS 
		(
			SELECT * FROM 
			(
				SELECT 
					TicketInfoId,
					TicketId,
					ROW_NUMBER() OVER (PARTITION BY TicketInfoId ORDER BY ExecutionOrder DESC) AS Lvl  
				FROM tblParent
			) h	
			WHERE h.LVL = 1
		),


		 tblChild AS 
		 (
		     SELECT pt.TicketInfoId, TM.ID AS TicketId, 1 AS TicketCategory, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				INNER JOIN parentTickets pt
					ON TM.ID = pt.TicketId
		    UNION ALL
		    SELECT T2.TicketInfoId, T1.ID AS TicketId, 2 AS TicketCategory,  ExecutionOrder + 1
		        FROM TicketMaster T1
				INNER JOIN TicketTaskData ttd ON t1.ID = ttd.TicketId
				INNER JOIN TicketTaskDependency ttdep ON ttd.Id = ttdep.DependentTicketTaskDataId
				INNER JOIN TicketTaskData ttd2 ON ttdep.TicketTaskDataId = ttd2.Id
		        INNER JOIN tblChild T2  
		            ON ttd2.TicketId = T2.TicketId
		),

		shipByTime AS 
		(
			SELECT DISTINCT * FROM 
			(
				SELECT tc.TicketInfoId, DENSE_RANK() OVER (PARTITION BY  tc.TicketInfoId ORDER BY ts.ShipByDateTime DESC) AS RNO, ts.ShipByDateTime AS FirstAvailableTime
				FROM tblChild tc
				LEFT JOIN TicketShipping ts ON
				tc.TicketId = ts.TicketId
			) AS sbt
			WHERE sbt.RNO = 1
		),

		scheduledTicketsShipBy AS 
		(
			SELECT 
				tc.TicketInfoId, 
				CASE
					WHEN COUNT(*) = COUNT(sc.EndsAt) THEN MAX(sc.EndsAt)
					ELSE NULL
				END AS FirstAvailableTime
			FROM tblChild tc
			INNER JOIN TicketMaster tm
				ON TC.TicketId = tm.Id
			LEFT JOIN ScheduleReport sc
				ON tm.SourceTicketId = sc.SourceTicketId
			GROUP BY tc.TicketInfoId
		),

		firstAvailableTime AS (
		SELECT 
			sts.TicketInfoId AS TicketItemInfoId, 
			COALESCE(sts.FirstAvailableTime, sbt.FirstAvailableTime) AS FirstAvailableTime
		FROM scheduledTicketsShipBy sts
		INNER JOIN shipByTime sbt
		ON sts.TicketInfoId = sbt.TicketInfoId
		)

		SELECT 
			fat.TicketItemInfoId, 
			fat.FirstAvailableTime,
			sm.PurchaseOrderLeadTime,
			sm.StockInLeadTime,
			'tbl_firstAvailableTime' AS __dataset_tableName
		FROM firstAvailableTime fat
		INNER JOIN TicketItemInfo tii
		ON fat.TicketItemInfoId = tii.Id
		INNER JOIN ProductMaster pm
		ON pm.Id = tii.ProductId
		INNER JOIN StockMaterial sm
		ON pm.SourceProductId = sm.SourceStockId

END