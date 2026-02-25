CREATE PROCEDURE [dbo].[spImportTimecardData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTimecardData',
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
		SET @blockName = 'Delete Time card data'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			Truncate Table TimeCardInfo

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
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
		SET @blockName = 'InsertTimecard'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into TimecardInfo(Id,SourceTimecardId,TicketId,SourceTicketId,EquipmentId,
			SourceEquipmentId,StartedOn,CompletedAt,ElapsedTime,ActualNetQuantity,CreatedOn,
			ModifiedOn,Totalizer,OperationType,Associate,ActualWasteQuantity,FinishedPieces,
			ActualGrossQuantity,ActualGrossLength,ActualCurrentSpeed, TaskName)
			select 
				NEWID() ID,
				CONCAT(T.kco,'_',t.PlantCode,'_',T.kjobcode,'_',T.kcompno,'_',T.kprocno,'_',T.[seq-code],'_',T.[seq-code2]) SourceTimecardId,
				TM.ID TicketId,
				Concat( T.kco,'_',T.PlantCode,'_',T.kjobcode,'_',T.kcompno) SourceTicketId,
				EM.ID EquipmentId,
				[mach-id] SourceEquipmentId,
				DATEADD(SECOND, [start-time], CAST('1990-01-01' AS DATETIME)) StartedOn,
				DATEADD(SECOND, [end-time], CAST('1990-01-01' AS DATETIME))CompletedAt,
				CONVERT(time(0), DATEADD(SECOND, [elapse-time], 0)) ElapsedTime,
				[event-qty] ActualNetQuantity,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				null,--Totalizer
				null,--sfstatcode.description OperationType
				T.[op-code],--Associate
				T.[scrap-qty],--ActualWasteQuantity
				(T.[scrap-qty] + T.[event-qty]), --FinishedPieces
				T.[event-qty],--ActualGrossQuantity
				null,--ActualGrossLength
				null, -- ActualCurrentSpeed
				T.kprocno --TaskName
			from sfeventcds T
			inner join TicketMaster TM on Concat( t.kco,'_',T.PlantCode,'_',T.kjobcode,'_',T.kcompno)  = TM.SourceTicketId and TM.Source = 'Radius'
			inner join EquipmentMaster EM on T.[mach-id] = EM.SourceEquipmentId and TM.Source = 'Radius'
			where [elapse-time] > 0
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
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
END



