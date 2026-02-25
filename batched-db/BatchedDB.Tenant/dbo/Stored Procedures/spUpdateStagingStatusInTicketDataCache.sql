CREATE PROCEDURE [dbo].[spUpdateStagingStatusInTicketDataCache]
  @TicketIds      AS UDT_SINGLEFIELDFILTER READONLY,
  @CorelationId		AS VARCHAR(40) = NULL,
  @TenantId				AS VARCHAR(40) = NULL
AS
BEGIN
  DECLARE 
		@spName							    VARCHAR(100) = 'spUpdateStagingStatusInTicketDataCache',
    @Columns                NVARCHAR(MAX),
		@__ErrorInfoLog			    __ErrorInfoLog,
		@warningStr					    NVARCHAR(4000),
		@infoStr						    NVARCHAR(4000),
		@errorStr						    NVARCHAR(4000),
		@maxCustomMessageSize   INT = 4000,
		@startTime					    DATETIME,
		@blockName					    VARCHAR(100),
		@IsError						    BIT = 0,
    @StagingColumns         NVARCHAR(MAX),
    @StagingQuery           NVARCHAR(MAX);

  DROP TABLE IF EXISTS #TempWorkcenterStagingRequirement;
  DROP TABLE IF EXISTS #TempStagingData;
  DROP TABLE IF EXISTS #TempStagingStatusData;

  SET @blockName = 'stagingStatusData';
  SET @startTime = GETDATE();
  -- Create a temp table to store the staging status data
  CREATE TABLE #TempStagingStatusData
  (
    [TicketId] VARCHAR(36),
    [TaskName] NVARCHAR(255),
    [StagingStatus] VARCHAR(36)
  );

  -- Create a temp table to store the staging requirements wrt workcenters
  SELECT
    SRG.WorkcenterTypeId,
    STRING_AGG(CONCAT('Is', REPLACE(SRQ.Name, ' ', ''), 'Staged'), ',') AS StagingReq
  INTO #TempWorkcenterStagingRequirement
  FROM StagingRequirementGroup SRG
    INNER JOIN StagingRequirement SRQ ON SRG.StagingRequirementId = SRQ.Id
  GROUP BY SRG.WorkcenterTypeId;

  -- Get comma separated names of boolean columns 
  SELECT @Columns = STRING_AGG(COLUMN_NAME , ',')
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

  -- Get comma separated names of boolean columns with status conditions
  SELECT @StagingColumns = STRING_AGG(CONCAT('CASE WHEN WSR.StagingReq IS NULL THEN NULL WHEN WSR.StagingReq LIKE ''%', COLUMN_NAME, '%'' THEN COALESCE(', COLUMN_NAME, ', 0) ELSE NULL END AS ', COLUMN_NAME), ',')
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

  -- Create a dynamic query to populate the temp table of staging status
  SET @StagingQuery =
            'SELECT
                TM.Id AS TicketId,
				TT.TaskName AS TaskName,
                WSR.StagingReq,
                '+@StagingColumns+'
            INTO #TempStagingData
            FROM TicketTask TT
                INNER JOIN TicketMaster TM ON TT.TicketId = TM.Id
                INNER JOIN EquipmentMaster EM ON TT.OriginalEquipmentId = EM.ID
                LEFT JOIN #TempWorkcenterStagingRequirement WSR ON EM.WorkcenterTypeId = WSR.WorkcenterTypeId
                LEFT JOIN TicketTaskStagingInfo TTS ON TM.ID = TTS.TicketId AND TT.TaskName = TTS.Taskname
			WHERE TT.IsComplete = 0 
            
            INSERT INTO #TempStagingStatusData
            SELECT 
                TicketId,
				TaskName,
                CASE
                    WHEN ' + REPLACE(@Columns, ',', ' IS NULL AND ') + ' IS NULL THEN ''Staged''
                    WHEN COALESCE(' + REPLACE(@Columns, ',', ', 1) = 1 AND COALESCE(') + ', 1) = 1 THEN ''Staged''
                    WHEN COALESCE(' + REPLACE(@Columns, ',', ', 0) = 0 AND COALESCE(') + ', 0) = 0 THEN ''Unstaged''
                    ELSE ''Partially Staged''
                END AS StagingStatus
            FROM #TempStagingData;'

  -- Execute the dynamic query to populate temp table of staging status
  EXEC sp_executesql @StagingQuery;

  UPDATE SMC
			SET SMC.StagingStatus = TSS.StagingStatus
			FROM TicketDataCache SMC
    JOIN #TempStagingStatusData TSS ON SMC.TicketId = TSS.TicketId AND SMC.TaskName = TSS.TaskName
			WHERE SMC.TicketId IN (SELECT Field
  FROM @TicketIds);

  INSERT @__ErrorInfoLog
  EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

END;