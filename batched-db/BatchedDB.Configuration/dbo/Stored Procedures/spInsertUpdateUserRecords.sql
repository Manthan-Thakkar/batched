CREATE PROCEDURE [dbo].[spInsertUpdateUserRecords]
	@TenantId nvarchar(36),
	@Number nvarchar(4000),
	@FirstName nvarchar(4000),
	@LastName nvarchar(4000),
	@E_Mail_Address nvarchar(4000),
	@Phone nvarchar(4000),
	@Inactive bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ClientID nvarchar(max),
			@UserName nvarchar(100),
			@UserCount int,
			@UsernameCount int

	select @ClientID = ClientId from Tenant where ID = @TenantId

	drop table if exists #temp

	select top 0 * 
	into #temp
	from UserAccounts

	insert into #temp
	select UA.* 
	from UserAccounts UA
	inner join TenantUser TU on UA.Id = TU.UserId
	where SourceUserId = @Number and TU.TenantId = @TenantId

	select @UserCount = COUNT(1) from #temp

	IF @UserCount = 0
	BEGIN
		--Generate username
		SET @UserName = UPPER(SUBSTRING(@FirstName,1,1)) + UPPER(SUBSTRING(@LastName,1,1)) + @Number;

		--Find all the records in the UserAccounts table which match the clientId and are like ‘[generatedUserName]%'. Record the count of such records.
		select 
			@UsernameCount = COUNT(1) 
		from UserAccounts UA
		inner join TenantUser TU on UA.Id = TU.UserId
		inner join Tenant T on TU.TenantId = T.ID
		where T.ClientId = @ClientID and (UA.Username = @UserName OR UA.Username like (@UserName + '-%'))

		--If the count is n, where n is greater than zero, then append a dash and n after the [generatedUserId] - as for example MY731-1
		IF @UsernameCount > 0
		BEGIN
			set @UserName = @UserName + '-' + CAST(@UsernameCount as nvarchar(max));
		END

		DECLARE @UserAccountsID nvarchar(36) = NEWID()

		
		INSERT INTO UserAccounts (Id, Username, Password, Scope, Enabled, PromptResetPassword, ModifiedOn, CreatedOn, Source, SourceUserId)
		VALUES (@UserAccountsID, @UserName, NEWID(), 'Tenant', IIF(@Inactive = 1,0,1), 1, GETUTCDATE(), GETUTCDATE(), 'LabelTraxx', @Number);

		INSERT INTO UserProfile (Id, UserId, FirstName, LastName, EmailAddress, PhoneNumber, CreatedOn, ModifiedOn)
		VALUES (NEWID(), @UserAccountsID, @FirstName, @LastName, @E_Mail_Address, @Phone, GETUTCDATE(), GETUTCDATE());

		INSERT INTO TenantUser(ID, TenantId, UserId, CreatedOn, ModifiedOn)
		VALUES (NEWID(), @TenantId, @UserAccountsID, GETUTCDATE(), GETUTCDATE());

		select 0;
	END
	ELSE 
	IF @UserCount = 1
	BEGIN 
		
		--Update the information - first name, last name, email, phone number, inactive/Enabled status
		UPDATE UserProfile 
		SET
			FirstName = @FirstName,
			LastName = @LastName,
			EmailAddress = @E_Mail_Address,
			PhoneNumber = @Phone,
			ModifiedOn = GETUTCDATE()
		WHERE 
			UserId = (select Id from #temp);

		
		UPDATE UserAccounts 
		SET
			Enabled = IIF(@Inactive = 1,0,1),
			ModifiedOn = GETUTCDATE()
		WHERE 
			Id = (select Id from #temp);

		select 1;
	END
	ELSE 
	BEGIN
		select 2;
	END

	


END
