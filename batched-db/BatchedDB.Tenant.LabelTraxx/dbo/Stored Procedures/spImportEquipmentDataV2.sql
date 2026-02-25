CREATE PROCEDURE spImportEquipmentDataV2
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
		@spName					varchar(100) = 'spImportEquipmentDataV2',
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

	IF @IsError = 0	
	BEGIN
		SET @blockName = 'GenerateTemporaryEquipmentData'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			select E.* 
			into #FilteredEquipments
			from Equipment E
			inner join 
			(
				select Number, COUNT(1) counts 
				from Equipment group by Number 
				having COUNT(1) = 1
			) E_Singles on E.Number = E_Singles.Number

			insert into #FilteredEquipments
			select E.* from Equipment E
			inner join 
			(
				select 
					Number, MAX(CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108))) ModifiedDateTime
				from Equipment
				where ID not in (select ID from #FilteredEquipments)
				and inactive = 0 
				group by Number
			) Dupes on E.Number = Dupes.Number and CAST(E.ModifiedDate as Date) = CAST(ModifiedDateTime as Date) and CAST(E.ModifiedTime as Time(0)) = CAST(ModifiedDateTime as Time(0))


			insert into #FilteredEquipments
			select E.* from Equipment E
			inner join 
			(
				select 
					Number, MAX(CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108))) ModifiedDateTime
				from Equipment
				where ID not in (select ID from #FilteredEquipments) and Number not in (select Number from #FilteredEquipments)
				and inactive = 1 
				group by Number
			) Dupes on E.Number = Dupes.Number and CAST(E.ModifiedDate as Date) = CAST(ModifiedDateTime as Date) and CAST(E.ModifiedTime as Time(0)) = CAST(ModifiedDateTime as Time(0))

			DECLARE @RepeatedRecords int

			Select @RepeatedRecords = COUNT(1)
			from
			(
				select Number, COUNT(1) counts from Equipment 
				group by Number
				having COUNT(1) > 1
			) Dupes

			IF @RepeatedRecords > 1 
			BEGIN
				SET @warningStr = 'TotalDuplicates_Equipment_Number|' +  CONVERT(varchar, @RepeatedRecords);
				SET @infoStr = NULL;
			END

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
	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'UpdateEquipment'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update EM 
			set 
				EM.Name = E.Number, 
				EM.DisplayName = E.Number,
				EM.Description = E.Description,
				EM.IsEnabled = (case when E.Inactive = 0 then 1 else 0 end),
				SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
				SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
				ModifiedOn = GETUTCDATE()
			from EquipmentMaster EM
			inner join #FilteredEquipments E on E.Number = EM.SourceEquipmentId and EM.Source = 'LabelTraxx'
			where @Since IS NULL OR E.UpdateTimeDateStamp >= @Since


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
		SET @blockName = 'InsertEquipment'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into EquipmentMaster (ID, TenantId, Source, SourceEquipmentId, Name, DisplayName, Description, SourceCreatedOn, SourceModifiedOn, CreatedOn, ModifiedOn)
			select 
				NEWID() ID,
				@TenantId TenantId,
				'LabelTraxx' Source,
				Number SourceEquipmentId,
				Number Name,
				Number DisplayName,
				Description Description,
				CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
				CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn
			from 
				#FilteredEquipments
			where 
				Number not in (select SourceEquipmentId from EquipmentMaster where Source = 'LabelTraxx')
				
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
	SET @blockName = 'GetNewUpdatedEquipmentSpeed'; 
	SET @startTime = GETDATE();
	BEGIN TRY
	-- UPDATE MATCHING ROWS
			
				SELECT
					EM.Id AS EquipmentId,
					V.Level,
					V.LengthFrom,
					V.LengthTo,
					V.Speed
				INTO #UpdatedEquipmentSpeed
				FROM #FilteredEquipments E
				INNER JOIN EquipmentMaster EM ON E.NUMBER = EM.SourceEquipmentId
				CROSS APPLY
				(
					VALUES
						(1,  E.StockSpoilL1,  E.StockSpoilH1,  E.PressSpeed1),
						(2,  E.StockSpoilL2,  E.StockSpoilH2,  E.PressSpeed2),
						(3,  E.StockSpoilL3,  E.StockSpoilH3,  E.PressSpeed3),
						(4,  E.StockSpoilL4,  E.StockSpoilH4,  E.PressSpeed4),
						(5,  E.StockSpoilL5,  E.StockSpoilH5,  E.PressSpeed5),
						(6,  E.StockSpoilL6,  E.StockSpoilH6,  E.PressSpeed6),
						(7,  E.StockSpoilL7,  E.StockSpoilH7,  E.PressSpeed7),
						(8,  E.StockSpoilL8,  E.StockSpoilH8,  E.PressSpeed8),
						(9,  E.StockSpoilL9,  E.StockSpoilH9,  E.PressSpeed9),
						(10, E.StockSpoilL10, E.StockSpoilH10, E.PressSpeed10),
						(11, E.StockSpoilL11, E.StockSpoilH11, E.PressSpeed11),
						(12, E.StockSpoilL12, E.StockSpoilH12, E.PressSpeed12),
						(13, E.StockSpoilL13, E.StockSpoilH13, E.PressSpeed13),
						(14, E.StockSpoilL14, E.StockSpoilH14, E.PressSpeed14),
						(15, E.StockSpoilL15, E.StockSpoilH15, E.PressSpeed15),
						(16, E.StockSpoilL16, E.StockSpoilH16, E.PressSpeed16),
						(17, E.StockSpoilL17, E.StockSpoilH17, E.PressSpeed17),
						(18, E.StockSpoilL18, E.StockSpoilH18, E.PressSpeed18),
						(19, E.StockSpoilL19, E.StockSpoilH19, E.PressSpeed19),
						(20, E.StockSpoilL20, E.StockSpoilH20, E.PressSpeed20)
				) AS V(Level, LengthFrom, LengthTo, Speed)
				WHERE @Since IS NULL OR E.UpdateTimeDateStamp >= @Since

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
	SET @blockName = 'UpdateEquipmentSpeed'; 
	SET @startTime = GETDATE();
	BEGIN TRY
			
					UPDATE ESM
					SET 
						ESM.LengthFrom = U.LengthFrom,
						ESM.LengthTo = U.LengthTo,
						ESM.Speed = U.Speed,
						ESM.ModifiedOnUtc = GETUTCDATE()
					FROM EquipmentSpeed ESM
					INNER JOIN #UpdatedEquipmentSpeed U
						ON ESM.EquipmentId = U.EquipmentId
						AND ESM.Level = U.Level;

						SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


						END TRY
	Begin CATCH
