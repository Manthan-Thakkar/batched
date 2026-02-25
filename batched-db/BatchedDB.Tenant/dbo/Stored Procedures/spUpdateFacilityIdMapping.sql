CREATE PROCEDURE [dbo].[spUpdateFacilityIdMapping]
	-- Standard parameters for all stored procedures
	@TenantId		varchar(36),
	@CorelationId	varchar(100),
	@facilityInfo	udt_FacilityInfo READONLY
AS
BEGIN

	SET NOCOUNT ON;
		BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateFacilityIdMapping',
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
		SET @blockName = 'StockInventory'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			UPDATE StockInventory
			SET
				FacilityId = fi.FacilityId,
				ModifiedOn = GETUTCDATE()
			FROM @facilityInfo fi
			INNER JOIN StockInventory si 
				ON fi.SourceFacilityId = si.FacilityId

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END


	IF @IsError = 0	
	BEGIN
		SET @blockName = 'PurchaseOrderItem'; SET @startTime = GETDATE();
		BEGIN TRY			
			
			UPDATE PurchaseOrderItem
			SET
				FacilityId = fi.FacilityId,
				ModifiedOnUTC = GETUTCDATE()
			FROM @facilityInfo fi
			INNER JOIN PurchaseOrderItem poi 
				ON fi.SourceFacilityId = poi.FacilityId

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END
