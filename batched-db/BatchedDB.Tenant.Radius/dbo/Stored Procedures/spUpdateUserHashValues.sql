CREATE PROCEDURE [dbo].[spUpdateUserHashValues_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateUserHashValues_Radius',
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
	
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	
	IF @IsError = 0	
		BEGIN		
			SET @blockName = 'Insert new users'; SET @startTime = GETDATE();
			Begin TRY	

					--Insert the new users hashvalues added in the PM_users table
					INSERT INTO UserHashValues (SourceRecordId, HashValue)
					SELECT PU.TableRecId, PU.[HashValue]
					FROM PM_User_Temp PU
					LEFT JOIN UserHashValues UHV
						   ON UHV.[SourceRecordId] = PU.TableRecId
					WHERE UHV.[SourceRecordId] IS NULL;  -- only new users
				  
			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

		IF @IsError = 0	
		BEGIN		
			SET @blockName = 'Update existing users'; SET @startTime = GETDATE();
			Begin TRY	

					-- UPDATE the existing users hashvalue
					UPDATE UHV
					SET HashValue = PU.HashValue
					FROM UserHashValues UHV
					INNER JOIN PM_User_Temp PU
							ON UHV.[SourceRecordId] = PU.TableRecId
					WHERE (UHV.HashValue IS NULL OR PU.HashValue <> UHV.HashValue);

					SET @infoStr = 'TotalRowsAffected|' + CONVERT(varchar, @@ROWCOUNT);
				  
			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	
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


