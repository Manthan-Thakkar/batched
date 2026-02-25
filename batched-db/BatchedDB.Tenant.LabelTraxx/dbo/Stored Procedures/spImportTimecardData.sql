CREATE PROCEDURE [dbo].[spImportTimecardData]
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

	
	-- DUPLICATE CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'DuplicateTimecardCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, ID 
					from Timecard 
					group by ID
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_Timecard_ID|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

			END
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


	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateTimecardInfoData'; SET @startTime = GETDATE();
		Begin TRY		
			Begin
				if (@Since IS NULL)
					Begin
						Truncate Table TimeCardInfo
					End
				Else
					Begin
						update TimecardInfo 
						set 
							StartedOn			= CONVERT(DATETIME, CONVERT(CHAR(8), SDate, 112) + ' ' + CONVERT(CHAR(8), STime, 108)),
							CompletedAt			= CONVERT(DATETIME, CONVERT(CHAR(8), EDate, 112) + ' ' + CONVERT(CHAR(8), ETime, 108)),
							ElapsedTime			= cast(dateadd(MINUTE,datediff(MINUTE, CONVERT(DATETIME, CONVERT(CHAR(8), SDate, 112) + ' ' + CONVERT(CHAR(8), STime, 108)), CONVERT(DATETIME, CONVERT(CHAR(8), EDate, 112) + ' ' + CONVERT(CHAR(8), ETime, 108))),0) as Time(0)),
							ActualNetQuantity	= CASE WHEN T.FinishedPieces > Labels_Act_Net THEN T.FinishedPieces ELSE Labels_Act_Net END,
							Associate			= T.AssocNo,
							Totalizer			= T.Totalizer,
							OperationType		= T.WorkOperation,
							ActualWasteQuantity = T.Labels_Act_Waste,
							FinishedPieces		= T.FinishedPieces,
							ActualGrossQuantity = T.Labels_Act_Gross,
							ActualGrossLength 	= T.Length_Act_Gross,
							ActualCurrentSpeed	= T.Speed_Act_Length_Min,
							ModifiedOn			= GETUTCDATE()
						from TimecardInfo tci
						Inner Join Timecard t on tci.SourceTimecardId = t.id
						where T.UpdateTimeDateStamp >= @Since
					End   
				End

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
				T.ID SourceTimecardId,
				TM.ID TicketId,
				Ticket_No SourceTicketId,
				EM.ID EquipmentId,
				PressNo SourceEquipmentId,
				CONVERT(DATETIME, CONVERT(CHAR(8), SDate, 112) + ' ' + CONVERT(CHAR(8), STime, 108)) StartedOn,
				CONVERT(DATETIME, CONVERT(CHAR(8), EDate, 112) + ' ' + CONVERT(CHAR(8), ETime, 108)) CompletedAt,
				cast(dateadd(MINUTE,datediff(MINUTE, CONVERT(DATETIME, CONVERT(CHAR(8), SDate, 112) + ' ' + CONVERT(CHAR(8), STime, 108)), CONVERT(DATETIME, CONVERT(CHAR(8), EDate, 112) + ' ' + CONVERT(CHAR(8), ETime, 108))),0) as Time(0)) ElapsedTime,
				CASE WHEN T.FinishedPieces > Labels_Act_Net THEN T.FinishedPieces ELSE Labels_Act_Net END ActualNetQuantity,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				T.Totalizer Totalizer,
				T.WorkOperation OperationType,
				T.AssocNo Associate,
				T.Labels_Act_Waste ActualWasteQuantity,
				T.FinishedPieces FinishedPieces,
				T.Labels_Act_Gross ActualGrossQuantity,
				T.Length_Act_Gross ActualGrossLength,
				T.Speed_Act_Length_Min ActualCurrentSpeed,
				CASE 
					WHEN T.Ticket_PressEquip = 'Equip4' THEN 'EQUIP4'
					WHEN T.Ticket_PressEquip = 'Equip3' THEN 'EQUIP3'
					WHEN T.Ticket_PressEquip = 'Press' THEN 'PRESS'
					WHEN T.Ticket_PressEquip = 'Equipment' THEN 'EQUIP'
					WHEN T.Ticket_PressEquip IS NULL THEN 'REWINDER'
					ELSE NULL 
				END AS TaskName
			from Timecard T
			inner join TicketMaster TM on T.Ticket_No = TM.SourceTicketId
			inner join EquipmentMaster EM on T.PressNo = EM.SourceEquipmentId
			left join TimecardInfo TCI on T.ID = TCI.SourceTimecardId
			WHERE TCI.SourceTimecardId IS NULL

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (
				select COUNT(1) 
				from Timecard T
				left join TimecardInfo TCI on T.ID = TCI.SourceTimecardId
				where TCI.SourceTimecardId IS NULL and T.ID is null
			)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Timecard_ID|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
				SET @infoStr = null;
			END

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

