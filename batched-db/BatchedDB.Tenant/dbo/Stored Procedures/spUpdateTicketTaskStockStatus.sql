CREATE PROCEDURE [dbo].[spUpdateTicketTaskStockStatus]
	@TaskStockStatuses udt_TaskStockStatus READONLY,
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateTicketTaskStockStatus',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly same as 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END
	BEGIN TRANSACTION;

	BEGIN
		SET @blockName = 'Updating task stock and production ready data'; SET @startTime = GETDATE();

		BEGIN TRY	

		UPDATE task
		SET 
			task.TaskStockStatus = tss.TaskStockStatus,
			task.IsProductionReady = tss.IsProductionReady,
			task.ModifiedOn = GETUTCDATE()
		FROM TicketTask_temp task
		INNER JOIN @TaskStockStatuses tss
			ON task.TicketId = tss.TicketId AND task.TaskName = tss.TaskName

		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
		
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@CorelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================

END