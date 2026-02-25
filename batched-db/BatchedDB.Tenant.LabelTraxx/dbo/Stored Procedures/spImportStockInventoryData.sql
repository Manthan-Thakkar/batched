CREATE PROCEDURE spImportStockInventoryData
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
		@spName					varchar(100) = 'spImportStockInventoryData',
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
	
	DROP TABLE IF EXISTS #TempRollStock

	IF @IsError = 0	
		BEGIN
		SET @blockName = 'PrepareMatchingRollStock'; SET @startTime = getdate();

	Declare @FacilityId varchar(36) = (SELECT TOP 1 [ID] FROM [dbo].[Facility] WITH(NOLOCK)
			WHERE [IsEnabled] = 1 ORDER BY [CreatedOnUTC]);

	CREATE TABLE #TempRollStock(
		[PK_UUID] NVARCHAR(4000), 
		[Width] REAL, 
		[StkDate] DATETIME, 
		[DateRollUsed] DATETIME, 
		[StkUsed] BIT,
		[Location] NVARCHAR(4000),
		[FootLength] INT,
		[CreatedDate] DATETIME,
		[StockNum] NVARCHAR(4000),
		[FacilityID] VARCHAR(36),
		[UpdateTimeDateStamp] DATETIME,
	);

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RollStock' AND COLUMN_NAME = 'Tag')
		BEGIN
			INSERT INTO #TempRollStock
			SELECT RS.[PK_UUID], RS.[Width], RS.[StkDate], RS.[DateRollUsed], RS.[StkUsed], RS.[Location], RS.[FootLength], RS.[CreatedDate], RS.[StockNum], ISNULL(F.ID, @FacilityId) AS FacilityID, RS.UpdateTimeDateStamp
			FROM [dbo].[RollStock] RS WITH(NOLOCK)
				LEFT JOIN [dbo].[Facility] F ON F.[SourceFacilityId] = RS.[Tag]
		END
	ELSE
		BEGIN
			INSERT INTO #TempRollStock
			SELECT RS.[PK_UUID], RS.[Width], RS.[StkDate], RS.[DateRollUsed], RS.[StkUsed], RS.[Location], RS.[FootLength], RS.[CreatedDate], RS.[StockNum], @FacilityId AS FacilityID, RS.UpdateTimeDateStamp
			FROM [dbo].[RollStock] RS WITH(NOLOCK)
		END

		 CREATE NONCLUSTERED INDEX IX_TempRollStock_PK_UUID ON #TempRollStock(PK_UUID);

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateStockInventory'; SET @startTime = getdate();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			UPDATE SI
			SET 
				[Width] = RS.[Width],
				[DimWidth] = RS.[Width],
				[StockedOn] = RS.[StkDate],
				[LastUsedOn] = RS.[DateRollUsed],
				[StockUsed] = RS.[StkUsed],
				[Location] = RS.[Location],
				[ModifiedOn] = GETUTCDATE(),
				[Length] = RS.[FootLength],
				[FacilityId] = RS.[FacilityID]
			FROM [dbo].[StockInventory] SI WITH(NOLOCK)
			INNER JOIN #TempRollStock RS 
				ON SI.[SourceStockInventoryId] = RS.[PK_UUID]
			where @Since IS NULL
			OR RS.UpdateTimeDateStamp >= @Since

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
		SET @blockName = 'InsertStockInventory'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			INSERT INTO [dbo].[StockInventory] (
				[Id],
				[StockMaterialId],
				[Source],
				[SourceStockInventoryId],
				[Width],
				[StockedOn],
				[LastUsedOn],
				[StockUsed],
				[Location],
				[SourceCreatedOn],
				[CreatedOn],
				[ModifiedOn],
				[Length],
				[FacilityId],
				[DimWidth]
				)
			SELECT 
				NEWID() [Id],
				SM.[Id] [StockMaterialId],
				'LabelTraxx' [Source],
				RS.[PK_UUID] [SourceStockInventoryId],
				RS.[Width] [Width],
				RS.[StkDate] [StockedOn],
				RS.[DateRollUsed] [LastUsedOn],
				RS.[StkUsed] [StockUsed],
				RS.[Location] [Location],
				RS.[CreatedDate] [SourceCreatedOn],
				GETUTCDATE() [CreatedOn],
				GETUTCDATE() [ModifiedOn],
				RS.[FootLength] [Length],
				RS.[FacilityId],
				RS.[Width] [DimWidth]
			FROM 
				#TempRollStock RS
				INNER JOIN [dbo].[StockMaterial] SM ON RS.[StockNum] = SM.[SourceStockId]
				WHERE
			NOT EXISTS(SELECT 1 FROM StockInventory WHERE SourceStockInventoryId = RS.PK_UUID)
				
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
	
			
	DROP TABLE IF EXISTS #TempRollStock
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END