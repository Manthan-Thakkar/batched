CREATE PROCEDURE [dbo].[spInsertUpdateUserRecordsBulk_labelTraxx]
    @UserList     dbo.udt_User READONLY,
    @TenantId     nvarchar(36),
    @CorelationId varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Logging vars
    DECLARE 
        @spName         varchar(100) = 'spInsertUpdateUserRecordsBulk_labelTraxx',
        @__ErrorInfoLog __ErrorInfoLog,
        @maxCustomMessageSize int = 4000,
        @blockName      varchar(100),
        @warningStr     nvarchar(4000),
        @infoStr        nvarchar(4000),
        @errorStr       nvarchar(4000),
        @IsError        bit = 0,
        @startTime      datetime = GETDATE();

    DECLARE @ClientID nvarchar(max);

     --Client ID
	IF @IsError = 0	
		BEGIN		
			SET @blockName = 'GetClientID'; SET @startTime = GETDATE();
			Begin TRY	
				select @ClientID = ClientId from Tenant with(nolock) where ID = @TenantId
				SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

				IF(@ClientID is null or LEN(@ClientID) = 0)
					THROW 50001, 'Client not found for given Tenant.', 0;

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
    -------------------------
    -- Temporary Table with Existing Users
    -------------------------
    DROP TABLE IF EXISTS #ExistingUsers;
    DROP TABLE IF EXISTS  #NewUsers

    SELECT UA.*, TU.TenantId
    INTO #ExistingUsers
    FROM UserAccounts UA WITH (NOLOCK)
    INNER JOIN TenantUser TU WITH (NOLOCK) ON UA.Id = TU.UserId
    INNER JOIN @UserList UL ON UA.SourceUserId = UL.Number
    WHERE TU.TenantId = @TenantId 
    AND UA.Source = 'LabelTraxx';

    -------------------------
    -- Handle Inserts
    -------------------------
    -- Users in @UserList not in #ExistingUsers → Insert
    SELECT 
        NEWID() AS UserId, 
    UL.*, 
    UPPER(LEFT(UL.FirstName, 1)) + UPPER(LEFT(UL.LastName, 1)) + UL.Number AS BaseUsername
    INTO #NewUsers
    FROM @UserList UL
    LEFT JOIN #ExistingUsers EU
        ON EU.SourceUserId = UL.Number
    WHERE EU.SourceUserId IS NULL;


    --Prepopulate the newUsers with their matching UserName count from the unsernames of same client.
    SELECT 
    NU.UserId,
    COUNT(*) AS ExistingCount
    INTO #UserNameCounts
    FROM #NewUsers NU
    JOIN UserAccounts UA WITH (NOLOCK) 
        ON UA.Username = NU.BaseUsername 
           OR UA.Username LIKE NU.BaseUsername + '-%'
    JOIN TenantUser TU WITH (NOLOCK) 
        ON UA.Id = TU.UserId
    JOIN Tenant T WITH (NOLOCK) 
        ON TU.TenantId = T.ID
    WHERE T.ClientId = @ClientID
    GROUP BY NU.UserId;

	INSERT INTO UserAccounts (Id, Username, Password, Scope, Enabled, PromptResetPassword, ModifiedOn, CreatedOn, Source, SourceUserId)
	SELECT 
    NU.UserId,
    -- Username uniqueness logic
    CASE 
        WHEN UC.ExistingCount > 0 
            THEN NU.BaseUsername + '-' + CAST(UC.ExistingCount AS NVARCHAR(10))
        ELSE NU.BaseUsername
    END,
    NEWID(), 
	'Tenant',
    IIF(NU.Inactive = 1, 0, 1)
	, 1, GETUTCDATE(), GETUTCDATE(), 
    'LabelTraxx', NU.Number
    FROM #NewUsers NU
    LEFT JOIN #UserNameCounts UC ON NU.UserId = UC.UserId;

     -- Insert related UserProfile
    INSERT INTO UserProfile (Id, UserId, FirstName, LastName, EmailAddress, PhoneNumber, POPermission,  CreatedOn, ModifiedOn)
    SELECT 
        NEWID(), 
        NU.UserId, 
        NU.FirstName, 
        NU.LastName, 
        NU.E_Mail_Address, 
        NU.Phone, 
        NU.POPermission,
        GETUTCDATE(),
        GETUTCDATE()
    FROM  #NewUsers NU


    -- Insert into TenantUser
    INSERT INTO TenantUser (ID, TenantId, UserId, CreatedOn, ModifiedOn)
    SELECT NEWID(), @TenantId, NU.UserId, GETUTCDATE(), GETUTCDATE()
    FROM #NewUsers NU

    -------------------------
    -- Handle Updates
    -------------------------
    UPDATE UP
    SET 
        FirstName = UL.FirstName,
        LastName = UL.LastName,
        EmailAddress = UL.E_Mail_Address,
        PhoneNumber = UL.Phone,
        POPermission = UL.POPermission,
        ModifiedOn = GETUTCDATE()
    FROM UserProfile UP
    JOIN #ExistingUsers EU ON UP.UserId = EU.Id
    JOIN @UserList UL ON UL.Number = EU.SourceUserId;

    -- Update UserAccounts.Enabled based on @Inactive
    UPDATE UA
    SET 
        Enabled = IIF(UL.Inactive = 1,0,1),
        ModifiedOn = GETUTCDATE()
    FROM UserAccounts UA
    JOIN #ExistingUsers EU ON UA.Id = EU.Id
    JOIN @UserList UL ON UL.Number = EU.SourceUserId; 

    DROP TABLE IF EXISTS #ExistingUsers;
    DROP TABLE IF EXISTS  #NewUsers

    -------------------------
    -- Final Logging
    -------------------------
    IF @IsError = 0
    BEGIN
        INSERT INTO @__ErrorInfoLog
        VALUES(@CorelationId, 'dbLog', @TenantId, 'database', 'Commit-Applicable', 0, GETUTCDATE(), 
               @spName, 'final-commit', 'info', 'message|all users processed');
    END

    SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog;
END
GO
