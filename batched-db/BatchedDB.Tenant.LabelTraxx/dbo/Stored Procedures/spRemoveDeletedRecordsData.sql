CREATE PROCEDURE [dbo].[spRemoveDeletedRecordsData]
	@TenantId		nvarchar(36),
	@CorelationId	varchar(100),
	@ProcessRulesEngine	bit = 0
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spRemoveDeletedRecordsData',
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

	-- Remove Deleted Tickets From Dependent tables of TicketMaster
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'TicketMasterDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				DROP TABLE IF EXISTS #DeletedTickets
				DROP TABLE IF EXISTS #DeletedTicketStockAvailability

				SELECT TM.SourceTicketId, TM.ID AS TicketID
				INTO #DeletedTickets
				FROM TicketMaster TM
				WHERE NOT EXISTS (
					SELECT 1
					FROM Ticket T
					WHERE T.Number = TM.SourceTicketId
				);

				IF EXISTS (SELECT 1 FROM #DeletedTickets)
				BEGIN
					SELECT TSA.TicketId, TSA.Id AS TicketStockAvailabilityId
						INTO #DeletedTicketStockAvailability
						FROM TicketStockAvailability TSA
						LEFT JOIN #DeletedTickets DT
						ON DT.TicketID = TSA.TicketId

					DELETE SAP
						FROM TicketStockAvailabilityPO SAP
						INNER JOIN #DeletedTicketStockAvailability DTSA
						ON SAP.TicketStockAvailabilityId = DTSA.TicketStockAvailabilityId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO|' +  CONVERT(varchar, @@ROWCOUNT)


					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
						INNER JOIN #DeletedTicketStockAvailability DTSA
						ON RMT.TicketStockAvailabilityId = DTSA.TicketStockAvailabilityId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets_temp RMT
						INNER JOIN #DeletedTicketStockAvailability DTSA
						ON RMT.TicketStockAvailabilityId = DTSA.TicketStockAvailabilityId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets_temp|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSA
						FROM TicketStockAvailability TSA
						INNER JOIN #DeletedTickets DT
						ON TSA.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailability|' +  CONVERT(varchar, @@ROWCOUNT)
					
					DELETE TSA
						FROM TicketStockAvailability_temp TSA
						INNER JOIN #DeletedTickets DT
						ON TSA.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailability_temp|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
						INNER JOIN TicketItemInfo TII 
							ON RMT.TicketItemInfoId = TII.Id
						INNER JOIN #DeletedTickets DT
							ON TII.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TII
						FROM TicketItemInfo TII
						INNER JOIN #DeletedTickets DT
						ON TII.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TN
						FROM TicketNote TN
						INNER JOIN #DeletedTickets DT
						ON TN.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketNote|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTK
						FROM TicketTask TTK
						INNER JOIN #DeletedTickets DT
						ON TTK.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTask|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete from Ticket Task Temp
					DELETE TTK
						FROM TicketTask_temp TTK
						INNER JOIN #DeletedTickets DT
						ON TTK.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTask_temp|' +  CONVERT(varchar, @@ROWCOUNT)
					
					DELETE TCI
						FROM TimecardInfo TCI
						INNER JOIN #DeletedTickets DT
						ON TCI.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TimecardInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSH
						FROM TicketShipping TSH
						INNER JOIN #DeletedTickets DT
						ON TSH.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketShipping|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TST
						FROM TicketStock TST
						INNER JOIN #DeletedTickets DT
						ON TST.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStock|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TPP
						FROM TicketPreProcess TPP
						INNER JOIN #DeletedTickets DT
						ON TPP.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketPreProcess|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTL
						FROM TicketTool TTL
						INNER JOIN #DeletedTickets DT
						ON TTL.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTool|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSC
						FROM TicketScore TSC
						INNER JOIN #DeletedTickets DT
						ON TSC.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketScore|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TD
						FROM TicketDimensions TD
						INNER JOIN #DeletedTickets DT
						ON TD.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketDimensions|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE OTC
						FROM OpenTicketColorsV2 OTC
						INNER JOIN #DeletedTickets DT
						ON OTC.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_OpenTicketColorsV2|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TGN
						FROM TicketGeneralNotes TGN
						INNER JOIN #DeletedTickets DT
						ON TGN.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketGeneralNotes|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTO
						FROM TicketTaskOverride TTO
						INNER JOIN #DeletedTickets DT
						ON TTO.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTaskOverride|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTD
                        FROM Tickettaskdependency TTD
                        INNER JOIN TicketTaskData TT ON TT.Id = TTD.DependentTicketTaskDataId
                        INNER JOIN #DeletedTickets DT ON TT.TicketId = DT.TicketID
                    SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTaskDependantData|' +  CONVERT(varchar, @@ROWCOUNT)
					
					DELETE TTD
						FROM Tickettaskdependency TTD
						INNER JOIN TicketTaskData TT ON TT.Id = TTD.TicketTaskDataId
						INNER JOIN #DeletedTickets DT ON TT.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTaskDependencyData|' +  CONVERT(varchar, @@ROWCOUNT)
					
					DELETE TTD
						FROM TicketTaskData TTD
						INNER JOIN #DeletedTickets DT
						ON TTD.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTaskData|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSO
						FROM TicketStockOverride TSO
						INNER JOIN #DeletedTickets DT
						ON TSO.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockOverrides|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE RTA
						FROM ReservationTaskAllocation RTA
						INNER JOIN #DeletedTickets DT
						ON RTA.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ReservationTaskAllocation|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTSI
						FROM TicketTaskStagingInfo TTSI
						INNER JOIN #DeletedTickets DT
						ON TTSI.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTaskStagingInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE SO
						FROM ScheduleOverride SO
						INNER JOIN #DeletedTickets DT
						ON SO.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ScheduleOverride|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete TicketUserDefined options
					DELETE TUDO
						FROM TicketUserDefinedOptions TUDO
						INNER JOIN #DeletedTickets DT
						ON TUDO.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketUserDefinedOptions|' +  CONVERT(varchar, @@ROWCOUNT)
 

					-- Delete from Ticket Master
					DELETE TM
						FROM TicketMaster TM
						INNER JOIN #DeletedTickets DT
						ON TM.Id = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketMaster|' +  CONVERT(varchar, @@ROWCOUNT)

				END
			
				-- Drop Temporary Tables
				DROP TABLE IF EXISTS #DeletedTicketStockAvailability
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Dependent tables of StockProductMaster
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'StockProductMasterDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				DROP TABLE IF EXISTS #DeletedStockProducts

				SELECT 
					SPM.SourceStockProductId, 
					SPM.Id AS StockProductID
				INTO #DeletedStockProducts
				FROM StockProductMaster SPM
				WHERE NOT EXISTS (
					SELECT 1
					FROM StockProduct SP
					WHERE SP.Id = SPM.SourceStockProductId);


				IF EXISTS (SELECT 1 FROM #DeletedStockProducts)
				BEGIN

					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
						INNER JOIN TicketItemInfo TII
							ON RMT.TicketItemInfoId = TII.Id
						INNER JOIN #DeletedStockProducts DSP
							ON TII.StockProductId = DSP.StockProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TII
						FROM TicketItemInfo TII
						INNER JOIN #DeletedStockProducts DSP
						ON TII.StockProductId = DSP.StockProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete from Stock Product Master
					DELETE SPM
						FROM StockProductMaster SPM
						INNER JOIN #DeletedStockProducts DSP
						ON SPM.Id = DSP.StockProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)
				END

				-- Drop Temporary Table #DeletedStockProducts
				DROP TABLE IF EXISTS #DeletedStockProducts
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Dependent tables of ProductMaster
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'ProductMasterDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				DROP TABLE IF EXISTS #DeletedProducts
				DROP TABLE IF EXISTS #DeleteStockProducts
                
				SELECT PM.SourceProductId, PM.Id AS ProductID
				INTO #DeletedProducts
				FROM ProductMaster PM
				WHERE NOT EXISTS (
					SELECT 1
					FROM Product P
					WHERE P.UniqueProdID = PM.SourceProductId
				);
                
				IF EXISTS (SELECT 1 FROM #DeletedProducts)
                BEGIN                
					DELETE PCI
                        FROM ProductColorInfo PCI
                        INNER JOIN #DeletedProducts DP
                        ON PCI.ProductId = DP.ProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ProductColorInfo|' +  CONVERT(varchar, @@ROWCOUNT)

					SELECT spm.Id
						INTO #DeleteStockProducts
						FROM StockProductMaster SPM
                        INNER JOIN #DeletedProducts DP
                        ON SPM.ProductId = DP.ProductID
                    
					Delete RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
                        INNER JOIN TicketItemInfo TII
							ON RMT.TicketItemInfoId = TII.Id
                        INNER JOIN #DeleteStockProducts DP
							ON TII.StockProductId = DP.Id
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets-StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					Delete RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
                        INNER JOIN TicketItemInfo TII
							ON RMT.TicketItemInfoId = TII.Id
                        INNER JOIN #DeletedProducts DP
							ON TII.ProductId = DP.ProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets-ProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					Delete TII
                        FROM TicketItemInfo TII
                        INNER JOIN #DeleteStockProducts DP
                        ON TII.StockProductId = DP.Id
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo-StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)
                    
					DELETE TII
                        FROM TicketItemInfo TII
                        INNER JOIN #DeletedProducts DP
                        ON TII.ProductId = DP.ProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo-ProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)
                    
					DELETE SPM
                        FROM StockProductMaster SPM
                        INNER JOIN #DeletedProducts DP
                        ON SPM.ProductId = DP.ProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete from Product Master
                    DELETE PM
                        FROM ProductMaster PM
                        INNER JOIN #DeletedProducts DP
                        ON PM.Id = DP.ProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)
                END
                
				-- Drop Temporary Table #DeletedProducts
                DROP TABLE IF EXISTS #DeletedProducts
				DROP TABLE IF EXISTS #DeleteStockProducts

			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END
	

	-- Remove Deleted Tickets From Dependent tables of Tooling Inventory
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'ToolingInventoryDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				DROP TABLE IF EXISTS #DeletedTools

				SELECT TI.SourceToolingId, TI.Id AS ToolID
				INTO #DeletedTools
				FROM ToolingInventory TI
				WHERE NOT EXISTS (
					SELECT 1
					FROM Tooling T
					WHERE T.Number = TI.SourceToolingId
				);

				IF EXISTS (SELECT 1 FROM #DeletedTools)
				BEGIN
					DELETE TT
						FROM TicketTool TT
						INNER JOIN #DeletedTools DT
						ON TT.ToolingId = DT.ToolID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTool|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete from Tooling Inventory
					DELETE TI
						FROM ToolingInventory TI
						INNER JOIN #DeletedTools DT
						ON TI.Id = DT.ToolID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ToolingInventory|' +  CONVERT(varchar, @@ROWCOUNT)
				END

				-- Drop Temporary Table #DeletedTools
				DROP TABLE IF EXISTS #DeletedTools
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Dependent tables of Stock Material
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'StockMaterialDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				DROP TABLE IF EXISTS #DeletedStockMaterial
				DROP TABLE IF EXISTS #DeletedPurchaseOrderItem
				DROP TABLE IF EXISTS #DeletedTicketStockAvailabilityData

				SELECT SM.SourceStockId, SM.Id AS StockMaterialID
				INTO #DeletedStockMaterial
				FROM StockMaterial SM
				WHERE NOT EXISTS (
					SELECT 1
					FROM Stock S
					WHERE S.StockNum = SM.SourceStockId
				);
					

				IF EXISTS (SELECT 1 FROM #DeletedStockMaterial)
				BEGIN
					SELECT TSA.OriginalStockMaterialId, TSA.Id AS TicketStockAvailabilityId
					INTO #DeletedTicketStockAvailabilityData
					FROM TicketStockAvailability TSA
					INNER JOIN #DeletedStockMaterial DSM
						ON DSM.StockMaterialID = TSA.OriginalStockMaterialId;

					DELETE SAP
						FROM TicketStockAvailabilityPO SAP
						INNER JOIN #DeletedTicketStockAvailabilityData DTSA
						ON SAP.TicketStockAvailabilityId = DTSA.TicketStockAvailabilityId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO_TSA|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
						INNER JOIN #DeletedTicketStockAvailabilityData DTSA
							ON RMT.TicketStockAvailabilityId = DTSA.TicketStockAvailabilityId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets_TSA|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSA
						FROM TicketStockAvailability TSA
						INNER JOIN #DeletedStockMaterial DSM
						ON TSA.OriginalStockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailability|' +  CONVERT(varchar, @@ROWCOUNT)


					SELECT POI.StockMaterialId, POI.Id AS PurchaseOrderItemId
					INTO #DeletedPurchaseOrderItem
					FROM PurchaseOrderItem POI
					INNER JOIN #DeletedStockMaterial DSM 
						ON DSM.StockMaterialID = POI.StockMaterialId;

					DELETE SAP
						FROM TicketStockAvailabilityPO SAP
						INNER JOIN #DeletedPurchaseOrderItem DPOI
						ON SAP.PurchaseOrderItemId = DPOI.PurchaseOrderItemId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO_POI|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE POI
						FROM PurchaseOrderItem POI
						INNER JOIN #DeletedStockMaterial DSM
						ON POI.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_PurchaseOrderItem|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE POM
						FROM PurchaseOrderMaster POM
						INNER JOIN #DeletedStockMaterial DSM
						ON POM.StockMaterialId is not NULL AND POM.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_PurchaseOrderMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TS
						FROM TicketStock TS
						INNER JOIN #DeletedStockMaterial DSM
						ON TS.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStock|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE SI
						FROM StockInventory SI
						INNER JOIN #DeletedStockMaterial DSM
						ON SI.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockInventory|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE SMS
						FROM StockMaterialSubstitute SMS
						INNER JOIN #DeletedStockMaterial DSM
						ON SMS.StockMaterialId = DSM.StockMaterialID
						OR SMS.AlternateStockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockMaterialSubstitute|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TSO
						FROM TicketStockOverride TSO
						INNER JOIN #DeletedStockMaterial DSM
						ON TSO.OverriddenStockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockOverrides|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE SICF
						FROM StockInventoryConfigFacilities SICF
						INNER JOIN StockInventoryConfiguration SIC ON SIC.Id = SICF.StockInventoryConfigId
						INNER JOIN #DeletedStockMaterial DSM ON SIC.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockInventoryConfigFacilities|' +  CONVERT(varchar, @@ROWCOUNT)
 
 
					DELETE SICD
						FROM StockInventoryConfigDimensions SICD
						INNER JOIN StockInventoryConfiguration SIC ON SIC.Id = SICD.StockInventoryConfigId
						INNER JOIN #DeletedStockMaterial DSM ON SIC.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockInventoryConfigDimensions|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE SIC
						FROM StockInventoryConfiguration SIC
						INNER JOIN #DeletedStockMaterial DSM
						ON SIC.StockMaterialId = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockInventoryConfiguraton|' +  CONVERT(varchar, @@ROWCOUNT)

					-- Delete from Stock Material
					DELETE SM
						FROM StockMaterial SM
						INNER JOIN #DeletedStockMaterial DSM
						ON SM.ID = DSM.StockMaterialID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockMaterial|' +  CONVERT(varchar, @@ROWCOUNT)
				END

				-- Drop Temporary Table
				DROP TABLE IF EXISTS #DeletedTicketStockAvailabilityData
				DROP TABLE IF EXISTS #DeletedPurchaseOrderItem
				DROP TABLE IF EXISTS #DeletedStockMaterial
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Stock Inventory
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'StockInventoryDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				-- Delete from Stock Inventory
				DELETE SI
				FROM StockInventory SI
				WHERE NOT EXISTS (
					SELECT 1
					FROM RollStock RS
					WHERE RS.PK_UUID = SI.SourceStockInventoryId
				);

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_StockInventory|' +  CONVERT(varchar, @@ROWCOUNT)
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Ticket Item Info
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'TicketItemInfoDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				
				-- Delete from Ticket Item Info
				DELETE RMT
				FROM TicketStockAvailabilityRawMaterialTickets RMT
				WHERE NOT EXISTS (
					SELECT 1
					FROM TicketItem TI
					INNER JOIN TicketItemInfo TII ON TII.SourceTicketItemId = TI.Id
					WHERE TII.Id = RMT.TicketItemInfoId
				);

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets|' +  CONVERT(varchar, @@ROWCOUNT)

				-- Delete from Ticket Item Info
				DELETE TII
				FROM TicketItemInfo TII
				WHERE NOT EXISTS (
					SELECT 1
					FROM TicketItem TI
					WHERE TI.Id = TII.SourceTicketItemId
				);
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Tickets From Product Color Info
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'ProductColorInfoDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				-- Delete from Product Color Info
				DELETE PCI
				FROM ProductColorInfo PCI
				WHERE NOT EXISTS (
					SELECT 1
					FROM ProductColor PC
					WHERE PC.PK_UUID = PCI.SourceProductColorId
				);
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ProductColorInfo|' +  CONVERT(varchar, @@ROWCOUNT)
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END
	
	-- Remove Deleted Purchase Orders
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'PurchaseOrderDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
				
				Drop Table if exists #DeletedPurchaseOrders
				Drop Table if exists #DeletedPurchaseOrderItems

				-- Delete from Purchase Order
				SELECT POM.SourcePurchaseOrderNo
				INTO #DeletedPurchaseOrders
				FROM PurchaseOrderMaster POM
				WHERE NOT EXISTS (
					SELECT 1
					FROM PurchaseOrder PO
					WHERE PO.PONumber = POM.SourcePurchaseOrderNo
				);

				-- Delete From Purchase Order Item
				Select poi.SourcePurchaseOrderItemId
				Into #DeletedPurchaseOrderItems
				From PurchaseOrderItem POI
				LEFT JOIN (Select CONCAT(ID, '_', Cut1) as ID, PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT1' as CutNumber, CUT1 as CutSize, NUMCUT1 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT1 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT1 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT1*CUT1/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT1*CUT1/1000 as ReceivedMSI
								From PO_Item_Stock
								Where CUT1 > 0 

							UNION ALL 

							Select CONCAT(ID, '_', Cut2) as ID, PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT2' as CutNumber, CUT2 as CutSize, NUMCUT2 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT2 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT2 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT2*CUT2/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT2*CUT2/1000 as ReceivedMSI
								From PO_Item_Stock
								Where CUT2 > 0

							UNION ALL 

							Select CONCAT(ID, '_', Cut3) as ID, PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT3' as CutNumber, CUT3 as CutSize, NUMCUT3 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT3 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT3 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT3*CUT3/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT3*CUT3/1000 as ReceivedMSI
								From PO_Item_Stock
								Where CUT3 > 0

							UNION ALL 

							Select CONCAT(ID, '_', Cut4) as ID, PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT4' as CutNumber, CUT4 as CutSize, NUMCUT4 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT4 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT4 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT4*CUT4/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT4*CUT4/1000 as ReceivedMSI
								From PO_Item_Stock
								Where CUT4 > 0

							UNION ALL 

							Select CONCAT(ID, '_', Cut5) as ID, PO_NUMBER, ORDERFOOTAGE, RECEIVEFOOTAGE, ROLLNUM, 'CUT5' as CutNumber, CUT5 as CutSize, NUMCUT5 as NumberofRollsInCut, ENTRYBY, ENTRYDATE, ENTRYTIME, RECEIVEDATE, RECEIPTBATCHSTATUS, WEIGHT, DIAMETER_OUTER, ORDERFOOTAGE*NUMCUT5 as OrderedLinearFootage, RECEIVEFOOTAGE*NUMCUT5 as ReceivedLinearFootage, ORDERFOOTAGE*NUMCUT5*CUT5/1000 as OrderedMSI, RECEIVEFOOTAGE*NUMCUT5*CUT5/1000 as ReceivedMSI
								From PO_Item_Stock
								Where CUT5 > 0) pis on POI.SourcePurchaseOrderItemId = pis.ID
					Where PIS.ID IS NULL

				DELETE TSAPO
						FROM TicketStockAvailabilityPO TSAPO
						INNER JOIN PurchaseOrderItem POI ON TSAPO.PurchaseOrderItemId = POI.Id
						INNER JOIN #DeletedPurchaseOrderItems DPOI ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO|' +  CONVERT(varchar, @@ROWCOUNT)

				DELETE POI
					FROM PurchaseOrderItem POI
					INNER JOIN PurchaseOrderMaster POM ON POM.ID = POI.PurchaseOrderId
					INNER JOIN #DeletedPurchaseOrders DPO ON DPO.SourcePurchaseOrderNo = POM.SourcePurchaseOrderNo 

				DELETE POI
					FROM PurchaseOrderItem POI
					INNER JOIN #DeletedPurchaseOrderItems DPOI ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 
					
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_PurchaseOrderItem|' +  CONVERT(varchar, @@ROWCOUNT)
	

				DELETE POM
					FROM PurchaseOrderMaster POM
					INNER JOIN #DeletedPurchaseOrders DPO
					ON DPO.SourcePurchaseOrderNo = POM.SourcePurchaseOrderNo
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_PurchaseOrderMaster|' +  CONVERT(varchar, @@ROWCOUNT)
		
			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END


	-- Remove Deleted Purchase Orders
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'RulesEngineDataCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
			
				IF EXISTS (SELECT 1 FROM #DeletedTickets) AND (@ProcessRulesEngine = 1)
				Begin
					DELETE FROM TicketAttributeValues WHERE [TicketId] IN  (SELECT [TicketID] FROM #DeletedTickets);
					DELETE FROM FeasibleRoutes WHERE [TicketId] IN  (SELECT [TicketID] FROM #DeletedTickets);
					DELETE FROM ChangeoverMinutes WHERE ([TicketIdFrom] IN  (SELECT [TicketID] FROM #DeletedTickets)) OR ([TicketIdTo] IN  (SELECT [TicketID] FROM #DeletedTickets));
					DELETE FROM TicketTask WHERE [TicketId] IN  (SELECT [TicketID] FROM #DeletedTickets);
					--DELETE FROM UnassignedJobs WHERE [TicketId] IN  (SELECT [TicketID] FROM #DeletedTickets);
				End

			END TRY
		
			BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
			END CATCH
		
			INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	-- BLOCK END

	--  Soft delete PurchaseOrderAudit records
	IF @IsError = 0	
	  	BEGIN
		  BEGIN TRY
			SET @blockName = 'PurchaseOrderAuditCleanup'; SET @startTime = GETDATE();
				IF  EXISTS (
					SELECT 1
					FROM INFORMATION_SCHEMA.TABLES
					WHERE TABLE_SCHEMA = 'dbo' 
						AND TABLE_NAME = 'PurchaseOrderAudit'
				)
				BEGIN
					IF EXISTS (SELECT 1 FROM PurchaseOrderAudit WHERE IsActive = 1)
					BEGIN
						UPDATE PurchaseOrderAudit SET IsActive = 0 WHERE IsActive = 1;
					END
				END
		  END TRY
		  BEGIN CATCH
--		==================================[Do not change]================================================
				SET @IsError = 1; Rollback;
				SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		 END CATCH

		END
	-- BLOCK END



	-- Remove Deleted Ticket User defined Options
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'TicketUserDefinedOptionsCleanup';
			BEGIN TRY
			
				DELETE TUDO 
				FROM TicketUserDefinedOptions TUDO 
				WHERE NOT EXISTS (
					SELECT 1
					FROM Equip_UserDefined EU
					WHERE EU.ID = TUDO.SourceEquipUDID
				);

			DROP TABLE IF EXISTS #DeletedTickets
		
			END TRY
		
			BEGIN CATCH
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
END

