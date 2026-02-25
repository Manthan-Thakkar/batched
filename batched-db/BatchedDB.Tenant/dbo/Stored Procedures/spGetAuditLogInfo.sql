CREATE PROCEDURE[dbo].[spGetAuditLogInfo]
    @pageNumber AS INT = 1,
    @pageSize AS INT = 10,
    @sortBy AS VARCHAR(100) = '-timestamp',
    @startDate AS DATETIME = NULL,
    @endDate AS DATETIME = NULL
    AS
BEGIN
    DROP TABLE IF EXISTS #auditInfoTemp;
    SELECT @startDate, @endDate
    SELECT
        Id AS Id,
        TimestampUTC AS TimeStampUTC,
        AppName AS AppName,
        ActionType AS ActionType,
        Entity AS Entity,
        Context AS Context,
        Description AS Description,
        UserRole AS UserRole,
        UserName AS UserName,
        COUNT(1) OVER () AS TotalCount,
        'tbl_auditMaster' AS __dataset_tableName
    INTO #auditInfoTemp
    FROM
        AuditMaster
    WHERE
        IsDisabled = 0
        AND  (@startDate IS NULL OR Cast(TimestampUTC AS DATE) >= Cast(@startDate AS DATE))
        AND (@endDate IS NULL OR Cast(TimestampUTC AS DATE) <= Cast(@endDate AS DATE))
    

    SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS RNO INTO #auditMasterSorted FROM #auditInfoTemp

    SELECT 
		Id,
		TimeStampUTC,
		AppName,
		ActionType,
		Entity,
		Context,
		Description,
		UserRole,
		UserName,
		TotalCount,
		__dataset_tableName
	FROM #auditMasterSorted 
    WHERE RNO BETWEEN (@pageNumber -1 ) * @pageSize + 1 AND (((@pageNumber - 1) * @pageSize + 1) + @pageSize) -1
    ORDER BY
            CASE WHEN @sortBy = '+timestamp'  THEN TimestampUTC END ,
            CASE WHEN @sortBy = '-timestamp'  THEN TimestampUTC END DESC


    SELECT
        at.AuditId AS AuditId,
        at.FieldName AS Name,
        at.FieldAction AS Action,
        at.Old AS Old,
        at.New AS New,
        at.DataType AS DataType,
        'tbl_auditTrail' AS __dataset_tableName
    FROM
        #auditMasterSorted ams
    INNER JOIN AuditTrail at
        ON ams.Id = at.AuditId

    -- Get Audit Fields Information
	SELECT 
        af.AuditId, 
        af.Name, 
        STRING_AGG( af.Value, ', ') WITHIN GROUP (ORDER BY af.Value) AS FieldValue,
		af.datatype,
        'tbl_auditFields' AS __dataset_tableName
    FROM 
        #auditMasterSorted am
    INNER JOIN 
        AuditField af
        ON am.Id = af.AuditId
    WHERE RNO BETWEEN (@pageNumber -1 ) * @pageSize + 1 AND (((@pageNumber - 1) * @pageSize + 1) + @pageSize) -1
    GROUP BY af.AuditId,  af.Name, af.DataType

    DROP TABLE IF EXISTS #auditInfoTemp ;
    DROP TABLE IF EXISTS #auditMasterSorted;

END