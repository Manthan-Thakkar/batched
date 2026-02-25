CREATE PROCEDURE [dbo].[spImportCustomerMasterData]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100),
	@Since DateTime = NULL
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportCustomerMasterData',
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

	
	-- DUPLICATE CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'DuplicateCustomerCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) Number
					FROM Customer 
					GROUP BY Number
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicate_Customer_Number|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;
			END
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullCustomerCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM Customer WHERE Number IS NULL
			)
			SET @infoStr = 'TotalNullRecords_Customer_UniqueSourceNumber|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
				SET @infoStr = NULL;
			END
		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END


	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	
	
	SELECT C.Number, C.Company, C.DistributorNum, C.MFGRepNum, C.Notes, C.Sales_Rep_No, C.Cust_Serv_No,C.Customer,c.Distributor, c.OTSName,c.ITSName,c.Inactive,c.PopUpName1,c.PK_UUID,c.UpdateTimeDateStamp
		INTO #MatchingCustomers
		FROM Customer C INNER JOIN CustomerMaster CM
		ON C.Number = CM.SourceCustomerID AND C.Number IS NOT NULL
		WHERE CM.Source = 'LabelTraxx'

	BEGIN
		SET @blockName = 'UpdateCustomerMaster'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE CM 
			SET 
				CM.SourceCustomerID = C.Number,
				CM.CustomerName = C.Company,
				CM.Source = 'LabelTraxx',
				CM.DistributorNumber = C.DistributorNum,
				CM.ManufacturingRepNumber = C.MFGRepNum,
				CM.Notes = C.Notes,
				CM.SourceSalespersonID = C.Sales_Rep_No,
				CM.SourceCustomerServicePersonID = C.Cust_Serv_No,
				CM.IsCustomer = C.Customer,
				CM.IsDistributor = C.Distributor,
				CM.Salesperson = C.OTSName,
				CM.CustomerServicePerson = C.ITSName,
				CM.IsActive = (case when C.Inactive = 0 then 1 else 0 end),
				CM.CustomField1 = C.PopUpName1,
				CM.SourceRecordId = C.PK_UUID,
				CM.CreatedOn = GETUTCDATE(),
				CM.ModifiedOn = GETUTCDATE(),
				CM.CustomerGroup = NULL
			FROM CustomerMaster CM
			INNER JOIN #MatchingCustomers C ON CM.SourceCustomerID = C.Number where C.Number IS NOT NULL
			AND (@Since IS NULL OR C.UpdateTimeDateStamp >= @Since)

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertCustomerMaster'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO CustomerMaster
			([Id], [SourceCustomerID],[CustomerName],[Source],[DistributorNumber],
			[ManufacturingRepNumber],[Notes],[SourceSalespersonID],[SourceCustomerServicePersonID],
			[IsCustomer],[IsDistributor],[Salesperson],[CustomerServicePerson],[IsActive],
			[CustomField1],[SourceRecordId],
			[CreatedOn],[ModifiedOn], [CustomerGroup])
			SELECT 
				NEWID() ID,
				C.Number, --SourceCustomerID
				C.Company, -- CustomerName
				'LabelTraxx',-- Source
				C.DistributorNum,-- DistributorNumber
				C.MFGRepNum,-- ManufacturingRepNumber
				C.Notes,-- Notes
				C.Sales_Rep_No,-- SourceSalespersonID
				C.Cust_Serv_No, -- SourceCustomerServicePersonID
				C.Customer, -- IsCustomer
				C.Distributor, -- IsDistributor
				C.OTSName, -- Salesperson
				C.ITSName, -- CustomerServicePerson
				(case when C.Inactive = 0 then 1 else 0 end),-- IsActive
				C.PopUpName1, -- CustomField1
				C.PK_UUID, -- SourceRecordId
				GETUTCDATE(), -- CreatedOn
				GETUTCDATE(), -- ModifiedOn,
				NULL -- CustomerGroup
			FROM Customer C 
			WHERE ( C.Number NOT IN (select CustomerMaster.SourceCustomerID From CustomerMaster))
			AND C.Number IS NOT NULL

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)
			drop table #MatchingCustomers
		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================


END
