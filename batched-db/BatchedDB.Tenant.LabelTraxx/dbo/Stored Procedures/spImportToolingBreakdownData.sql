CREATE PROCEDURE [dbo].[spImportToolingBreakdownData]
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportToolingBreakdownData',
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

	
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertToolingBreakdown'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
            DELETE FROM ToolingInventoryBreakdown --replace with update statement

			insert into ToolingInventoryBreakdown(Id,ToolingNumber,FacilityId,ToolingId,CreatedOnUTC,ModifiedOnUTC)
			select 
				NEWID() ID,
				ti.SourceToolingId + '_' + REPLACE(STR(t2.number + 1), ' ', ''),
				null,
				ti.Id,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn
			from 
				ToolingInventory ti
			JOIN master.dbo.spt_values t2 ON t2.type = 'P' AND t2.number < ti.availablequantity
			
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (select COUNT(1) from Tooling where Number not in (select SourceToolingId from ToolingInventory where Source = 'LabelTraxx') and Number is null)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Tooling_Number|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
				SET @infoStr = null;
			END

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	end

--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END
