CREATE PROCEDURE [dbo].[spGetTicketHierarchy]
	@sourceTicketId varchar(510)
AS

BEGIN

    DECLARE @parentId varchar(510);  -- oldest ancestor
    DECLARE @isTicketDependencyEnabled bit;
	DECLARE @wcmTicketCategory int;
	DECLARE @wcmTicketId varchar(510);

    -- Get TicketDependency value
    SELECT @isTicketDependencyEnabled = (CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END)
	FROM TaskRules TR 
	INNER JOIN TaskInfo TI
	ON TR.TaskInfoId = TI.Id
	WHERE TI.IsEnabled = 1 
		AND TR.RuleName = 'EnforceTaskDependency' 
		AND TR.RuleText = 'TRUE' 
	
	-- If ticket TicketDependency is disabled 
    IF(@isTicketDependencyEnabled = 0)
	BEGIN
        SELECT @sourceTicketId AS SourceTicketId, TM.ID AS TicketId, 0 AS TicketCategory, 1 AS ExecutionOrder, 'tbl_ticketHierarchy' AS __dataset_tableName 
			FROM TicketMaster TM
			WHERE TM.SourceTicketId = @sourceTicketId
	END

    ELSE
    -- If ticket TicketDependency is enabled
	BEGIN
		;WITH tblParent AS  --CTE for oldest ancestor
		(
		    SELECT SourceTicketId, ID, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				WHERE TM.SourceTicketId = @sourceTicketId
		    UNION ALL
		    SELECT T1.SourceTicketId, T1.ID, T2.ExecutionOrder + 1 AS ExecutionOrder
		        FROM TicketMaster T1
				inner join TicketTaskData ttd on t1.ID = ttd.TicketId
				inner join TicketTaskDependency ttdep on ttd.Id = ttdep.TicketTaskDataId
				inner join TicketTaskData ttd2 on ttdep.DependentTicketTaskDataId = ttd2.Id
		        INNER JOIN tblParent T2  
		            ON ttd2.TicketId = T2.ID
		)
		
		SELECT @parentId = (SELECT TOP 1 SourceTicketId FROM tblParent ORDER BY ExecutionOrder DESC);
		

		;WITH tblChild AS  --CTE for all @parentId and all children
		(
		     SELECT TM.SourceTicketId, TM.ID AS TicketId, 1 as TicketCategory, TM.DependentSourceTicketId, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				WHERE TM.SourceTicketId = @parentId
		    UNION ALL
		    SELECT T1.SourceTicketId, T1.ID AS TicketId, 2 as TicketCategory, T1.DependentSourceTicketId, ExecutionOrder + 1
		        FROM TicketMaster T1
				inner join TicketTaskData ttd on t1.ID = ttd.TicketId
				inner join TicketTaskDependency ttdep on ttd.Id = ttdep.DependentTicketTaskDataId
				inner join TicketTaskData ttd2 on ttdep.TicketTaskDataId = ttd2.Id
		        INNER JOIN tblChild T2  
		            ON ttd2.TicketId = T2.TicketId
		)
		
		SELECT tc.SourceTicketId, tc.TicketId,
		CASE 
			WHEN tc.TicketCategory = 1 and (SELECT count(*) FROM tblChild tcc WHERE tcc.TicketCategory = 2) = 0 THEN 0
			ELSE tc.TicketCategory
		END AS TicketCategory, 
		CASE 
			WHEN tsarmt.Id IS NOT NULL AND rmt.Id IS NULL THEN 1 
			WHEN rmt.Id IS NOT NULL AND tsarmt.Id IS NULL THEN 2
			ELSE 0 
		END AS WCMTicketCatergory,
		ExecutionOrder
		--'tbl_ticketHierarchy' AS __dataset_tableName 
		INTO #ticketHierarchy1
		FROM tblChild tc
		LEFT JOIN TicketItemInfo tii
			ON tii.TicketId = tc.TicketId
		LEFT JOIN TicketStockAvailabilityRawMaterialTickets tsarmt 
			ON tii.Id = tsarmt.TicketItemInfoId
		LEFT JOIN TicketStockAvailability tsa
			ON tsa.TicketId = tc.TicketId
		LEFT JOIN TicketStockAvailabilityRawMaterialTickets rmt
			ON tsa.Id = rmt.TicketStockAvailabilityId
		GROUP BY tc.SourceTicketId, tc.TicketId, tc.TicketCategory, tc.ExecutionOrder, tsarmt.Id, rmt.Id
		ORDER BY tc.ExecutionOrder DESC

		OPTION (maxrecursion 10);


		SELECT TOP 1 @wcmTicketCategory = WCMTicketCatergory, @wcmTicketId = TicketId FROM #ticketHierarchy1 WHERE WCMTicketCatergory IN (1, 2)

		CREATE TABLE #wcmTickets
		(
			SourceTicketId nvarchar(510),
			TicketId varchar(36),
			WCMTicketCatergory int
		);

		IF(@wcmTicketCategory = 1)
		BEGIN
			INSERT INTO #wcmTickets
			SELECT 
				tsatm.SourceTicketId AS SourceTicketId, 
				tsatm.Id AS TicketId,
				2 AS WCMTicketCatergory
			FROM TicketStockAvailabilityRawMaterialTickets tsarmt
			INNER JOIN TicketItemInfo tti
				ON tsarmt.TicketItemInfoId = tti.Id
			INNER JOIN TicketMaster tm
				ON tti.TicketId = tm.ID
			INNER JOIN TicketStockAvailability tsa
				ON tsarmt.TicketStockAvailabilityId = tsa.Id
			INNER JOIN TicketMaster tsatm
				ON tsa.TicketId = tsatm.Id
			WHERE tm.Id = @wcmTicketId
		END

		ELSE IF (@wcmTicketCategory = 2)

		BEGIN
		INSERT INTO #wcmTickets
			SELECT 
				rmtm.SourceTicketId AS SourceTicketId,
				rmtm.Id AS TicketId,
				1 AS WCMTicketCatergory
			FROM TicketMaster tm
			INNER JOIN TicketStockAvailability tsa
				ON tm.Id = tsa.TicketId
			INNER JOIN TicketStockAvailabilityRawMaterialTickets rmt
				ON tsa.Id = rmt.TicketStockAvailabilityId
			INNER JOIN TicketItemInfo tti 
				ON rmt.TicketItemInfoId = tti.Id
			INNER JOIN TicketMaster rmtm
				ON tti.TicketId = rmtm.ID
			WHERE tm.Id = @wcmTicketId
		END

		;WITH wcmParentTickets AS 
		(
		    SELECT SourceTicketId, ID, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				WHERE TM.SourceTicketId IN (SELECT TOP 1 SourceTicketId FROM #wcmTickets wt WHERE wt.WCMTicketCatergory > 0)
		    UNION ALL
		    SELECT T1.SourceTicketId, T1.ID, T2.ExecutionOrder + 1 AS ExecutionOrder
		        FROM TicketMaster T1
				INNER JOIN TicketTaskData ttd ON t1.ID = ttd.TicketId
				INNER JOIN TicketTaskDependency ttdep ON ttd.Id = ttdep.TicketTaskDataId
				INNER JOIN TicketTaskData ttd2 ON ttdep.DependentTicketTaskDataId = ttd2.Id
		        INNER JOIN wcmParentTickets T2  
		            ON ttd2.TicketId = T2.ID
		)
		
		SELECT @parentId = (SELECT TOP 1 SourceTicketId FROM wcmParentTickets ORDER BY ExecutionOrder DESC);
		

		;WITH wcmChildTickets AS 
		(
		     SELECT TM.SourceTicketId, TM.ID AS TicketId, 1 as TicketCategory, TM.DependentSourceTicketId, 1 AS ExecutionOrder
		        FROM TicketMaster TM
				WHERE TM.SourceTicketId = @parentId
		    UNION ALL
		    SELECT T1.SourceTicketId, T1.ID AS TicketId, 2 as TicketCategory, T1.DependentSourceTicketId, ExecutionOrder + 1
		        FROM TicketMaster T1
				INNER JOIN TicketTaskData ttd ON t1.ID = ttd.TicketId
				INNER JOIN TicketTaskDependency ttdep ON ttd.Id = ttdep.DependentTicketTaskDataId
				INNER JOIN TicketTaskData ttd2 ON ttdep.TicketTaskDataId = ttd2.Id
		        INNER JOIN wcmChildTickets T2  
		            ON ttd2.TicketId = T2.TicketId
		)

		SELECT wct.SourceTicketId, wct.TicketId,
		CASE 
			WHEN wct.TicketCategory = 1 and (SELECT count(*) FROM wcmChildTickets WHERE TicketCategory = 2) = 0 THEN 0
			ELSE wct.TicketCategory
		END AS TicketCategory,
		wct.ExecutionOrder,
		ISNULL(wcmth.WCMTicketCatergory, 0) AS WCMTicketCatergory
		INTO #ticketHierarchy2
		FROM wcmChildTickets wct
		LEFT JOIN #wcmTickets wcmth ON wct.TicketId = wcmth.TicketId
		GROUP BY wct.SourceTicketId, wct.TicketId, wct.TicketCategory, wct.ExecutionOrder, wcmth.WCMTicketCatergory
		ORDER BY wct.ExecutionOrder DESC

		OPTION (maxrecursion 10);


		WITH resultTicketHierarchy AS 
		(
			SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCatergory, ExecutionOrder  FROM #ticketHierarchy1
			UNION
			SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCatergory, ExecutionOrder FROM #ticketHierarchy2
		)

		SELECT h.TicketId, h.SourceTicketId, h.TicketCategory, h.WCMTicketCatergory, h.ExecutionOrder, 'tbl_ticketHierarchy' AS __dataset_tableName 
		FROM 
		(
			SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCatergory, ExecutionOrder, ROW_NUMBER() OVER (PARTITION BY TicketId ORDER BY WCMTicketCatergory DESC) RNo
			FROM resultTicketHierarchy
		) h
		WHERE h.RNo = 1
		ORDER BY h.ExecutionOrder DESC;

		DROP TABLE IF EXISTS #wcmTickets;
		DROP TABLE IF EXISTS #ticketHierarchy1;
		DROP TABLE IF EXISTS #ticketHierarchy2;
	END
END