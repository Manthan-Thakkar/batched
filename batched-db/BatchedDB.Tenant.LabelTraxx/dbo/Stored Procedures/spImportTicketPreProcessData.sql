CREATE PROCEDURE [dbo].[spImportTicketPreProcessData]
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
		@spName					varchar(100) = 'spImportTicketPreProcessData',
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
	-- Matching id in temporary table
			SELECT ticMaster.Id as TicketId, tic.Number as TicketNumber
			INTO #MatchingTickets
			from TicketPreProcess ticPreProc 
			INNER JOIN TicketMaster ticMaster ON ticPreProc.TicketId = ticMaster.ID 
			INNER JOIN Ticket tic on tic.Number = ticMaster.SourceTicketId
			WHERE ticMaster.Source = 'LabelTraxx' AND ticMaster.TenantId = @TenantId
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTicketPreProcess'; SET @startTime = GETDATE();
		Begin TRY		
					-- Update the records
			Update TicketPreProcess 
			set
				ArtWorkComplete = tic.ArtDone,
				ProofComplete = tic.ProofDone,
				PlateComplete = tic.PlateDone,
				ToolsReceived = tic.ToolsIn,
				InkReceived = tic.Is_Ink_In ,
				StockReceived = tic.StockIn ,
				ModifiedOn = GETUTCDATE(),
				ArtStatus = tic.ArtStat,
				ProofStatus = tic.ProofStat,
				ToolStatus = tic.ToolStat
			from
			TicketPreProcess ts inner join 
			TicketMaster ticMaster on ts.TicketId = ticMaster.id
			INNER JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
			INNER JOIN Ticket tic ON tic.Number = ticMaster.SourceTicketId AND tic.Number IS NOT NULL
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
		SET @blockName = 'InsertTicketPreProcess'; SET @startTime = GETDATE();
		Begin TRY
			-- Insert the new records
			INSERT INTO [dbo].[TicketPreProcess] ([TicketId] ,[ArtWorkComplete] ,[ProofComplete]  ,[PlateComplete] ,[ToolsReceived] ,[InkReceived],[StockReceived],[CreatedOn],[ModifiedOn], [ArtStatus],[ProofStatus],[ToolStatus])
		   SELECT 
				ticMaster.ID,
				tic.ArtDone,
				tic.ProofDone,
				tic.PlateDone,
				tic.ToolsIn,
				tic.Is_Ink_In,
				tic.StockIn,
				GETUTCDATE(),
				GETUTCDATE(),
				tic.ArtStat,
				tic.ProofStat,
				tic.ToolStat
			FROM Ticket tic INNER JOIN TicketMaster ticMaster on tic.Number = ticMaster.SourceTicketId
			Where tic.Number not in (select TicketNumber from #MatchingTickets) 
			and tic.Number IS NOT NULL
			
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

