CREATE PROCEDURE [dbo].[spInsertUpdateUserRecords_Radius]
	@users AS [UDT_USER] readonly,
	-- Standard parameters for all stored procedures	
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spInsertUpdateUserRecords_Radius',
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

	DECLARE @ClientID nvarchar(max)

	--Validate if client id is associated with the tenant Id parameter
	
		IF @IsError = 0	
		BEGIN		
			SET @blockName = 'GetClientID'; SET @startTime = GETDATE();
			Begin TRY		
				
				select @ClientID = ClientId from Tenant with(nolock) where ID = @TenantId


				SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


				--- Invalid ClientID check

				IF(@ClientID is null or LEN(@ClientID) = 0)
					THROW 50001, 'Client not found for given Tenant.', 0;					
				-----
			

			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
				SET @ErrorStr = @ErrorStr + '#ClientNotFound_Tenant|' + @TenantId	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	
	--Identify matching users
	SELECT UA.* 
		INTO #MatchingUserAccounts
		FROM UserAccounts UA WITH(NOLOCK)
		INNER JOIN TenantUser TU WITH(NOLOCK) on UA.Id = TU.UserId AND TU.TenantId = @TenantId AND UA.Source = 'Radius'
		INNER JOIN @users U ON U.Number = UA.SourceUserId

	SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_MatchingUserAccounts|' +  CONVERT(varchar, @@ROWCOUNT)

	--Update matching Users
	IF @IsError = 0
		BEGIN		
			SET @blockName = 'UpdateExistingUser'; SET @startTime = GETDATE();
			Begin TRY		
				
				--Update the information - first name, last name, email, phone number, inactive/Enabled status
				UPDATE UP 
				SET
					FirstName = IIF(U.FirstName IS NULL OR U.FirstName = '', UP.FirstName, U.FirstName),
					LastName = IIF(U.LastName IS NULL OR U.LastName = '', UP.LastName, U.LastName),
					EmailAddress = IIF(U.E_Mail_Address IS NULL OR U.E_Mail_Address = '', UP.EmailAddress, U.E_Mail_Address),
					PhoneNumber = IIF(U.Phone IS NULL OR U.Phone = '', UP.PhoneNumber, U.Phone),
					ModifiedOn = GETUTCDATE()
				from UserProfile UP
				INNER JOIN #MatchingUserAccounts MU ON up.UserId = MU.Id
				INNER JOIN @users U ON U.Number = mu.SourceUserId;
					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserProfile|' +  CONVERT(varchar, @@ROWCOUNT)

				-- This is not required for Radius, users will be Enabled by default always as we don't get the Enabled/Disabled info.
				--UPDATE UA 
				--SET
				--	Enabled = IIF(@Inactive = 1,0,1),
				--	ModifiedOn = GETUTCDATE()
				--from UserAccounts UA
				--INNER JOIN #MatchingUserAccounts MU ON UA.Id = MU.Id
				--INNER JOIN @users U ON U.Number = mu.SourceUserId;
					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserAccounts|' +  CONVERT(varchar, 0)
				
			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

	IF @IsError = 0
		BEGIN		
			SET @blockName = 'InsertNewUser'; SET @startTime = GETDATE();
			Begin TRY	
				SELECT
					U.NUMBER,
					U.FirstName,
					U.LastName,
					U.E_Mail_Address,
					U.Phone,
					U.Inactive
				INTO #NewUserAccounts
				FROM @users u
				WHERE U.Number NOT IN (SELECT SourceUserId from UserAccounts where Source = 'Radius')

				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_NewUserAccounts|' +  CONVERT(varchar, @@ROWCOUNT)

				INSERT INTO UserAccounts (Id, Username, Password, Scope, Enabled, PromptResetPassword, ModifiedOn, CreatedOn, Source, SourceUserId)
					SELECT 
						NEWID(),
						NU.Number,
						NEWID(),
						'Tenant',
						IIF(NU.Inactive = 1,0,1),
						1,
						GETUTCDATE(),
						GETUTCDATE(),
						'Radius',
						NU.Number
					FROM #NewUserAccounts NU

					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserAccounts|' +  CONVERT(varchar, @@ROWCOUNT)

				
				INSERT INTO UserProfile (Id, UserId, FirstName, LastName, EmailAddress, PhoneNumber, CreatedOn, ModifiedOn)
					SELECT 
						NEWID(),
						UA.Id,
						NU.FirstName,
						NU.LastName,
						NU.E_Mail_Address,
						NU.Phone,
						GETUTCDATE(),
						GETUTCDATE()
					FROM #NewUserAccounts NU
					INNER JOIN UserAccounts UA ON NU.Number = UA.SourceUserId AND NU.Number = UA.Username


				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserProfile|' +  CONVERT(varchar, @@ROWCOUNT)

				
				INSERT INTO TenantUser(ID, TenantId, UserId, CreatedOn, ModifiedOn)
				SELECT 
					NEWID(),
					@TenantId,
					UA.Id,
					GETUTCDATE(),
					GETUTCDATE()
					FROM #NewUserAccounts NU
					INNER JOIN UserAccounts UA ON NU.Number = UA.SourceUserId AND NU.Number = UA.Username

				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_TenantUser|' +  CONVERT(varchar, @@ROWCOUNT)


			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
			--	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	DROP TABLE IF exists #MatchingUserAccounts
	DROP TABLE IF EXISTS #NewUserAccounts

--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		--COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END