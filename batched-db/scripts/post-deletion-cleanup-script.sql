USE batched;
DECLARE @DbName VARCHAR(64) = '$(DbName_value)'
PRINT 'Database name: ' + @DbName;
IF EXISTS (SELECT 1 FROM TenantDatabase WHERE DbName = @DbName)
BEGIN
	DECLARE @TenantId VARCHAR(36);
	DECLARE @AgentId VARCHAR(36);
	DECLARE @JobId VARCHAR(36);
	DECLARE @DataSourceId VARCHAR(36);
	DECLARE @OdbcDataSourceQueryId VARCHAR(36);
	DECLARE @S3DataDestinationId VARCHAR(36);
	DECLARE @ScheduleArchiveInfoId VARCHAR(36);

	SELECT @TenantId = TenantId
	FROM TenantDatabase
	WHERE DBname = @DbName;
	
	SELECT @AgentId = Id
	FROM AGENT WHERE TENANTID = @TenantId

	SELECT @JobId = Id
	FROM Job WHERE AgentId = @AgentId

	SELECT @DataSourceId = Id
	FROM DataSource WHERE JobId = @JobId

	SELECT @OdbcDataSourceQueryId = Id
	FROM OdbcDataSourceQuery WHERE DataSourceId = @DataSourceId

	SELECT @S3DataDestinationId = Id
	FROM S3DataDestination WHERE JobId = @JobId

	SELECT @ScheduleArchiveInfoId = Id
	FROM ScheduleArchiveInfo WHERE TenantId = @TenantId

	--Agent and Job Cleanup--
	DELETE FROM S3DataDestination WHERE JobId = @JobId
	
	DELETE FROM OdbcDataSourceQuery WHERE DATASOURCEID = @DataSourceId

	DELETE FROM DataSource WHERE JobId = @JobId

	DELETE JRAI
	FROM JobRunAdditionalInfo JRAI
	inner join jobrun jr on jr.Id =jrai.JobRunId
	where jr.jobId = @JobId


	DELETE FROM JobRun where jobid =@JobId
	
	DELETE From job WHERE agentid =@AgentId

	DELETE FROM AgentSettings WHERE AgentId = @AgentId

	DELETE FROM AGENT WHERE TenantId = @TenantId
	
	-- ScheduleArchive and Event Cleanup
	DELETE FROM ScheduleArchiveStatus where ScheduleArchiveID = @ScheduleArchiveInfoId

	DELETE FROM ScheduleArchiveInfo where TenantId = @TenantId

	DELETE FROM ScheduleEvent WHERE TenantId = @TenantId 

	--PowerBI Cleanup
	DELETE FROM PowerBIConfiguration WHERE TenantId = @TenantId

	--Facility Cleanup
	DELETE FROM Facility WHERE TenantId = @TenantId

	--Tenant User Cleanup
	DELETE FROM TenantUser where TenantId = @TenantId

	--Tenant Clickup
	DELETE FROM TenantDatabase  WHERE TenantId = @TenantId

	DELETE FROM Tenant WHERE ID = @TenantId
END