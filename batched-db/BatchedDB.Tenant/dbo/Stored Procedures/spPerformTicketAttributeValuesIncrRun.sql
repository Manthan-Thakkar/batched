CREATE PROCEDURE [dbo].[spPerformTicketAttributeValuesIncrRun]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100),
	@TicketStockAttributeIncrRun bit = 0 --Incr run is executed for stock attributes then this will 1
AS	
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spPerformTicketAttributeValuesIncrRun',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END
	
	
	IF @IsError = 0	
	BEGIN
		BEGIN TRANSACTION
		SET @blockName = 'Incremental Run TicketAttributeValues_temp'; SET @startTime = GETDATE();
		BEGIN TRY			
			IF(@TicketStockAttributeIncrRun = 0) --Incr run is executed for stock attributes then do not trucate the _temp tables
			BEGIN
				TRUNCATE TABLE TicketAttributeValues_temp;

				INSERT INTO TicketAttributeValues_temp(
					ID, TicketId, Name, Value, DataType, CreatedOn, ModifiedOn
					) 
				SELECT 
					ID, TicketId, Name, Value, DataType, CreatedOn, ModifiedOn
				FROM TicketAttributeValues;
			END;

			MERGE INTO TicketAttributeValues_temp AS tavt
			USING TicketAttributeValues_Incr AS tavi
			ON tavt.TicketId = tavi.TicketId AND tavi.Name = tavt.Name 
			WHEN MATCHED THEN
			    UPDATE SET
			        tavt.ModifiedOn = GETUTCDATE(),
			        tavt.Value = tavi.Value,
			        tavt.DataType = tavi.DataType
					WHEN NOT MATCHED BY TARGET THEN
			    INSERT (ID, TicketId, Name, Value, DataType, CreatedOn, ModifiedOn)
			    VALUES (tavi.ID, tavi.TicketId, tavi.Name, tavi.Value, tavi.DataType, tavi.CreatedOn, tavi.ModifiedOn);
			
		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		END TRY

		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH

		SET @blockName = 'Delete from TicketAttributeValues_Temp'; SET @startTime = GETDATE();
		BEGIN TRY		
		
		DELETE FROM TicketAttributeValues_temp where id in
		(select id from TicketAttributeValues_temp where TicketId not in 
			(SELECT tm.ID from TicketMaster tm
			INNER JOIN TicketShipping ts on tm.id = ts.TicketId
			LEFT JOIN LastJobsRun ljr on tm.SourceTicketId = ljr.Ticket_No
			WHERE
			tm.SourceTicketType <> 0
			AND
			((tm.IsOpen = 1 and ts.ShipByDateTime >= GETUTCDATE()-181)
			OR ts.ShippedOnDate >= GETUTCDATE()-3
			OR ljr.Ticket_No is not null)))	


		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		END TRY
		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

		IF @IsError = 0
		BEGIN
			COMMIT TRANSACTION;
		END

		IF @IsError = 0
		BEGIN
			INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
				@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
		END
		
		SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
	END
END