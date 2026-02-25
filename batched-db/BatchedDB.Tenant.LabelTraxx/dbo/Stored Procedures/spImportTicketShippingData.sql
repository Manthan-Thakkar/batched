CREATE PROCEDURE [dbo].[spImportTicketShippingData]
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
		@spName					varchar(100) = 'spImportTicketShippingData',
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
		SET @blockName = 'PrepTempData'; SET @startTime = GETDATE();

			-- Matching id in temporary table
			SELECT ticMaster.Id as TicketId, tic.Number as TicketNumber
			INTO #MatchingTickets
			from TicketShipping ticPreProc 
			INNER JOIN TicketMaster ticMaster WITH (NOLOCK) ON ticPreProc.TicketId = ticMaster.ID 
			INNER JOIN Ticket tic WITH (NOLOCK) on tic.Number = ticMaster.SourceTicketId

			CREATE NONCLUSTERED INDEX IX_MatchingTickets_TicketNumber ON #MatchingTickets(TicketNumber) INCLUDE (TicketId)
	
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Update Ticket Shipping'; SET @startTime = GETDATE();

		Begin TRY		

		Update ts 
			set
				ShipByDateTime  = tic.Ship_By_Date ,
				ShippedOnDate  = tic.DateShipped ,
				SourceShipAddressId  = tic.Ship_Address_ID ,
				SourceShipVia  = tic.ShipVia,
				DueOnSiteDate  = tic.Due_on_Site_Date,
				ShipState = tic.ShipSt,
				ModifiedOn = GETUTCDATE(),
				ShippingStatus = tic.ShippingStatus,
				ShippingAddress = (CASE
						WHEN tic.ShipAddr2 IS NULL THEN ISNULL(tic.ShipAddr1, '') 
						WHEN tic.ShipAddr1 IS NULL THEN ISNULL(tic.ShipAddr2, '') 
						ELSE (tic.ShipAddr1 + ' ' + tic.ShipAddr2)
					END),					
				ShippingCity = tic.ShipCity,
				ShippingInstruc = tic.ShippingInstruc,
				ShipAttnEmailAddress = tic.ShipAttn_EmailAddress,
				ShipLocation = tic.ShipLocation,
				ShipZip = tic.ShipZip,
				BillLocation = tic.BillLocation,
				BillAddr1 = tic.BillAddr1,
				BillAddr2 = tic.BillAddr2,
				BillCity = tic.BillCity,
				BillZip = tic.BillZip,
				BillCountry = tic.BillCountry,
				BillState = tic.BillState,
				ShipCounty = tic.ShipCounty
			from TicketShipping ts inner join 
			TicketMaster ticMaster WITH (NOLOCK) on ts.TicketId = ticMaster.id
			INNER JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
			INNER JOIN Ticket tic WITH (NOLOCK) ON tic.Number = ticMaster.SourceTicketId AND tic.Number IS NOT NULL
			where @Since IS NULL
			OR tic.UpdateTimeDateStamp >= @Since
			
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Insert Ticket Shipping'; SET @startTime = GETDATE();

		Begin TRY

		-- Insert the new records	
			
			INSERT INTO [dbo].[TicketShipping]([Id],[TicketId],[Source],[ShipByDateTime],[ShippedOnDate],[SourceShipAddressId] ,[SourceShipVia],[DueOnSiteDate],[ShipState],[CreatedOn],[ModifiedOn],[ShippingStatus],[ShippingAddress],[ShippingCity],[ShippingInstruc],[ShipAttnEmailAddress],[ShipLocation],[ShipZip],[BillLocation],[BillAddr1],[BillAddr2],[BillCity],[BillZip],[BillCountry],[BillState],[ShipCounty])  
			SELECT 
			    NEWID(),
				ticMaster.ID,
				'LabelTraxx',
				tic.Ship_By_Date ,
				tic.DateShipped,
				tic.Ship_Address_ID,
				tic.ShipVia,
				tic.Due_on_Site_Date,
				tic.ShipSt,
				GETUTCDATE(),
				GETUTCDATE(),
				tic.ShippingStatus,
				CASE
					WHEN tic.ShipAddr2 IS NULL THEN ISNULL(tic.ShipAddr1, '') 
					WHEN tic.ShipAddr1 IS NULL THEN ISNULL(tic.ShipAddr2, '') 
					ELSE (tic.ShipAddr1 + ' ' + tic.ShipAddr2)
				END,
				tic.ShipCity,
				tic.ShippingInstruc,
				 tic.ShipAttn_EmailAddress,
			    tic.ShipLocation,
				tic.ShipZip,
				 tic.BillLocation,
				 tic.BillAddr1,
				 tic.BillAddr2,
				tic.BillCity,
				tic.BillZip,
				tic.BillCountry,
				tic.BillState,
				tic.ShipCounty
			FROM Ticket tic INNER JOIN TicketMaster ticMaster WITH (NOLOCK) on tic.Number = ticMaster.SourceTicketId
			LEFT JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
			Where mtic.TicketNumber IS NULL

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
				
			-- Delete temporary table
			drop table if exists #MatchingTickets
					   		
	
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