CREATE PROCEDURE [dbo].[spLogCreator]
	@CorelationId			[nvarchar](100),
	@TenantId				[nvarchar](50),
	@SPName					[nvarchar](100),
	@IsError				bit,
	@startTime				datetime,
	@maxCustomMessageSize	int,
	@blockName				[nvarchar](100)  OUTPUT,
	@warningStr				[nvarchar](4000) OUTPUT,
	@errorStr				[nvarchar](4000) OUTPUT,
	@infoStr				[nvarchar](4000) OUTPUT
AS
	DECLARE 
		@returnErrorLog __ErrorInfoLog,
		@status [nvarchar](20),
		@logType [nvarchar](10)

	SET @logType = CASE WHEN @IsError = 1 THEN 'error' WHEN  @warningStr IS NOT NULL AND @warningStr <> ''  THEN 'warning' ELSE 'info' END
	SET @status = CASE WHEN @IsError = 0 THEN 'Commit-Applicable' ELSE 'RolledBack' END; 


	INSERT INTO @returnErrorLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', @status, datediff(ms, @startTime, GETDATE()), 
					GETUTCDATE(), @spName, @blockName, @logType, SUBSTRING(COALESCE(@errorStr, @warningStr, @infoStr, ''), 1, @maxCustomMessageSize))
	
	SET @errorStr = NULL; SET @infoStr = NULL; SET @warningStr = NULL; SET @blockName = 'unknown';
	SELECT * FROM @returnErrorLog
GO