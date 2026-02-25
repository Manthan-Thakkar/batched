CREATE PROCEDURE [dbo].[spImportTicketScoreData]
    @tickets udt_TicketScore ReadOnly,
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketScoreData',
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
	
	DROP TABLE IF EXISTS #MatchingTickets;
	DROP TABLE IF EXISTS #tempScore;

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'GeneratingTicketsMapping'; SET @startTime = GETDATE();

		Begin TRY	
			DECLARE @MissingTickets int;
			
			-- Matching id in temporary table
			SELECT 
				TicketMaster.Id as TicketId, 
				Ticket.Number as TicketNumber
			INTO
				#MatchingTickets
			FROM
				TicketMaster
				INNER JOIN Ticket ON Ticket.Number = TicketMaster.SourceTicketId
			WHERE 
				TicketMaster.Source = 'LabelTraxx'
				AND (TicketMaster.IsOnHold = 1 OR TicketMaster.IsOpen = 1)
				AND TicketMaster.TenantId = @TenantId
		
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT);
			
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
		SET @blockName = 'CalculatingScore'; SET @startTime = GETDATE();

		Begin TRY	

		;with openTickets as (
					SELECT
							TSP.ShipByDateTime as ShipTime,
							MT.TicketId ,
							Priority,
							EstTotal,
							CustomerNum
					FROM 
						#MatchingTickets MT
						INNER JOIN Ticket T ON MT.TicketNumber = T.Number
						INNER JOIN TicketShipping TSP on TSP.TicketId = MT.TicketId
		),scoringSetup as (
					select 
						 ot.*
						,dbo.udf_WorkDays(ot.ShipTime,GETDATE()) as daysLate
						, ISNULL(cp.Rank,'C')  as customerRank
						, (ROW_NUMBER() OVER(ORDER BY ot.EstTotal))*1.0 / 
						(COUNT(ot.TicketId) OVER()) as revenuePercentile
					FROM 
					openTickets ot 
					LEFT JOIN CustomerRank cp ON cp.SourceCustomerId = ot.CustomerNum
		),pointsCalc as(
				select
					TicketId

					-- due date score
					, CASE 
						WHEN daysLate > 0 THEN 2*ABS(daysLate)
						WHEN daysLate >= -1 THEN 1.5 -- due today or tomorrow
						WHEN daysLate >= -2 THEN 1.4
						WHEN daysLate >= -3 THEN 1.3
						WHEN daysLate >= -4 THEN 1.2
						WHEN daysLate >= -5 THEN 1.1
						WHEN daysLate >= -10 THEN 1
						WHEN daysLate >= -15 THEN 0.75
						WHEN daysLate >= -20 THEN 0.5
						ELSE 0.1
						END as dueDatePoints

					-- revenue percentile score
					, 1+ISNULL(revenuePercentile,0) as orderSizePoints

					-- priority score
					, CASE WHEN priority LIKE '%Urgent%' or priority LIKE '%High%' or priority LIKE '%Rush%' or priority LIKE '%Promised%' THEN 1000 ELSE 1 END as priorityPoints

				from 
					scoringSetup 
		)

		SELECT * into #tempScore from pointsCalc
		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT);

			
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
		SET @blockName = 'UpdateTicketScore'; SET @startTime = GETDATE();

		Begin TRY	
			
			Update TS
			Set  [RevenueScore]= #tempScore.orderSizePoints,		
			     [DueDateScore]=#tempScore.dueDatePoints,		
			     [CustomerRankScore]= ISNULL( TSC.CustomerRankScore,0),	
			     [PriorityScore]=#tempScore.priorityPoints,		
			     ModifiedOn = GETUTCDATE()			
			FROM TicketScore TS
			INNER JOIN #tempScore on TS.TicketId = #tempScore.TicketId
			LEFT JOIN @tickets TSC on TS.TicketId = TSC.TicketId
		
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT);
			
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
		SET @blockName = 'InsertTicketScore'; SET @startTime = GETDATE();

		Begin TRY	
			
			INSERT INTO [dbo].[TicketScore] ([TicketId],[RevenueScore],[DueDateScore],[CustomerRankScore],[PriorityScore],CreatedOn,[ModifiedOn])
			   SELECT 
					TS.TicketId,
					TS.orderSizePoints,
					TS.dueDatePoints,
					ISNULL(TSC.CustomerRankScore,0),	
					TS.priorityPoints,
					GETUTCDATE(),
					GETUTCDATE()
				FROM #tempScore TS LEFT JOIN @tickets TSC on TS.TicketId = TSC.TicketId
				Where TS.TicketId NOT IN (SELECT TicketId FROM TicketScore)
			   

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT);
			
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
		SET @blockName = 'DeleteTicketScore'; SET @startTime = GETDATE();

		Begin TRY	
			
			DELETE FROM TicketScore
			WHERE TicketScore.TicketId NOT IN (SELECT TicketId FROM #tempScore)

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT);
			
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END

	DROP TABLE IF EXISTS #MatchingTickets;
	DROP TABLE IF EXISTS #tempScore;
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