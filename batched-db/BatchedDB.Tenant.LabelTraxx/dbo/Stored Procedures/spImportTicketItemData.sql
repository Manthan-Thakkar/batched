CREATE PROCEDURE [dbo].[spImportTicketItemData]
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
		@spName					varchar(100) = 'spImportTicketItemData',
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
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN

		SET @blockName = 'Prep Matching Ticket Items'; SET @startTime = GETDATE();		
					
			-- Matching id in temporary table
			SELECT ticItemInfo.Id as TicketItemId, ticitem.ID as SourceTicketItemId
			INTO #MatchingTicketItems
			FROM TicketItem ticitem INNER JOIN TicketItemInfo ticItemInfo
			ON ticitem.ID = ticItemInfo.SourceTicketItemId  AND ticitem.ID IS NOT NULL

			CREATE NONCLUSTERED INDEX IX_MatchingTicketItems_SourceTicketItemId ON #MatchingTicketItems(SourceTicketItemId)
			CREATE NONCLUSTERED INDEX IX_MatchingTicketItems_TicketItemId ON #MatchingTicketItems(TicketItemId)

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
				
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN

		SET @blockName = 'UpdateTicketItems'; SET @startTime = GETDATE();

		Begin TRY		
					-- Update the records
			Update TicketItemInfo 
			set
			    ProductId = pMstr.Id,
				StockProductId = spMstr.Id,
				NumColors = ticitem.NoColors,
				OrderQuantity = ticitem.Orderquantity,
				ModifiedOn = GETUTCDATE(),
				WorkStatus = ticitem.WORK_STATUS,
				MachineCount = ticitem.MACHINECOUNT,
				SalesOrderNumber = null,
				SalesOrderDate = null
			from 
			TicketItemInfo ticItemInfo INNER JOIN #MatchingTicketItems mtic ON ticItemInfo.Id = mtic.TicketItemId
			INNER JOIN TicketItem ticitem ON ticitem.ID = ticItemInfo.SourceTicketItemId AND ticitem.Id IS NOT NULL
			LEFT JOIN StockProductMaster spMstr ON ticitem.STOCKPRODUCTID = spMstr.SourceStockProductId 
			LEFT JOIN ProductMaster pMstr ON ticitem.UNIQUEPRODID = pMstr.SourceProductId
			where @Since IS NULL
			OR ticitem.UpdateTimeDateStamp >= @Since
			OR spMstr.ModifiedOn >= @Since
			OR pMstr.ModifiedOn >= @Since
			
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
		SET @blockName = 'InsertTicketItems'; SET @startTime = GETDATE();

		Begin TRY
		-- Insert the new records
		INSERT INTO [dbo].[TicketItemInfo] ([Id]  ,[TicketId],[ProductId],[StockProductId],[NumColors],[OrderQuantity],[SourceTicketItemId],[CreatedOn],[ModifiedOn],[WorkStatus], [MachineCount], [SalesOrderNumber], [SalesOrderDate])
		   SELECT 
				NEWID(),
				ticMstr.ID,
				pMstr.Id,
				spMstr.Id,
				ticItem.Nocolors,
				ticItem.Orderquantity,
				ticItem.ID,
				GETUTCDATE(),
				GETUTCDATE(),
				ticItem.WORK_STATUS,
				ticItem.MachineCount,
				null,	-- SalesOrderNumber
				null	-- SalesOrderDate
			FROM TicketItem ticItem LEFT JOIN StockProductMaster spMstr
			ON ticitem.STOCKPRODUCTID = spMstr.SourceStockProductId 
			LEFT JOIN ProductMaster pMstr ON ticitem.UNIQUEPRODID = pMstr.SourceProductId
			INNER JOIN TicketMaster ticMstr ON ticMstr.SourceTicketId = ticItem.Ticketnumber
			LEFT JOIN #MatchingTicketItems mtic ON ticItem.ID = mtic.SourceTicketItemId
			Where mtic.SourceTicketItemId IS NULL
			and ticItem.ID IS NOT NULL
		-------

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
		drop table if exists #MatchingTicketItems
		drop table if exists #NullStockProductProduct	   		
	
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
