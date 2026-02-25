CREATE PROCEDURE [dbo].[spImportTicketDimensionsData]
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
		@spName					varchar(100) = 'spImportTicketDimensionsData',
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
	
	DROP TABLE IF EXISTS #MatchingTicketDimensions;
	DROP TABLE IF EXISTS #MatchingNumLeftoverRolls;

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'GeneratingTicketsMapping'; SET @startTime = GETDATE();
		DECLARE @MissingTicketDimensions int;

		Begin TRY	
			-- Matching id in temporary table

			SELECT 
				TicketMaster.Id as TicketId, 
				Ticket.Number as TicketNumber
			INTO
				#MatchingTicketDimensions
			FROM
				TicketDimensions
				INNER JOIN TicketMaster ON TicketDimensions.TicketId = TicketMaster.ID 
				INNER JOIN Ticket ON Ticket.Number = TicketMaster.SourceTicketId
			
			CREATE INDEX IX_MatchingTicketDimensions_TicketId_TicketNumber ON #MatchingTicketDimensions (TicketId);

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

			
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
		SET @blockName = 'CalculatingNumLeftoverRolls'; SET @startTime = GETDATE();

		Begin TRY	
				SELECT 
					mtd.TicketId, 
					SUM(Ceiling(CASE 
						When T.ActQuantity > T.TicQuantity Then 0
						WHEN T.[LabelsPer_] = 0 THEN NULL
						When T.PriceMode='Rolls' Then  T.TicQuantity - T.ActQuantity
						ELSE (TItem.OrderQuantity*1.0 / nullif(T.[LabelsPer_], 1)) 
						END)) as numberOfLeftoverRolls
				INTO
					#MatchingNumLeftoverRolls
				FROM 
					#MatchingTicketDimensions mtd
					INNER JOIN Ticket T with(NOLOCK) on T.Number = mtd.TicketNumber
					INNER JOIN TicketItemInfo TItem with(NOLOCK) on TItem.TicketId = mtd.TicketId
				Group by 
					mtd.TicketId

					
				SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
			
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
		SET @blockName = 'UpdateTicketDimensions'; SET @startTime = GETDATE();

		Begin TRY
			----Update the records into TicketDimensions table
			Update
				[TicketDimensions] 
			set
				ConsecutiveNumber		= T.ConsecNo ,
				Quantity				= T.TicQuantity,
				ActualQuantity			= T.ActQuantity,
				SizeAcross				= T.SizeAcross,
				SizeAround				= T.SizeAround,
				Shape					= T.Shape,
				ColumnSpace				= T.ColSpace,
				RowSpace				= T.RowSpace,
				NumAcross				= T.NoAcross,
				NumAroundPlate			= T.NoArounPlate,
				LabelRepeat				= T.LabelRepeat,
				FinishedNumAcross		= T.NoLabAcrossFin,
				FinishedNumLabels		= T.LabelsPer_,
				CoreSize				= T.CoreSize,
				OutsideDiameter			= T.OutsideDiameter,
				EsitmatedLength			= T.EstFootage,
				OverRunLength			= T.OverRun,
				NoPlateChanges          = T.NoPlateChanges,
				CalcLinearLength		= (ceiling((T.TicQuantity*(1+(1.0*T.OverRun/100)))/(CASE WHEN T.NoAcross = 0 THEN 1 ELSE T.NoAcross END * CASE WHEN T.NoArounPlate = 0 THEN 1 ELSE T.NoArounPlate END)) * (CASE WHEN T.NoArounPlate = 0 THEN 1 ELSE T.NoArounPlate END * (T.SizeAround + T.RowSpace)))/1000.0 ,
				CalcNumLeftoverRolls	= leftoverRolls.numberOfLeftoverRolls,
				CalcFinishedRollLength	= T.LabelRepeat * (T.LabelsPer_ / CASE WHEN T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END) / 1000,
				CalcCoreWidth			= Case When T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END * (T.SizeAcross + T.ColSpace) ,
				CalcNumStops			= try_CONVERT(DECIMAL(10,5),CASE When T.PriceMode = 'Rolls' Then TicQuantity WHEN T.[LabelsPer_] = 0 THEN NULL ELSE T.TicQuantity*1.0 / T.[LabelsPer_] END) / NULLIF(T.NoAcross,0) * CASE WHEN T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END,
				ModifiedOn = GETUTCDATE(),
				ActFootage = T.ActFootage,
				CoreType = T.CoreType,
				RollLength = T.RollLength,
				RollUnit = T.RollUnit,
				EstimatedLength = T.EstFootage
			FROM 
				[TicketDimensions] TD
				INNER JOIN #MatchingTicketDimensions mtd ON TD.TicketId = mtd.TicketId
				INNER JOIN Ticket T ON T.Number = mtd.TicketNumber
				LEFT JOIN #MatchingNumLeftoverRolls leftoverRolls on leftoverRolls.TicketId = mtd.TicketId
			where @Since IS NULL
			OR T.UpdateTimeDateStamp >= @Since --Potential issue with CalcNumLeftoverRolls not updating

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

		-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertTicketDimensions'; SET @startTime = GETDATE();

		Begin TRY
			----Insert the records into TicketDimensions table
			INSERT INTO [TicketDimensions] (Id,TicketId,ConsecutiveNumber,Quantity, ActualQuantity,SizeAcross,	SizeAround,Shape,ColumnSpace,RowSpace,
						NumAcross,NumAroundPlate,LabelRepeat,FinishedNumAcross,FinishedNumLabels,CoreSize,OutsideDiameter,EsitmatedLength,
						OverRunLength,NoPlateChanges,CalcLinearLength,CalcNumLeftoverRolls,CalcFinishedRollLength,CalcCoreWidth,CalcNumStops,CreatedOn,ModifiedOn,ActFootage,CoreType,RollLength,RollUnit, EstimatedLength)
				SELECT
					 NEWID(),
					 TM.ID,
					 T.ConsecNo ,
					 T.TicQuantity,
					 T.ActQuantity,
					 T.SizeAcross,
					 T.SizeAround,
					 T.Shape,
					 T.ColSpace,
					 T.RowSpace,
					 T.NoAcross,
					 T.NoArounPlate,
					 T.LabelRepeat,
					 T.NoLabAcrossFin,
					 T.LabelsPer_,
					 T.CoreSize,
					 T.OutsideDiameter,
					 T.EstFootage,
					 T.OverRun,
					 T.NoPlateChanges,
					 (ceiling((T.TicQuantity*(1+(1.0*T.OverRun/100)))/(CASE WHEN T.NoAcross = 0 THEN 1 ELSE T.NoAcross END * CASE WHEN T.NoArounPlate = 0 THEN 1 ELSE T.NoArounPlate END)) * (CASE WHEN T.NoArounPlate = 0 THEN 1 ELSE T.NoArounPlate END * (T.SizeAround + T.RowSpace)))/1000.0 ,
					leftoverRolls.numberOfLeftoverRolls,
					 T.LabelRepeat * (T.LabelsPer_ / CASE WHEN T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END) / 1000,
					 Case When T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END * (T.SizeAcross + T.ColSpace) ,
					 try_CONVERT(DECIMAL(10,5),CASE When T.PriceMode = 'Rolls' Then TicQuantity WHEN T.[LabelsPer_] = 0 THEN NULL ELSE T.TicQuantity*1.0 / T.[LabelsPer_] END) / NULLIF(T.NoAcross,0) * CASE WHEN T.NoLabAcrossFin = 0 THEN 1 ELSE T.NoLabAcrossFin END,
					GETUTCDATE(),
					GETUTCDATE(),
					T.ActFootage,
					T.CoreType,
					T.RollLength,
					T.RollUnit,
					T.EstFootage
				FROM 
					Ticket T 
					INNER JOIN TicketMaster TM on T.Number = TM.SourceTicketId
					LEFT JOIN #MatchingNumLeftoverRolls leftoverRolls on leftoverRolls.TicketId = TM.ID
				WHERE 
					NOT EXISTS (select 1 FROM #MatchingTicketDimensions mtd WHERE mtd.TicketId = TM.ID) 

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

--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================



	DROP TABLE IF EXISTS #MatchingTicketDimensions;
	DROP TABLE IF EXISTS #MatchingNumLeftoverRolls;
END