CREATE PROCEDURE [dbo].[spPerformChangeoverMinutesIncrRun]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN
	SET NOCOUNT ON;

	BEGIN
		--	==============================logging variables (do not change)=======================================
			DECLARE 
				@spName					varchar(100) = 'spPerformChangeoverMinutesIncrRun',
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
		SET @blockName = 'Incremental Run ChangeoverMinutes_temp'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			TRUNCATE TABLE ChangeoverMinutes_temp;

			INSERT INTO ChangeoverMinutes_temp(
				ID, TicketIdFrom, TicketIdTo, EquipmentId, ChangeoverMinutes, SavedChangeoverMinutes, CreatedOn, ModifiedOn, Count, Description
				) 
			SELECT 
				ID, TicketIdFrom, TicketIdTo, EquipmentId, ChangeoverMinutes, SavedChangeoverMinutes, CreatedOn, ModifiedOn, Count, Description
			FROM ChangeoverMinutes;

			MERGE INTO ChangeoverMinutes_temp AS cmt
			USING ChangeoverMinutes_Incr AS cmi
			ON cmt.TicketIdFrom = cmi.TicketIdFrom AND cmt.TicketIdTo = cmi.TicketIdTo AND cmt.EquipmentId = cmi.EquipmentId
			WHEN MATCHED THEN
			    UPDATE SET
			        cmt.ChangeoverMinutes = cmi.ChangeoverMinutes,
					cmt.SavedChangeoverMinutes = cmi.SavedChangeoverMinutes,
					cmt.ModifiedOn = GETUTCDATE(),
					cmt.Count = cmi.Count,
					cmt.Description = cmi.Description
			WHEN NOT MATCHED BY TARGET THEN
			    INSERT (ID, TicketIdFrom, TicketIdTo, EquipmentId, ChangeoverMinutes, SavedChangeoverMinutes, CreatedOn, ModifiedOn, Count, Description)
			    VALUES (cmi.ID, cmi.TicketIdFrom, cmi.TicketIdTo, cmi.EquipmentId, cmi.ChangeoverMinutes, cmi.SavedChangeoverMinutes, cmi.CreatedOn, cmi.ModifiedOn, cmi.Count, cmi.Description);
		
		SET @infoStr = 'TotalRowsAffected|' +  CONVERT(VARCHAR, @@ROWCOUNT)
		
		END TRY
		
		BEGIN CATCH
			ROLLBACK;
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH

		
		SET @blockName = 'Delete from ChangeoverMinutes_temp'; SET @startTime = GETDATE();
		BEGIN TRY		
		
		IF EXISTS (select 1 from TicketTask_Temp)
		BEGIN		
		DELETE FROM ChangeoverMinutes_temp where id in (select ID from ChangeoverMinutes_Temp where TicketIdFrom not in (select distinct ticketid from TicketTask_temp)
			OR TicketIdFrom not in (select distinct ticketid from TicketTask_temp))	
		END

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