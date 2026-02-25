CREATE PROCEDURE [dbo].[spUpdateUserHashData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spUpdateUserHashData',
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
			SET @blockName = 'Insert New users'; SET @startTime = GETDATE();
			Begin TRY

					--Insert the new users hashvalues added in the associate table
					INSERT INTO UserHashValues (PK_UUID, SourceUserId, HashValue)
					SELECT AT.PK_UUID, AT.Number, AT.HashValue
					FROM [AssociateTemp] AT
					LEFT JOIN UserHashValues UHV
						   ON UHV.PK_UUID = AT.PK_UUID
					WHERE UHV.PK_UUID IS NULL;  -- only new users

					SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)
					-----
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
			SET @blockName = 'Update Existing users'; SET @startTime = GETDATE();
			Begin TRY

					-- UPDATE the existing users hashvalue
					UPDATE UHV
					SET HashValue = A.HashValue
					FROM UserHashValues UHV
					INNER JOIN [AssociateTemp] A
							ON UHV.PK_UUID = A.PK_UUID
					WHERE (UHV.HashValue IS NULL OR A.HashValue <> UHV.HashValue);

					SET @infoStr = 'TotalRowsAffected|' + CONVERT(varchar, @@ROWCOUNT);
					-----
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
