CREATE PROCEDURE [dbo].[spImportTicketData]
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
		@spName					varchar(100) = 'spImportTicketData',
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

    -- Get default facility id
    Declare @FacilityId varchar(36) = (SELECT TOP 1 [ID] FROM [dbo].[Facility] WITH(NOLOCK)
			                            WHERE [IsEnabled] = 1 ORDER BY [CreatedOnUTC]);

    -- Matching id in temporary table
    SELECT ticMaster.Id as TicketId, tic.Number as TicketNumber
    INTO #MatchingTickets
    FROM TicketMaster ticMaster INNER JOIN Ticket tic
        ON tic.Number = ticMaster.SourceTicketId AND tic.Number IS NOT NULL
    WHERE ticMaster.Source = 'LabelTraxx' AND ticMaster.TenantId = @TenantId

    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0	
	  	BEGIN
        SET @blockName = 'UpdateTickets'; SET @startTime = GETDATE();

        Begin TRY		
					-- Update the records
			Update TicketMaster 
			set
				OrderDate = T1.OrderDate,
				SourceCustomerId = T1.CustomerNum,
				CustomerName = T1.CustomerName,
				CustomerPO = T1.CustPONum,
				SourcePriority = T1.Priority,
				SourceFinishType = T1.FinishType,
				isBackSidePrinted = T1.TurnBar,
				isSlitOnRewind = T1.SlitOnRewind,
				UseTurretRewinder = T1.Use_TurretRewinder,
				EstTotalRevenue = T1.EstTotal,
				SourceTicketType = T1.TicketType,
				SourceStockTicketType = T1.StockTicketType,
				PriceMode = T1.PriceMode,
				FinalUnwind = T1.FinalUnwind,
				IsOpen = CASE WHEN T1.TicketStatus <> 'Done' THEN 1 ELSE 0 END ,
				SourceStatus = T1.TicketStatus,
				IsOnHold = CASE WHEN T1.TicketStatus in ('Hold','Credit Hold')  THEN 1 ELSE 0 END,
				BackStageColorStrategy = T1.BackStage_ColorStrategy,
				Pinfeed = T1.Pinfeed,
				GeneralDescription = T1.GeneralDescr,
				IsPrintReversed = T1.IsPrintReversed,
				SourceTicketNotes = T1.Notes,
				EndUserNum = T1.EndUserNum,
				EndUserName = T1.EndUserName,
				Tab = T1.Tab,
				SizeAround = T1.SizeAround,
				ShrinkSleeveLayFlat = T1.ShrinkSleeve_LayFlat,
				Shape = T1.Shape,
				InkStatus = T1.Ink_Status,
				SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), T1.EntryDate, 112) + ' ' + CONVERT(CHAR(8), T1.EntryTime, 108)),
				SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), T1.ModifyDate, 112) + ' ' + CONVERT(CHAR(8), T1.ModifyTime, 108)),
				ModifiedOn = GETUTCDATE(),
				ITSName = T1.ITSName,
				OTSName = T1.OTSName,
				ITSAssocNum = T1.ITSAssocNum,
				OTSAssocNum = T1.OTSAssocNum,
				DateDone = T1.DateDone,
				EndUserPO = T1.EndUserPO,
				IsStockAllocated= T1.Stock_Allocated,
				EstPackHrs = T1.EstPackHrs,
				ActPackHrs = T1.ActPackHrs,
				CustContact = T1.CustContact,
				FinishNotes = T1.FinishNotes,
				StockNotes = T1.StockNotes,
				CreditHoldOverride = T1.CreditHoldOverride,
				ShrinkSleeveOverLap = T1.ShrinkSleeve_OverLap,
				ShrinkSleeveCutHeight = T1.ShrinkSleeve_CutHeight,
				Terms = T1.Terms,
				RotoQuoteNumber = T1.Roto_Quote_Number,
				PlateStatus = T1.PlateStat,
				FlexPackGusset = T1.FlexPack_Gusset,
				FlexPackHeight = T1.FlexPack_Height,
				EstPostPressHours = T1.EstPostPressHours,
				CoreType = T1.CoreType,
				DependentSourceTicketId = T2.Number,
				TicketCategory = (CASE WHEN T1.PrevJobNum IS NOT NULL AND T1.SubTicket = 1 THEN 2 WHEN T2.Number IS NOT NULL THEN 1 ELSE 0 END),
				ShipStatus = T1.ShipStat,
				Press_Status = T1.PressStat,
				InternetSubmission = T1.Internet_Submission,
				SourceCompanyId = NULL,
				SourceFacilityId = NULL,
				TicketRowspace = T1.RowSpace,
				FinishStatus = T1.FinishStat,
				EnteredBy = T1.EntryBy,
				PreviousTicketNumber = T1.PrevJobNum,

				
				-- PRESS DETAILS
				Press = T1.Press,
				PressDone = T1.PressDone,
				EstTime = T1.EstPressTime,
				EstRunHrs = T1.EstRunHrs,
				EstWuHrs = T1.EstWuHrs,
				EstMRHrs = T1.EstMRHrs,

				-- EQUIP DETAILS
				EquipId = T1.Equip_ID,
				EquipDone = T1.Equip_Done,
				EquipEstTime = T1.Equip_EstTime,
				EquipEstRunHrs = T1.Equip_EstRunHrs,
				EquipWashUpHours = T1.Equip_WashUpHours,
				EquipMakeReadyHours = T1.Equip_MakeReadyHours,

				-- EQUIP3 DETAILS
				Equip3Id = T1.Equip3_ID,
				Equip3Done = T1.Equip3_Done,
				Equip3EstTime = T1.Equip3_EstTime,
				Equip3EstRunHrs = T1.Equip3_EstRunHrs,
				Equip3WashUpHours = T1.Equip3_WashUpHours,
				Equip3MakeReadyHours = T1.Equip3_MakeReadyHours,

				-- EQUIP4 DETAILS
				Equip4Id = T1.Equip4_ID,
				Equip4Done= T1.Equip4_Done,
				Equip4EstTime = T1.Equip4_EstTime,
				Equip4EstRunHrs = T1.Equip4_EstRunHrs,
				Equip4WashUpHours = T1.Equip4_WashUpHours,
				Equip4MakeReadyHours = T1.Equip4_MakeReadyHours,
				
				-- EQUIP5 DETAILS
				Equip5Id = T1.Equip5_ID,
				Equip5Done = T1.Equip5_Done,
				Equip5EstTime = T1.Equip5_EstTime,
				Equip5EstRunHrs = T1.Equip5_EstRunHrs,
				Equip5WashUpHours = T1.Equip5_WashUpHours,
				Equip5MakeReadyHours = T1.Equip5_MakeReadyHours,

				-- EQUIP6 DETAILS
				Equip6Id = T1.Equip6_ID,
				Equip6Done = T1.Equip6_Done,
				Equip6EstTime = T1.Equip6_EstTime,
				Equip6EstRunHrs = T1.Equip6_EstRunHrs,
				Equip6WashUpHours = T1.Equip6_WashUpHours,
				Equip6MakeReadyHours = T1.Equip6_MakeReadyHours,

				-- EQUIP7 DETAILS (NEW REWINDER - FOR LABELTRAXX)
				Equip7Id = T1.RewindEquipNum,
				Equip7Done = T1.FinishDone,
				Equip7EstTime = T1.EstFinHrs,
				Equip7EstRunHrs = T1.EstFinHrs,
				Equip7WashUpHours = T1.EstWuHrs,
				Equip7MakeReadyHours = T1.EstMRHrs,

				-- REWINDER DETAILS
				RewindEquipNum = T1.RewindEquipNum,
				FinishDone = T1.FinishDone,
				EstFinHrs = T1.EstFinHrs,

                -- Facility Mapping
                FacilityId = ISNULL(F.ID, @FacilityId),

                -- Estimated Press Speed Mapping
                EstimatedPressSpeed = T1.EstPressSpd

			from
            TicketMaster ticMaster INNER JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
            INNER JOIN Ticket T1 ON T1.Number = ticMaster.SourceTicketId AND T1.Number IS NOT NULL
            LEFT JOIN Ticket T2
            ON T1.Number = T2.PrevJobNum
                AND T2.SubTicket = 1
                AND (CASE WHEN T1.Number LIKE '%-%' THEN LEFT(T1.Number, CHARINDEX('-', T1.Number) - 1) ELSE T1.Number END) = (CASE WHEN T2.Number LIKE '%-%' THEN LEFT(T2.Number, CHARINDEX('-', T2.Number) - 1) ELSE T2.Number END)
            LEFT JOIN (
                        SELECT SourceFacilityId, MIN(ID) AS ID
                        FROM Facility
                        WHERE SourceFacilityId IS NOT NULL
                        GROUP BY SourceFacilityId
                      ) F ON F.SourceFacilityId = T1.Tag
			where @Since IS NULL
            OR T1.UpdateTimeDateStamp >= @Since
            OR T2.UpdateTimeDateStamp >= @Since

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
        SET @blockName = 'InsertTickets'; SET @startTime = GETDATE();

        Begin TRY
			-- Insert the new records
			INSERT INTO [dbo].[TicketMaster] ([ID], [Source], [SourceTicketId], [TenantId], [OrderDate], [SourceCustomerId], [CustomerName], [CustomerPO], [SourcePriority],
            [SourceFinishType], [isBackSidePrinted], [IsSlitOnRewind], [UseTurretRewinder], [EstTotalRevenue], [SourceTicketType], [SourceStockTicketType], [PriceMode], [FinalUnwind],
            [IsOpen], [SourceStatus], [IsOnHold], [BackStageColorStrategy], [Pinfeed], [GeneralDescription], [IsPrintReversed], [SourceTicketNotes], [EndUserNum], [EndUserName],
            [Tab], [SizeAround], [ShrinkSleeveLayFlat], [Shape], [SourceCreatedOn], [SourceModifiedOn], [CreatedOn], [ModifiedOn], [InkStatus], [ITSName], [OTSName], [ITSAssocNum],
            [OTSAssocNum], [DateDone], [EndUserPO], [IsStockAllocated], [EstPackHrs], [ActPackHrs], [CustContact], [FinishNotes], [StockNotes], [CreditHoldOverride], [ShrinkSleeveOverLap],
            [ShrinkSleeveCutHeight], [Terms], [RotoQuoteNumber], [PlateStatus], [FlexPackGusset], [FlexPackHeight], [EstPostPressHours], [CoreType], [DependentSourceTicketId],
            [TicketCategory], [ShipStatus], [Press_Status], [InternetSubmission], [SourceCompanyId], [SourceFacilityId], [TicketRowspace], [FinishStatus], [EnteredBy], [PreviousTicketNumber],

            [Press], [PressDone], [EstTime], [EstRunHrs], [EstWuHrs], [EstMRHrs],
            [EquipId], [EquipDone], [EquipEstTime], [EquipEstRunHrs], [EquipWashUpHours], [EquipMakeReadyHours],
            [Equip3Id], [Equip3Done], [Equip3EstTime], [Equip3EstRunHrs], [Equip3WashUpHours], [Equip3MakeReadyHours],
            [Equip4Id], [Equip4Done], [Equip4EstTime], [Equip4EstRunHrs], [Equip4WashUpHours], [Equip4MakeReadyHours],
            [Equip5Id], [Equip5Done], [Equip5EstTime], [Equip5EstRunHrs], [Equip5WashUpHours], [Equip5MakeReadyHours],
            [Equip6Id], [Equip6Done], [Equip6EstTime], [Equip6EstRunHrs], [Equip6WashUpHours], [Equip6MakeReadyHours],
            [Equip7Id], [Equip7Done], [Equip7EstTime], [Equip7EstRunHrs], [Equip7WashUpHours], [Equip7MakeReadyHours],
            [RewindEquipNum], [FinishDone], [EstFinHrs], [FacilityId], [EstimatedPressSpeed])

        SELECT
            NEWID(),
            'LabelTraxx',
            T1.Number,
            @TenantId,
            T1.OrderDate,
            T1.CustomerNum,
            T1.CustomerName,
            T1.CustPONum,
            T1.Priority,
            T1.FinishType,
            T1.TurnBar,
            T1.SlitOnRewind,
            T1.Use_TurretRewinder,
            T1.EstTotal,
            T1.TicketType,
            T1.StockTicketType,
            T1.PriceMode,
            T1.FinalUnwind,
            CASE WHEN T1.TicketStatus <> 'Done' THEN 1 ELSE 0 END AS IsOpen,
            T1.TicketStatus,
            CASE WHEN T1.TicketStatus in ('Hold','Credit Hold')  THEN 1 ELSE 0 END AS IsOnHold,
            T1.BackStage_ColorStrategy,
            T1.Pinfeed,
            T1.GeneralDescr,
            T1.IsPrintReversed,
            T1.Notes,
            T1.EndUserNum,
            T1.EndUserName,
            T1.Tab,
            T1.SizeAround,
            T1.ShrinkSleeve_LayFlat,
            T1.Shape,
            CONVERT(DATETIME, CONVERT(CHAR(8), T1.EntryDate, 112) + ' ' + CONVERT(CHAR(8), T1.EntryTime, 108)),
            CONVERT(DATETIME, CONVERT(CHAR(8), T1.ModifyDate, 112) + ' ' + CONVERT(CHAR(8), T1.ModifyTime, 108)),
            GETUTCDATE(),
            GETUTCDATE(),
            T1.Ink_Status,
            T1.ITSName,
            T1.OTSName,
            T1.ITSAssocNum,
            T1.OTSAssocNum,
            T1.DateDone,
            T1.EndUserPO,
            T1.Stock_Allocated,
            T1.EstPackHrs,
            T1.ActPackHrs,
            T1.CustContact,
            T1.FinishNotes,
            T1.StockNotes,
            T1.CreditHoldOverride,
            T1.ShrinkSleeve_OverLap,
            T1.ShrinkSleeve_CutHeight,
            T1.Terms,
            T1.Roto_Quote_Number,
            T1.PlateStat,
            T1.FlexPack_Gusset,
            T1.FlexPack_Height,
            T1.EstPostPressHours,
            T1.CoreType,
            T2.Number,
            (CASE WHEN T1.PrevJobNum IS NOT NULL AND T1.SubTicket = 1 THEN 2 WHEN T2.Number IS NOT NULL THEN 1 ELSE 0 END),
            T1.ShipStat,
            T1.PressStat,
            T1.Internet_Submission,
            NULL, --SourceFacilityId
            NULL, --SourceCompanyId
            T1.RowSpace,
            T1.FinishStat,
            T1.EntryBy,
            T1.PrevJobNum,

            -- PRESS DETAILS
            T1.Press,
            T1.PressDone,
            T1.EstPressTime,
            T1.EstRunHrs,
            T1.EstWuHrs,
            T1.EstMRHrs,

            -- EQUIP DETAILS
            T1.Equip_ID,
            T1.Equip_Done,
            T1.Equip_EstTime,
            T1.Equip_EstRunHrs,
            T1.Equip_WashUpHours,
            T1.Equip_MakeReadyHours,

            -- EQUIP3 DETAILS
            T1.Equip3_ID,
            T1.Equip3_Done,
            T1.Equip3_EstTime,
            T1.Equip3_EstRunHrs,
            T1.Equip3_WashUpHours,
            T1.Equip3_MakeReadyHours,

            -- EQUIP4 DETAILS
            T1.Equip4_ID,
            T1.Equip4_Done,
            T1.Equip4_EstTime,
            T1.Equip4_EstRunHrs,
            T1.Equip4_WashUpHours,
            T1.Equip4_MakeReadyHours,

            -- EQUIP5 DETAILS
            T1.Equip5_ID,
            T1.Equip5_Done,
            T1.Equip5_EstTime,
            T1.Equip5_EstRunHrs,
            T1.Equip5_WashUpHours,
            T1.Equip5_MakeReadyHours,

            -- EQUIP6 DETAILS
            T1.Equip6_ID,
            T1.Equip6_Done,
            T1.Equip6_EstTime,
            T1.Equip6_EstRunHrs,
            T1.Equip6_WashUpHours,
            T1.Equip6_MakeReadyHours,

            -- EQUIP7 DETAILS (NEW REWINDER - FOR LABELTRAXX)
            T1.RewindEquipNum,
            T1.FinishDone,
            T1.EstFinHrs,
            T1.EstFinHrs,
            T1.EstWuHrs,
            T1.EstMRHrs,

            -- REWINDER DETAILS
            T1.RewindEquipNum,
            T1.FinishDone,
            T1.EstFinHrs,

            -- Facility Mapping
            ISNULL(F.ID, @FacilityId),

            -- Estimated Press Speed Mapping
            T1.EstPressSpd

        FROM Ticket T1
            LEFT JOIN Ticket T2
            ON T1.Number = T2.PrevJobNum
                AND T2.SubTicket = 1
                AND (CASE WHEN T1.Number LIKE '%-%' THEN LEFT(T1.Number, CHARINDEX('-', T1.Number) - 1) ELSE T1.Number END) = (CASE WHEN T2.Number LIKE '%-%' THEN LEFT(T2.Number, CHARINDEX('-', T2.Number) - 1) ELSE T2.Number END)
            LEFT JOIN (
                    SELECT SourceFacilityId, MIN(ID) AS ID
                    FROM Facility
                    WHERE SourceFacilityId IS NOT NULL
                    GROUP BY SourceFacilityId
                ) F ON F.SourceFacilityId = T1.Tag
        Where T1.Number NOT IN (select TicketNumber from #MatchingTickets)
            AND T1.Number IS NOT NULL

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END

    -- Delete temporary table
    DROP TABLE IF EXISTS #MatchingTickets
	
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
