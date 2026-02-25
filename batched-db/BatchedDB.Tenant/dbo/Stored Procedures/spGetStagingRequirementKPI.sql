CREATE PROCEDURE [dbo].[spGetStagingRequirementKPI]
    @startDate			AS DATETIME = NULL,
    @endDate			AS DATETIME = NULL,
    @equipments			AS UDT_SINGLEFIELDFILTER readonly,
    @facilities			AS UDT_SINGLEFIELDFILTER readonly,
    @ticketNumbers		AS UDT_SINGLEFIELDFILTER readonly,
    @workcenters		AS UDT_SINGLEFIELDFILTER readonly,
    @valuestreams		AS UDT_SINGLEFIELDFILTER readonly,
	@components			AS UDT_SINGLEFIELDFILTER readonly,
	@CorelationId		AS VARCHAR(36) = NULL,
	@TenantId			AS VARCHAR(36) = NULL
AS
BEGIN
	DECLARE
		@spName					VARCHAR(100) = 'spGetStagingRequirementKPI',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000,
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME,
		@query					NVARCHAR(MAX);


	DROP TABLE IF EXISTS #TempStagingData;
	DROP TABLE IF EXISTS #TempWorkcenterStagingRequirement;
	DROP TABLE IF EXISTS #TempSchedule;


	SET @blockName = 'Create and Populate Temp Table - TempStagingData'; SET @startTime = GETUTCDATE();

		CREATE TABLE #TempStagingData
		(
			TicketId VARCHAR(36),
			Taskname VARCHAR(36),
			StagingNameKey VARCHAR(36),
			IsStaged BIT NULL
		);

		SELECT @query = 'INSERT INTO #TempStagingData ' + STRING_AGG(CONCAT('SELECT TicketId, Taskname, ''', column_name, ''' as [StagingNameKey], ', column_name, ' as [IsStaged] FROM TicketTaskStagingInfo'), ' UNION ALL ')
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE table_name = 'TicketTaskStagingInfo' AND DATA_TYPE = 'bit';

		EXEC sp_executesql @query;

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;



	SET @blockName = 'Create Temp Table - TempWorkcenterStagingRequirement'; SET @startTime = GETUTCDATE();

		SELECT
			SRG.WorkcenterTypeId,
			STRING_AGG(CONCAT('Is', REPLACE(SRQ.Name, ' ', ''), 'Staged'), ', ') AS StagingReq
		INTO #TempWorkcenterStagingRequirement
		FROM StagingRequirementGroup SRG
			INNER JOIN StagingRequirement SRQ ON SRG.StagingRequirementId = SRQ.Id
		GROUP BY SRG.WorkcenterTypeId;
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;



	SET @blockName = 'Create Temp Table - TempSchedule'; SET @startTime = GETUTCDATE();

		SELECT
			TM.ID AS TicketId,
			SR.SourceTicketId AS TicketNumber,
			SR.TaskName,
			EM.WorkcenterTypeId,
			SR.StartsAt,
			SR.EndsAt
		INTO #TempSchedule
		FROM ScheduleReport SR
			INNER JOIN TicketMaster TM ON SR.SourceTicketId = TM.SourceTicketId
			INNER JOIN EquipmentMaster EM ON SR.EquipmentId = EM.ID
			LEFT JOIN EquipmentValueStream EVS ON SR.EquipmentId = EVS.EquipmentId
			LEFT JOIN StagingRequirementGroup SRG ON EM.WorkcenterTypeId = SRG.WorkcenterTypeId
		WHERE ((SELECT Count(1) FROM @equipments) = 0 OR SR.EquipmentId IN (SELECT field FROM @equipments))
			AND ((SELECT Count(1) FROM @facilities) = 0 OR EM.FacilityId IN (SELECT field FROM @facilities))
			AND ((SELECT Count(1) FROM @workcenters) = 0 OR EM.WorkcenterTypeId IN (SELECT field FROM @workcenters))
			AND ((SELECT Count(1) FROM @ticketNumbers) = 0 OR SR.SourceTicketId IN (SELECT field FROM @ticketNumbers))
			AND ((SELECT Count(1) FROM @valuestreams) = 0 OR EVS.ValueStreamId IN (SELECT field FROM @valuestreams))
			AND ((SELECT Count(1) FROM @components) = 0 OR SRG.StagingRequirementId IN (SELECT field FROM @components))
			AND (@startDate IS NULL OR @startDate <= SR.EndsAt)
			AND (@endDate IS NULL OR @endDate >= SR.StartsAt)
		GROUP BY TM.ID, SR.SourceTicketId, SR.TaskName, EM.WorkcenterTypeId, SR.StartsAt, SR.EndsAt;

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;


	
	SET @blockName = 'Final data'; SET @startTime = GETUTCDATE();

		SELECT
				TS.TicketId,
				TS.TicketNumber,
				TS.TaskName,
				TTS.StagingNameKey,
				CASE
					WHEN 
						TWS.StagingReq IS NOT NULL AND
						TTS.StagingNameKey IS NOT NULL AND
						TTS.IsStaged IS NULL AND
						TWS.StagingReq LIKE '%'+TTS.StagingNameKey+'%' 
					THEN 0
					ELSE TTS.IsStaged
				END AS IsStaged,
				TWS.StagingReq,
				TS.StartsAt,
				TS.EndsAt,
				'tbl_StagingRequirement_FinalData' AS __dataset_tableName
			FROM #TempSchedule TS
				LEFT JOIN #TempWorkcenterStagingRequirement TWS ON TS.WorkcenterTypeId = TWS.WorkcenterTypeId
				LEFT JOIN #TempStagingData TTS ON TS.TicketId = TTS.TicketId AND TS.TaskName = TTS.Taskname;

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;


	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;

END