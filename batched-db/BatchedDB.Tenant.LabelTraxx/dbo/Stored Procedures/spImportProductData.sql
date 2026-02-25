CREATE PROCEDURE [dbo].[spImportProductData]
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
		@spName					varchar(100) = 'spImportProductData',
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
		SET @blockName = 'DuplicateProductCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @duplicateRecs int = 
			(
				SELECT COUNT(1) FROM (
					select COUNT(1) no_of_recs, UniqueProdID 
					from Product 
					group by UniqueProdID
					having COUNT(1) > 1
				) DupeCounter
			)
			SET @infoStr = 'TotalDuplicates_Product_UniqueProdID|' +  CONVERT(varchar, @duplicateRecs);
			IF @duplicateRecs > 1 
			BEGIN
				SET @warningStr = @infoStr
				SET @infoStr = NULL;

				DECLARE @DupeActiveRecs int = 
				(
					SELECT COUNT(1) FROM (
						select COUNT(1) no_of_recs, UniqueProdID, Inactive 
						from Product
						where Inactive = 0
						group by UniqueProdID, Inactive
						having COUNT(1) > 1
					) DupeCounter
				)
				
				IF @DupeActiveRecs > 1 
				BEGIN
					SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_Product_UniqueProdID|' +  CONVERT(varchar, @DupeActiveRecs);
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

	-- NULL CHECK BLOCK
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'NullProductCheck'; SET @startTime = GETDATE();
		Begin TRY			
			DECLARE @NullRecs int = 
			(
				SELECT COUNT(1) FROM Product where UniqueProdID is null
			)
			SET @infoStr = 'TotalNullRecords_Product_UniqueProdID|' +  CONVERT(varchar, @NullRecs);
			IF @NullRecs > 1 
			BEGIN
				SET @warningStr = @infoStr;
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
		SET @blockName = 'UpdateProducts'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			update PM 
			set 
				PM.ColorDesc = P.COLORDESCR, 
				PM.SourceProductGroup = P.PRODGROUP,
				PM.ToolingNotes = P.ToolingNotes,
				PM.SlitOnRewind = P.SlitOnRewind,
				PM.NumColors = P.NOOFCOLORS,
				PM.NumFloods = P.NOFLOODS,
				PM.ProductNum = P.PRODNUM,
				PM.PlateId = P.PLATE_ID,
				PM.CustomField1 = P.POPUPNAME1,
				PM.CriticalQuality = P.CRITICALQUALITY,
				PM.ProdDescr = P.DESCRIPTION,
				PM.MaterialTrac = P.MATERIALTRAC,
				PM.ColumnPerf = P.COLUMNPERF,
				PM.RowPerf = P.ROWPERF,
				PM.ProductGroupId = P.GROUP_ID,
				PM.IsEnabled = (case when P.INACTIVE = 0 then 1 else 0 end),
				SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
				SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
				ModifiedOn = GETUTCDATE(),
				ProductPopup1 = FPUD_POPUP1,
				ProductPopup2 = FPUD_POPUP2,
				ProductPopup3 = FPUD_POPUP3,
				ProductPopup4 = FPUD_POPUP4,
				ProductPopup5 = FPUD_POPUP5,
				ProductPopup6 = FPUD_POPUP6,
				JobType = P.JOBTYPE,
				ProductType = P.PRODGROUP,
				SheetPackType = P.SHEETPACKTYPE,
				CoreWidth = P.CoreWidth,
				Notes = P.Notes,
				FinishedWidth = P.SIZEACROSS,
				FinishedLength = p.SIZEAROUND,
				PM.EquipNoColors = P.EQUIP_NOCOLORS,
				PM.EquipNoFloods = P.EQUIP_NOFLOODS,
				PM.RevisionNumber = P.REVISIONNO
			from ProductMaster PM
				inner join Product P on P.UniqueProdID = PM.SourceProductId
			where @Since IS NULL OR P.UpdateTimeDateStamp >= @Since

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
		SET @blockName = 'InsertProducts'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			insert into ProductMaster (Id,TenantId,Source,SourceProductId,ColorDesc,SourceProductGroup,ToolingNotes,SlitOnRewind,NumColors,NumFloods,ProductNum,PlateId,CustomField1,CriticalQuality,ProdDescr,MaterialTrac,ColumnPerf,RowPerf,SourceCreatedOn,SourceModifiedOn,IsEnabled,CreatedOn,ModifiedOn,ProductGroupId, ProductPopup1, ProductPopup2, ProductPopup3, ProductPopup4, ProductPopup5, ProductPopup6, JobType, ProductType, SheetPackType, CoreWidth, Notes, FinishedWidth, FinishedLength, EquipNoColors, EquipNoFloods, RevisionNumber)
			select 
				NEWID() ID,
				@TenantId TenantId,
				'LabelTraxx' Source,
				Product.UniqueProdID SourceProductId,
				COLORDESCR ColorDesc,
				PRODGROUP SourceProductGroup,
				ToolingNotes ToolingNotes,
				SlitOnRewind SlitOnRewind,
				NOOFCOLORS NumColors,
				NOFLOODS NumFloods,
				PRODNUM ProductNum,
				PLATE_ID PlateId,
				POPUPNAME1 CustomField1,
				CRITICALQUALITY CriticalQuality,
				DESCRIPTION ProdDescr,
				MATERIALTRAC MaterialTrac,
				COLUMNPERF ColumnPerf,
				ROWPERF RowPerf,
				CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
				CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
				CASE WHEN INACTIVE = 1 THEN 0 ELSE 1 END IsEnabled,
				GETUTCDATE() CreatedOn,
				GETUTCDATE() ModifiedOn,
				GROUP_ID ProductGroupId,
				FPUD_POPUP1 ProductPopup1,
				FPUD_POPUP2 ProductPopup2,
				FPUD_POPUP3 ProductPopup3,
				FPUD_POPUP4 ProductPopup4,
				FPUD_POPUP5 ProductPopup5,
				FPUD_POPUP6 ProductPopup6,
				Product.JOBTYPE,
				Product.PRODGROUP,
				Product.SHEETPACKTYPE,
				Product.CoreWidth,
				Product.Notes,
				Product.SIZEACROSS,			-- FinishedWidth
				Product.SIZEAROUND,			-- FinishedLength
				Product.EQUIP_NOCOLORS,		-- EquipNoColors
				Product.EQUIP_NOFLOODS,		-- EquipNoFloods
				Product.REVISIONNO			-- Product RevisionNumber
			from 
				Product
			where 
				Product.UniqueProdID not in (select SourceProductId from ProductMaster where Source = 'LabelTraxx') 
				and Product.UniqueProdID is not null	
				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)


			DECLARE @nullProducts int = (select COUNT(1) from Product where UniqueProdID not in (select SourceProductId from ProductMaster where Source = 'LabelTraxx') and UniqueProdID is null)
			IF @nullProducts > 0
			BEGIN
				SET @warningStr = 'NullRows_Product_UniqueProdID|' +  CONVERT(varchar, @nullProducts) + '#' + @infoStr;
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
