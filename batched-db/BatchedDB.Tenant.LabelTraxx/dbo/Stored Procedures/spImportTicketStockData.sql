CREATE PROCEDURE [dbo].[spImportTicketStockData]
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
		@spName					varchar(100) = 'spImportTicketStockData',
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
	DROP TABLE IF EXISTS #MatchingTicketStocks;
	CREATE TABLE #MatchingTicketStocks (
	TicketNumber NVARCHAR(50),
	StockNum NVARCHAR(50),
	Sequence NVARCHAR(10),
	StockType NVARCHAR(50),
	Width NVARCHAR(50),
	Notes NVARCHAR(MAX),
	EstimatedLength FLOAT,
	RoutingNo INT
		);

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'GeneratingTicketStocks'; SET @startTime = GETDATE();

		Begin TRY	

			IF EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.TABLES t
				JOIN INFORMATION_SCHEMA.COLUMNS c
					ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
				WHERE t.TABLE_NAME = 'Ticket_CommonStock'
				  AND c.COLUMN_NAME IN ('routingNo', 'updateTimeDateStamp')
				GROUP BY t.TABLE_NAME, t.TABLE_SCHEMA
				HAVING COUNT(DISTINCT c.COLUMN_NAME) = 2
			)
			BEGIN
				--PRINT 'BOTH TABLE AND COLUMNS EXISTS'
				DECLARE @sql NVARCHAR(MAX);
				SET @sql = '
					INSERT INTO #MatchingTicketStocks
					SELECT
						T.Number AS TicketNumber,
						TCS.StockNum AS StockNum,
						ROW_NUMBER() OVER (PARTITION BY T.Number ORDER BY TCS.UpdateTimeDateStamp) AS Sequence,
						TCS.StockType AS StockType,
						TCS.Width AS Width,
						TCS.Description AS Notes,
						T.EstFootage AS EstimatedLength,
						TCS.RoutingNo AS RoutingNo
					FROM Ticket_CommonStock TCS
					INNER JOIN Ticket T ON TCS.TicketNumber = T.Number
				';
				EXEC sp_executesql @sql;
			END
			ELSE
			BEGIN
						-- Matching id in temporary table
					INSERT INTO #MatchingTicketStocks
					SELECT Number as TicketNumber, stockNum, [Sequence], StockType, Width, Notes, EstimatedLength, RoutingNo
					FROM (
								SELECT Number,StockNum1 AS stockNum, 1 as [Sequence], 'Laminate' as StockType, StockWidth1 as Width, StockDesc1 as Notes, EstFootage as EstimatedLength, NULL AS RoutingNo
								FROM ticket
								WHERE (StockNum1 IS NOT NULL)
								UNION ALL
								SELECT Number,StockNum2 AS stockNum, 2 as [Sequence], 'Substrate' as StockType, StockWidth2 as Width, StockDesc2 as Notes, EstFootage as EstimatedLength, NULL AS RoutingNo
								FROM ticket
								WHERE (StockNum2 IS NOT NULL)
								UNION ALL
								SELECT Number,StockNum3 AS stockNum, 3 as [Sequence], 'HotFoil' as StockType, StockWidth3 as Width,StockDesc3 as Notes, EstFootage as EstimatedLength, NULL AS RoutingNo
								FROM ticket
								WHERE (StockNum3 IS NOT NULL)
							) as ticketStocks 

					
			END

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'DeleteOrUpdateTicketStocks'; SET @startTime = GETDATE();

		Begin TRY		
				if (@Since IS NULL)
					Begin
						TRUNCATE TABLE [dbo].[TicketStock]
						SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
					End
				Else
					Begin
						DELETE ts FROM [dbo].[TicketStock] ts
						INNER JOIN 
							TicketMaster TM on ts.TicketId = TM.ID
								WHERE TM.ModifiedOn >= @Since
					End
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
		SET @blockName = 'InsertTicketStocks'; SET @startTime = GETDATE();

		Begin TRY
			----Insert the records into TicketStock using Ticket table
			INSERT INTO [dbo].[TicketStock] ([Id], [TicketId], [StockMaterialId], [Sequence], [StockType] ,[Width], [Notes], [CreatedOn], [ModifiedOn], [RequiredQuantity], [TaskName], [RoutingNo])
				SELECT 
					NEWID(), 
					TM.ID,
					SM.Id, 
					MTS.[Sequence], 
					MTS.StockType, 
					MTS.Width,
					MTS.Notes, 
					GETUTCDATE(),
					GETUTCDATE(),
					MTS.EstimatedLength,
					CASE WHEN MTS.RoutingNo IS NULL THEN
						CASE WHEN MTS.Sequence = 2 THEN 
									CASE WHEN tm.Press IS NOT NULL THEN 'Press'
										WHEN tm.EquipID IS NOT NULL THEN 'Equip'
										WHEN tm.Equip3ID IS NOT NULL THEN 'Equip3'
										WHEN tm.Equip4ID IS NOT NULL THEN 'Equip4'
										WHEN tm.Equip5ID IS NOT NULL THEN 'Equip5'
										WHEN tm.Equip6Id IS NOT NULL THEN 'Equip6'
										WHEN tm.RewindEquipNum IS NOT NULL THEN 'Rewind'
										ELSE 'Press'
									END
							ELSE CASE WHEN tm.EquipId IS NOT NULL THEN 'Equip'
										ELSE 'Press'
									END
						END
					ELSE
						CASE WHEN MTS.RoutingNo = 1 THEN 'Press'
							 WHEN MTS.RoutingNo = 2 THEN 'Equip'
							 WHEN MTS.RoutingNo = 3 THEN 'Equip3'
							 WHEN MTS.RoutingNo = 4 THEN 'Equip4'
							 WHEN MTS.RoutingNo = 5 THEN 'Equip5'
							 WHEN MTS.RoutingNo = 6 THEN 'Equip6'
							 WHEN MTS.RoutingNo = 7 THEN 'Equip7'
							 ELSE 'Press'
						END
					END,
					MTS.RoutingNo AS RoutingNo
				FROM
					#MatchingTicketStocks as MTS
				INNER JOIN 
					TicketMaster TM on MTS.TicketNumber = TM.SourceTicketId
				INNER JOIN 
					StockMaterial SM on MTS.stockNum = SM.SourceStockId
				LEFT JOIN
					TicketStock TS on TS.TicketId = TM.ID 
				WHERE 
					TS.Id IS NULL
				ORDER BY 
					MTS.TicketNumber ASC,
					MTS.[Sequence] ASC

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
	drop table if exists #MatchingTicketStocks
					   		
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
