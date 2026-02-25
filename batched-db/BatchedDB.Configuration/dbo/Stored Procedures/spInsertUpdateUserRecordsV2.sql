CREATE PROCEDURE [dbo].[spInsertUpdateUserRecordsV2]
	@Number nvarchar(4000),
	@FirstName nvarchar(4000),
	@LastName nvarchar(4000),
	@E_Mail_Address nvarchar(4000),
	@Phone nvarchar(4000),
	@Inactive bit,
	-- Standard parameters for all stored procedures	
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spInsertUpdateUserRecordsV2',
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

	DECLARE @ClientID nvarchar(max),
			@UserName nvarchar(100),
			@UserCount int,
			@UsernameCount int

	--BEGIN TRANSACTION;
	
	--Client ID
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
	
	
	drop table if exists #temp

	select top 0 * 
	into #temp
	from UserAccounts
	
	
	--Temp Table
	IF @IsError = 0	
		BEGIN		
			SET @blockName = 'InsertIntoTemporaryTable'; SET @startTime = GETDATE();
			Begin TRY		
				


				insert into #temp
				select UA.* 
				from UserAccounts UA with(nolock)
				inner join TenantUser TU with(nolock) on UA.Id = TU.UserId
				where SourceUserId = @Number and TU.TenantId = @TenantId


				SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


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
	

	
	select @UserCount = COUNT(1) from #temp

	--Insert New User
	IF @IsError = 0	AND @UserCount = 0 
		BEGIN		
			SET @blockName = 'InsertNewUser'; SET @startTime = GETDATE();
			Begin TRY		
				
				--Generate username
				SET @UserName = UPPER(SUBSTRING(@FirstName,1,1)) + UPPER(SUBSTRING(@LastName,1,1)) + @Number;

				--Find all the records in the UserAccounts table which match the clientId and are like ‘[generatedUserName]%'. Record the count of such records.
				select 
					@UsernameCount = COUNT(1) 
				from UserAccounts UA with(nolock)
				inner join TenantUser TU with(nolock) on UA.Id = TU.UserId
				inner join Tenant T with(nolock) on TU.TenantId = T.ID
				where T.ClientId = @ClientID and (UA.Username = @UserName OR UA.Username like (@UserName + '-%'))

				--If the count is n, where n is greater than zero, then append a dash and n after the [generatedUserId] - as for example MY731-1
				IF @UsernameCount > 0
				BEGIN
					set @UserName = @UserName + '-' + CAST(@UsernameCount as nvarchar(max));
				END

				DECLARE 
					@UserAccountsID nvarchar(36) = NEWID()


				INSERT INTO UserAccounts (Id, Username, Password, Scope, Enabled, PromptResetPassword, ModifiedOn, CreatedOn, Source, SourceUserId)
				VALUES (@UserAccountsID, @UserName, NEWID(), 'Tenant', IIF(@Inactive = 1,0,1), 1, GETUTCDATE(), GETUTCDATE(), 'LabelTraxx', @Number);

					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserAccounts|' +  CONVERT(varchar, @@ROWCOUNT)

				
				INSERT INTO UserProfile (Id, UserId, FirstName, LastName, EmailAddress, PhoneNumber, CreatedOn, ModifiedOn)
				VALUES (NEWID(), @UserAccountsID, @FirstName, @LastName, @E_Mail_Address, @Phone, GETUTCDATE(), GETUTCDATE());

				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserProfile|' +  CONVERT(varchar, @@ROWCOUNT)

				
				INSERT INTO TenantUser(ID, TenantId, UserId, CreatedOn, ModifiedOn)
				VALUES (NEWID(), @TenantId, @UserAccountsID, GETUTCDATE(), GETUTCDATE());

				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_TenantUser|' +  CONVERT(varchar, @@ROWCOUNT)

				
				select 0 status, 'tbl_User' as __dataset_tableName;

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
	
	
	IF @IsError = 0	AND @UserCount = 1 
		BEGIN		
			SET @blockName = 'UpdateExistingUser'; SET @startTime = GETDATE();
			Begin TRY		
				
				--Update the information - first name, last name, email, phone number, inactive/Enabled status
				UPDATE UserProfile 
				SET
					FirstName = IIF(@FirstName IS NULL OR @FirstName = '', FirstName, @FirstName),
					LastName = IIF(@LastName IS NULL OR @LastName = '', LastName, @LastName),
					EmailAddress = IIF(@E_Mail_Address IS NULL OR @E_Mail_Address = '', EmailAddress, @E_Mail_Address),
					PhoneNumber = IIF(@Phone IS NULL OR @Phone = '', PhoneNumber, @Phone),
					ModifiedOn = GETUTCDATE()
				WHERE 
					UserId = (select Id from #temp);
					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserProfile|' +  CONVERT(varchar, @@ROWCOUNT)

		
				UPDATE UserAccounts
				SET
					Enabled = IIF(Enabled = 0, 0 ,IIF(@Inactive = 1,0,1)),
					ModifiedOn = GETUTCDATE()
				WHERE 
					Id = (select Id from #temp);
					
				SET @infoStr = COALESCE( @infoStr,'') + '#TotalRowsAffected_UserAccounts|' +  CONVERT(varchar, @@ROWCOUNT)

				select 1 status, 'tbl_User' as __dataset_tableName;				
				
			

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
	
	
	IF @IsError = 0	AND @UserCount > 1
		BEGIN		
			SET @blockName = 'InconsistentUserCheck'; SET @startTime = GETDATE();
			Begin TRY		
				
				select 2 status, 'tbl_User' as __dataset_tableName;				
				
				THROW 50001, 'Inconsistent User found.', 1;	

			END TRY
			Begin CATCH
	--		==================================[Do not change]================================================
				SET @IsError = 1; --Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
	--		=======================[Concate more error strings after this]===================================
				SET @ErrorStr = @ErrorStr + '#InconsistentUser_Number|'+ Convert(varchar, @Number)
			END CATCH
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

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