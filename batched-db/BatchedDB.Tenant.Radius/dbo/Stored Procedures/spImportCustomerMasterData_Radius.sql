CREATE PROCEDURE [dbo].[spImportCustomerMasterData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportCustomerMasterData_Radius',
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
		SET @blockName = 'DuplicatePV_CustomerCheck'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					SELECT COUNT(1) CustCode
					FROM PV_Customer 
					GROUP BY CustCode
					HAVING COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicate_PV_Customer_Number|' +  CONVERT(varchar, @duplicateRecs);
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
		SET @blockName = 'NullPV_Customer'; SET @startTime = GETDATE();
		BEGIN TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM PV_Customer where CustCode IS NULL
			)
			SET @infoStr = 'TotalNullRecords_PV_Customer_CustCode|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
				SET @infoStr = NULL;
			END
		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END



	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS

	SELECT C.CustCode, C.CustName, C.notes, C.MonSalesAgentID, C.CustStatus, C.TableRecId, C.CustGroup
		INTO #MatchingCustomers
		FROM PV_Customer C INNER JOIN CustomerMaster CM
		ON C.CustCode = CM.SourceCustomerID AND C.CustCode IS NOT NULL
		WHERE CM.Source = 'Radius'

	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateCustomerMaster'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE CM 
			SET 
				CM.SourceCustomerID = MCus.CustCode,
				CM.CustomerName = MCus.CustName,
				CM.Source = 'Radius',
				CM.Notes = MCus.notes,
				CM.SourceSalespersonID = MCus.MonSalesAgentID,
				CM.IsCustomer = (case when MCus.CustStatus in ('0','1','2') then 1 else 0 end),
				CM.IsDistributor = 0,
				CM.Salesperson = U.UserName,
				CM.IsActive = (case when MCus.CustStatus = 0 then 1 else 0 end),
				CM.SourceRecordId = MCus.TableRecId,
				CM.CustomerGroup = MCus.CustGroup
			FROM CustomerMaster CM
			INNER JOIN #MatchingCustomers MCus ON CM.SourceCustomerID = MCus.CustCode
			INNER JOIN PM_User U ON MCus.MonSalesAgentID = U.UserCode
			Where MCus.CustCode IS NOT NULL

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
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
			
			INSERT INTO CustomerMaster([Id],[SourceCustomerID],[CustomerName],
			[Source],[DistributorNumber],[ManufacturingRepNumber],[Notes],[SourceSalespersonID],
			[SourceCustomerServicePersonID], [IsCustomer],[IsDistributor],[Salesperson],
			[CustomerServicePerson],[IsActive],[CustomField1],[SourceRecordId],[CreatedOn], [ModifiedOn], [CustomerGroup])
			SELECT 
				NEWID() ID, --Id
				C.CustCode, --SourceCustomerID
				C.CustName, --CustomerName
				'Radius',	--Source
				null,		--DistributorNumber
				null,		--ManufacturingRepNumber
				C.notes,	--Notes
				C.MonSalesAgentID, --SourceSalespersonID
				null,		--SourceCustomerServicePersonID
				(case when C.CustStatus in ('0','1','2') then 1 else 0 end),--IsCustomer
				0,			--IsDistributor,
				U.UserName,	--Salesperson
				null,		--CustomerServicePerson
				(case when C.CustStatus = 0 then 1 else 0 end),--IsActive
				null,		--CustomField1
				C.TableRecId, --SourceRecordId
				GETUTCDATE(), --CreatedOn
				GETUTCDATE(), --ModifiedOn
				C.CustGroup --CustomerGroup
			FROM 
				PV_Customer C
				LEFT JOIN PM_User U on C.MonSalesAgentID = U.UserCode
				WHERE ( C.CustCode NOT IN (select CustomerMaster.SourceCustomerID From CustomerMaster))
				AND C.CustCode IS NOT NULL
				
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
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

