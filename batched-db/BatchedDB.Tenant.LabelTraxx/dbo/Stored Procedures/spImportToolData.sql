CREATE PROCEDURE [dbo].[spImportToolData]
	@TenantId		nvarchar(36),
	@CorelationId varchar(100),
	@Since DateTime = NULL
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportToolData',
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


	-- Delete Duplicate records in TicketTool caused due to LT ERP issue.
	;WITH [DuplicateTicketToolIds] AS (
		SELECT [Id], ROW_NUMBER() OVER (PARTITION BY [TicketId], [ToolingId], [Sequence] ORDER BY [ModifiedOn] DESC, LEN([Description]) DESC) AS [RowNumber]
		FROM [dbo].[TicketTool]
	)
		DELETE [TT]
		FROM [dbo].[TicketTool] TT
		INNER JOIN [DuplicateTicketToolIds] DTT ON [TT].[Id] = [DTT].[Id]
		WHERE [RowNumber] <> 1;


	-- Delete Duplicate records in ToolingInventory caused due to LT ERP issue.
	;WITH [DistinctTools] AS (
		SELECT [SourceToolingId], [ToolType], MIN([Id]) AS [MinId]
		FROM [dbo].[ToolingInventory]
		GROUP BY [SourceToolingId], [ToolType]
	)
		DELETE [TI]
		FROM [dbo].[ToolingInventory] TI
		INNER JOIN [DistinctTools] DT ON [TI].[SourceToolingId] = [DT].[SourceToolingId] AND [TI].[ToolType] = [DT].[ToolType]
		WHERE [TI].[Id] <> [DT].[MinId];



	-- Get Distinct Tooling
	DROP TABLE IF EXISTS [dbo].[#TempTooling];

	;WITH [TempTooling] AS (
		SELECT *, ROW_NUMBER() OVER (PARTITION BY [Number] ORDER BY [ModifiedDate] DESC, [ModifiedTime] DESC) AS [RowNumber]
		FROM [dbo].[Tooling]
	)
		SELECT *
        INTO [dbo].[#TempTooling]
        FROM [TempTooling]
        WHERE [RowNumber] = 1;



	-- DUPLICATE CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'DuplicateToolingCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, Number 
					from [dbo].[#TempTooling] 
					group by Number
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_Tooling_Number|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 0
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						select COUNT(1) no_of_recs, Number, Inactive 
						from [dbo].[#TempTooling]
						where Inactive = 0
						group by Number, Inactive
						having COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 0
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_Tooling_Number|' +  CONVERT(varchar, @DupeActiveRecs);
				END
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
		SET @blockName = 'UpdateTooling'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update TI 
			set 
				DieSize				= T.DieSize,
				GearTeeth			= T.GearTeeth,
				Location			= T.Location,
				FlexoHotStamping	= T.Flexo_HotS,
				LinerCaliper		= T.LinerCaliper,
				Shape				= T.Shape,
				IsEnabled			= CASE WHEN T.Inactive = 0 THEN 1 ELSE 0 END,
				AvailableQuantity	= Case WHEN T.Shape LIKE '%Print Cylinder%' THEN T.Quantity ELSE T.ToolIn END,
				ToolType			= Case WHEN T.Shape LIKE '%Print Cylinder%' THEN 'Cylinder' ELSE 'Tool' END,
				FacilityId			= NULL,
				SourceCreatedOn		= CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
				SourceModifiedOn	= CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
				ModifiedOn			= GETUTCDATE(),
				Pitch				= T.Pitch,
				[NoAround]			= [T].[NoAround],
				[NoAcross]			= [T].[NoAcross],
				[SizeAcross]		= [T].[SizeAcross],
				[SizeAround]		= [T].[SizeAround],
				[ToolIn]			= [T].[ToolIn]
			from ToolingInventory TI
			inner join [dbo].[#TempTooling] T on T.Number = TI.SourceToolingId and TI.Source = 'LabelTraxx'
			where @Since IS NULL
			OR T.UpdateTimeDateStamp >= @Since

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
		SET @blockName = 'InsertTooling'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into ToolingInventory(
				Id, TenantId, Source, SourceToolingId, DieSize, GearTeeth, Location, FlexoHotStamping, SourceCreatedOn, SourceModifiedOn,
				IsEnabled, CreatedOn, ModifiedOn, LinerCaliper, Shape, AvailableQuantity, ToolType, FacilityId, Pitch,
				NoAround, NoAcross, SizeAcross, SizeAround, ToolIn)
			select 
				NEWID() ID,
				@TenantId TenantId,
				'LabelTraxx' Source,
				Number SourceToolingId,
				DieSize DieSize,
				GearTeeth GearTeeth,
				Location Location,
				Flexo_HotS FlexoHotStamping,
				CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
				CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
				0 IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				LinerCaliper,
				Shape,
				Case WHEN Shape LIKE '%Print Cylinder%' THEN Quantity ELSE ToolIn END,
				Case WHEN Shape LIKE '%Print Cylinder%' THEN 'Cylinder' ELSE 'Tool' END,
				null, --to support multi facility in future
				Pitch,
				[NoAround],
				[NoAcross],
				[SizeAcross],
				[SizeAround],
				[ToolIn]
			from 
				[dbo].[#TempTooling]
			where 
				Number not in (select SourceToolingId from ToolingInventory where Source = 'LabelTraxx') 
				and Number is not null	
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (select COUNT(1) from [dbo].[#TempTooling] where Number not in (select SourceToolingId from ToolingInventory where Source = 'LabelTraxx') and Number is null)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Tooling_Number|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
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

