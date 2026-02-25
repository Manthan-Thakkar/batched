CREATE PROCEDURE [dbo].[spGetTicketHierarchyBulk]
    @ticketNumbers AS UDT_SINGLEFIELDFILTER READONLY
AS
BEGIN
    DECLARE @parentId VARCHAR(510);  -- oldest ancestor
    DECLARE @isTicketDependencyEnabled BIT;
    DECLARE @wcmTicketCategory INT;
    DECLARE @wcmTicketId VARCHAR(510);

    SET NOCOUNT ON;
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
        SELECT  TN.Field AS RequestedTicketId, TM.SourceTicketId AS SourceTicketId, TM.ID AS TicketId, 0 AS TicketCategory, 1 AS ExecutionOrder, 'tbl_ticketHierarchy' AS __dataset_tableName 
        FROM TicketMaster TM
        JOIN @TicketNumbers TN ON
        TN.Field = TM.SourceTicketId
    END
    ELSE
    BEGIN
        DECLARE @RequestTicketNumber NVARCHAR(100);

        DECLARE ticket_cursor CURSOR FOR
        SELECT field FROM @TicketNumbers

        DROP TABLE IF EXISTS #finalResult;

        OPEN ticket_cursor
        FETCH NEXT FROM ticket_cursor
        INTO @RequestTicketNumber

        WHILE @@FETCH_STATUS = 0
        BEGIN

            If OBJECT_ID('tempdb..#ticketHierarchy1') IS NOT NULL
            BEGIN
                truncate table #ticketHierarchy1
            END
            ELSE
            BEGIN
                CREATE TABLE #ticketHierarchy1
                (
                    SourceTicketId NVARCHAR(100),
                    TicketId VARCHAR(36),
                    TicketCategory INT,
                    WCMTicketCategory INT,
                    ExecutionOrder INT,

                )
            END
            If OBJECT_ID('tempdb..#ticketHierarchy2') IS NOT NULL
            BEGIN
                truncate table #ticketHierarchy2
            END
            ELSE
            BEGIN
                    CREATE TABLE #ticketHierarchy2
                (
                    SourceTicketId NVARCHAR(100),
                    TicketId VARCHAR(36),
                    TicketCategory INT,
                    ExecutionOrder INT,
                    WCMTicketCategory INT

                )
            END


            If OBJECT_ID('tempdb..#result') IS NOT NULL
            BEGIN
                TRUNCATE table #result
            END
            ELSE
            BEGIN
                CREATE TABLE #result
                (
                    RequestTicketNumber NVARCHAR(100),
                    TicketId VARCHAR(36),
                    SourceTicketId NVARCHAR(100),
                    TicketCategory INT,
                    WCMTicketCategory INT,
                    ExecutionOrder INT,
                    __dataset_tableName NVARCHAR(1000) 

                )
            END

            If OBJECT_ID('tempdb..#wcmTickets') IS NOT NULL
            BEGIN
                truncate table #wcmTickets
            END
            ELSE
            BEGIN 
                CREATE TABLE #wcmTickets
                (
                    SourceTicketId NVARCHAR(510),
                    TicketId VARCHAR(36),
                    WCMTicketCategory INT
                );
            END 

            ;WITH tblParent AS  --CTE for oldest ancestor
            (
                SELECT SourceTicketId, ID, 1 AS ExecutionOrder
                    FROM TicketMaster TM
                    WHERE TM.SourceTicketId = @RequestTicketNumber
                UNION ALL
                SELECT T1.SourceTicketId, T1.ID, T2.ExecutionOrder + 1 AS ExecutionOrder
                    FROM TicketMaster T1
                    INNER JOIN TicketTaskData ttd ON t1.ID = ttd.TicketId
                    INNER JOIN TicketTaskDependency ttdep ON ttd.Id = ttdep.TicketTaskDataId
                    INNER JOIN TicketTaskData ttd2 ON ttdep.DependentTicketTaskDataId = ttd2.Id
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
                    INNER JOIN TicketTaskData ttd ON t1.ID = ttd.TicketId
                    INNER JOIN TicketTaskDependency ttdep ON ttd.Id = ttdep.DependentTicketTaskDataId
                    INNER JOIN TicketTaskData ttd2 ON ttdep.TicketTaskDataId = ttd2.Id
                    INNER JOIN tblChild T2  
                        ON ttd2.TicketId = T2.TicketId
            )

            INSERT INTO #ticketHierarchy1
            SELECT tc.SourceTicketId, tc.TicketId,
            CASE 
                WHEN tc.TicketCategory = 1 AND (SELECT COUNT(*) FROM tblChild tcc WHERE tcc.TicketCategory = 2) = 0 THEN 0
                ELSE tc.TicketCategory
            END AS TicketCategory, 
            CASE 
                WHEN tsarmt.Id IS NOT NULL AND rmt.Id IS NULL THEN 1 
                WHEN rmt.Id IS NOT NULL AND tsarmt.Id IS NULL THEN 2
                ELSE 0 
            END AS WCMTicketCategory,
            ExecutionOrder
            --'tbl_ticketHierarchy' AS __dataset_tableName 
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



            SELECT TOP 1 @wcmTicketCategory = WCMTicketCategory, @wcmTicketId = TicketId FROM #ticketHierarchy1 WHERE WCMTicketCategory IN (1, 2)

            IF(@wcmTicketCategory = 1)
            BEGIN
                INSERT INTO #wcmTickets
                SELECT 
                    tsatm.SourceTicketId AS SourceTicketId, 
                    tsatm.Id AS TicketId,
                    2 AS WCMTicketCategory
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
                    1 AS WCMTicketCategory
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
                    WHERE TM.SourceTicketId IN (SELECT TOP 1 SourceTicketId FROM #wcmTickets wt WHERE wt.WCMTicketCategory > 0)
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

            INSERT INTO #ticketHierarchy2 SELECT wct.SourceTicketId, wct.TicketId,
            CASE 
                WHEN wct.TicketCategory = 1 AND (SELECT COUNT(*) FROM wcmChildTickets WHERE TicketCategory = 2) = 0 THEN 0
                ELSE wct.TicketCategory
            END AS TicketCategory,
            wct.ExecutionOrder,
            ISNULL(wcmth.WCMTicketCategory, 0) AS WCMTicketCategory
            FROM wcmChildTickets wct
            LEFT JOIN #wcmTickets wcmth ON wct.TicketId = wcmth.TicketId
            GROUP BY wct.SourceTicketId, wct.TicketId, wct.TicketCategory, wct.ExecutionOrder, wcmth.WCMTicketCategory
            ORDER BY wct.ExecutionOrder DESC

            OPTION (maxrecursion 10);

            WITH resultTicketHierarchy AS 
            (
                SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCategory, ExecutionOrder  FROM #ticketHierarchy1
                UNION
                SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCategory, ExecutionOrder FROM #ticketHierarchy2
            )
            INSERT INTO #result SELECT @RequestTicketNumber as RequestTicketNumber, h.TicketId, h.SourceTicketId, h.TicketCategory, h.WCMTicketCategory, h.ExecutionOrder, 'tbl_ticketHierarchy' AS __dataset_tableName
            FROM 
            (
                SELECT TicketId, SourceTicketId, TicketCategory, WCMTicketCategory, ExecutionOrder, ROW_NUMBER() OVER (PARTITION BY TicketId ORDER BY WCMTicketCategory DESC) RNo
                FROM resultTicketHierarchy
            ) h
            WHERE h.RNo = 1
            ORDER BY h.ExecutionOrder DESC;

            If OBJECT_ID('tempdb..#finalResult') IS NOT NULL
            BEGIN
                INSERT INTO #finalResult SELECT * FROM  #result
            END
            ELSE
            BEGIN
                SELECT * INTO #finalResult from #result
            END  

			SET @parentId = NULL;  
			SET @wcmTicketCategory = NULL;
			SET @wcmTicketId = NULL;

            FETCH NEXT FROM ticket_cursor
            INTO @RequestTicketNumber
        END

        SELECT * FROM #finalResult;
        DROP TABLE IF EXISTS #wcmTickets;
        DROP TABLE IF EXISTS #ticketHierarchy1;
        DROP TABLE IF EXISTS #ticketHierarchy2;
        DROP TABLE IF EXISTS #finalResult
        DROP TABLE IF EXISTS #result;

        CLOSE ticket_cursor
        DEALLOCATE ticket_cursor    

    END
END