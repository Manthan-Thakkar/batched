CREATE PROCEDURE [dbo].[spImportTicketShippingData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
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
		SET @blockName = 'Prep Data to Populate Temp Table'; SET @startTime = GETDATE();

		-- #PV_Jobs temp table WITH concatenated ticket number
		SELECT 
			J.*,JC.JobCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
		INTO #PV_Jobs
		FROM PV_job J
			INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
		where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9


	-- Matching id in temporary table
			--SELECT ticMaster.Id as TicketId, tic.TicketNumber as TicketNumber
			--INTO #MatchingTickets
			--from TicketShipping ticPreProc 
			--INNER JOIN TicketMaster ticMaster ON ticPreProc.TicketId = ticMaster.ID 
			--INNER JOIN #PV_Jobs tic on tic.TicketNumber = ticMaster.SourceTicketId
			--WHERE ticMaster.Source = 'Radius' AND ticMaster.TenantId = @TenantId


	;with TicketShippingPreDataCalc as(		SELECT distinct
			j.TicketNumber as TicketNumber, 
			sr.ActualShipDate ,
			SO.ShipAddrNum,
			sr.CarrierCode,
			so.CustReqDate,
			shipad.County as ShippingCounty,
			SR.ShipReqStat,
			shipad.DisplayAddress as ShippingAddress,
			shipad.Town as ShippingCity,
			sr.ShipReqText,
			shipad.Email,
			shipad.DisplayAddress  as ShipLocation,
			shipad.PostCode as ShipZip,
			billad.DisplayAddress as BillLocation,
			billad.Address1 as Address1,
			billad.Address2 as Address2,
			billAd.Town as BillCity,
			billad.PostCode as BillZip,
			billad.Country as BillCounrty,
			billad.County as BillState,
			ROW_NUMBER() OVER(PARTITION BY j.jobcode,j.plantcode,j.compnum ORDER BY sr.ShipDate DESC ) AS row_number --- need to revisit this

			
			 from #PV_Jobs j
			 INNER JOIN PV_JobSOLink jsol on j.CompNum = jsol.CompNum and j.PlantCode = jsol.PlantCode and j.JobCode = jsol.JobCode
			INNER JOIN PV_ShipReqLine srl on srl.SOrderNum = jsol.SOrderNum and srl.CompNum = jsol.CompNum and srl.SOPlantCode = jsol.SOPlantCode and srl.SOrderLineNum = jsol.SOrderLineNum
			INNER JOIN PV_SOrder so on jsol.CompNum = so.CompNum and jsol.SOPlantCode = so.PlantCode and jsol.SOrderNum = so.SOrderNum 
			INNER JOIN PV_ShipReq sr on sr.ShipReqNum = srl.ShipReqNum and sr.CompNum = srl.CompNum and sr.PlantCode = srl.PlantCode 
			LEFT JOIN PV_Address shipad on shipad.AddressNum = sr.ShipAddrNum  
			LEFT JOIN PV_Address billad on billad.AddressNum = sr.BillAddrNum  )

			select *  into #TicketShippingPreData from TicketShippingPreDataCalc  where row_number =1
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Update Ticket Shipping'; SET @startTime = GETDATE();

		Begin TRY		

		--Update ts 
		--	set
		--		ShipByDateTime  = tic.ReqHaveReadyDate ,
		--		ShippedOnDate  = TSPreData.ActualShipDate ,
		--		SourceShipAddressId  = TSPreData.ShipAddrNum ,
		--		SourceShipVia  = TSPreData.CarrierCode,
		--		DueOnSiteDate  = TSPreData.CustReqDate,
		--		ShipState = TSPreData.ShippingCounty,
		--		ModifiedOn = GETUTCDATE(),
		--		ShippingStatus = (CASE WHEN  TSPreData.ShipReqStat = 0 THEN 'Not started '
		--							WHEN TSPreData.ShipReqStat = 1 THEN 'Generated'
		--							WHEN TSPreData.ShipReqStat = 2 THEN 'Printed'
		--							WHEN TSPreData.ShipReqStat = 3 THEN 'Picked'
		--							WHEN TSPreData.ShipReqStat = 4 THEN 'Confirmed'
		--							WHEN TSPreData.ShipReqStat = 5 THEN 'Shipped'
		--							ELSE null END),
		--		ShippingAddress = TSPreData.ShippingAddress,					
		--		ShippingCity = TSPreData.ShippingCity,
		--		ShippingInstruc = TSPreData.ShipReqText,
		--		ShipAttnEmailAddress = TSPreData.Email,
		--		ShipLocation = TSPreData.ShipLocation ,
		--		ShipZip = TSPreData.ShipZip,
		--		BillLocation = TSPreData.BillLocation,
		--		BillAddr1 = TSPreData.Address1,
		--		BillAddr2 = TSPreData.Address2,
		--		BillCity = TSPreData.BillCity,
		--		BillZip = TSPreData.BillZip,
		--		BillCountry = TSPreData.BillCounrty,
		--		BillState = TSPreData.BillState,
		--		ShipCounty = TSPreData.ShippingCounty
		--	from TicketShipping ts inner join 
		--	TicketMaster ticMaster on ts.TicketId = ticMaster.id
		--	INNER JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
		--	INNER JOIN #PV_Jobs tic ON  tic.TicketNumber = ticMaster.SourceTicketId AND tic.JobCode IS NOT NULL
		--	LEFT join #TicketShippingPreData TSPreData on  tic.TicketNumber  = TSPreData.TicketNumber
			
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
			Truncate Table TicketShipping

			INSERT INTO [dbo].[TicketShipping]([Id],[TicketId],[Source],[ShipByDateTime],[ShippedOnDate],[SourceShipAddressId] ,[SourceShipVia],[DueOnSiteDate],[ShipState],[CreatedOn],[ModifiedOn],[ShippingStatus],[ShippingAddress],[ShippingCity],[ShippingInstruc],[ShipAttnEmailAddress],[ShipLocation],[ShipZip],[BillLocation],[BillAddr1],[BillAddr2],[BillCity],[BillZip],[BillCountry],[BillState],[ShipCounty])  
			SELECT 
			    NEWID(),
				ticMaster.ID,
				'Radius',
				tic.ReqHaveReadyDate ,
				TSPreData.ActualShipDate,
				TSPreData.ShipAddrNum,
				TSPreData.CarrierCode,
				TSPreData.CustReqDate,
				TSPreData.ShippingCounty,
				GETUTCDATE(),
				GETUTCDATE(),
				(CASE WHEN  TSPreData.ShipReqStat = 0 THEN 'Not started '
									WHEN TSPreData.ShipReqStat = 1 THEN 'Generated'
									WHEN TSPreData.ShipReqStat = 2 THEN 'Printed'
									WHEN TSPreData.ShipReqStat = 3 THEN 'Picked'
									WHEN TSPreData.ShipReqStat = 4 THEN 'Confirmed'
									WHEN TSPreData.ShipReqStat = 5 THEN 'Shipped'
									ELSE null END),
				TSPreData.ShippingAddress,
				TSPreData.ShippingCity,
				TSPreData.ShipReqText,
				 TSPreData.Email,
			    TSPreData.ShipLocation,
				TSPreData.ShipZip,
				 TSPreData.BillLocation,
				 TSPreData.Address1,
				 TSPreData.Address2,
				TSPreData.BillCity,
				TSPreData.BillZip,
				TSPreData.BillCounrty,
				TSPreData.BillState,
				TSPreData.ShippingCounty
			FROM #PV_Jobs tic INNER JOIN TicketMaster ticMaster on  tic.TicketNumber = ticMaster.SourceTicketId
			LEFT join #TicketShippingPreData TSPreData on tic.TicketNumber = TSPreData.TicketNumber
			Where tic.JobCode IS NOT NULL
			--Where tic.TicketNumber  not in (select TicketNumber from #MatchingTickets) 
			--and tic.JobCode IS NOT NULL

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
			drop table if exists #PV_Jobs
					   		
	
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