--	==================================[Do not change]================================================
		SET @IsError = 1; Rollback;
		SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--	=======================[Concate more error strings after this]===================================
       --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
	END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, 
			@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;
	END

	-- BLOCK END

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0
	BEGIN
	SET @blockName = 'InsertEquipmentSpeed'; 
	SET @startTime = GETDATE();
	BEGIN TRY
			INSERT INTO EquipmentSpeed
			(
				Id,
				EquipmentId,
				Level,
				LengthFrom,
				LengthTo,
				Speed,
				CreatedOnUtc,
				ModifiedOnUtc
			)
			SELECT 
				NEWID(),
				U.EquipmentId,
				U.Level,
				U.LengthFrom,
				U.LengthTo,
				U.Speed,
				GETUTCDATE(),
				GETUTCDATE()
			FROM #UpdatedEquipmentSpeed U
			WHERE NOT EXISTS 
			(
				SELECT 1 
				FROM EquipmentSpeed ES 
				WHERE ES.EquipmentId = U.EquipmentId 
				  AND ES.Level = U.Level
			);

	END TRY
	Begin CATCH
--	==================================[Do not change]================================================
		SET @IsError = 1; Rollback;
		SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--	=======================[Concate more error strings after this]===================================
       --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
	END CATCH
	INSERT @__ErrorInfoLog EXEC spLogCreator 
			@CorelationId, @TenantId, @SPName, @IsError, @startTime, 
			@maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, 
			@errorStr OUTPUT, @infoStr OUTPUT;
	END

--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================


	DROP table IF EXISTS #FilteredEquipments
	DROP table IF EXISTS #UpdatedEquipmentSpeed
	DROP table IF EXISTS #UpdatedEquipmentUDO
END
GO