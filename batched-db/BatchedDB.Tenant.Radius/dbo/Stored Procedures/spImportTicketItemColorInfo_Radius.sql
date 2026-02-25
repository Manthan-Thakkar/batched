CREATE PROCEDURE [dbo].[spImportTicketItemColorInfo_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketItemColorInfo_Radius',
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

	SELECT 
		J.CompNum,J.PlantCode,J.JobCode, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
	INTO #PV_Jobs
	FROM PV_job J
		INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
	where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

	select tii.id as ticketItemInfoId, wir.[wi-rc-ink-type], wir.[wi-rc-type], wir.[wi-rc-kinkcode], wir.[wi-rc-side] 
	INTO #ItemColorInfo
	from TicketItemInfo tii
	inner join TicketMaster tm on tii.TicketId = tm.ID
	inner join #PV_Jobs pvj on tm.SourceTicketId = pvj.TicketNumber 
	inner join productmaster pm on tii.ProductId = pm.Id
	inner join [wi-rcoat] wir on pm.SourceProductId = wir.[item-code] and pvj.CompNum = wir.kco and pvj.PlantCode = wir.PlantCode and pvj.JobCode = wir.korder
	WHERE wir.[wi-rc-type] = 'INK'
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		DECLARE @UpdateMissingCount int
		

		SET @blockName = 'UpdateTicketItemColors'; SET @startTime = GETDATE();

		Begin TRY		
			
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
		DECLARE @InsertMissingProductStockProductCount int
		DECLARE @InsertMissingTicketMasterCount int
		SET @blockName = 'InsertTicketItemColorsItems'; SET @startTime = GETDATE();

		truncate table TicketItemColorInfo;

		Begin TRY
		-- Insert the new records
		INSERT INTO [dbo].[TicketItemColorInfo] ([Id]  ,[TicketItemInfoId],[CoatingType],[SourceInkType],
		[SourceInk],[CoatSide],[CreatedOnUTC],[ModifiedOnUTC])
		   SELECT 
				NEWID(),
				ticItemColorInfo.ticketItemInfoId,
				ticItemColorInfo.[wi-rc-type],
				ticItemColorInfo.[wi-rc-ink-type],
				ticItemColorInfo.[wi-rc-kinkcode],
				ticItemColorInfo.[wi-rc-side],
				GETDATE(),
				GETDATE()
			FROM #ItemColorInfo ticItemColorInfo
		
		--- Set info string for total rows affected
		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		----

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
		drop table if exists #PV_Jobs
		drop table if exists #ItemColorInfo
	
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