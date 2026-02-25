CREATE PROCEDURE [dbo].[spRemoveDeletedRecordsData_Radius]
	@TenantId		nvarchar(36),
	@CorelationId 	varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spRemoveDeletedRecordsData_Radius',
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
				DROP TABLE IF EXISTS #AllSourceJobs
				DROP TABLE IF EXISTS #DeletedPurchaseOrderItems
				DROP TABLE IF EXISTS #DeletedAssociatedPOIs

				SELECT 
					CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
				INTO #AllSourceJobs
				FROM PV_job J
					INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
				where (J.JobStatus in (10, 20) OR (J.JobStatus Not In (10, 20) AND J.CompletedDate >= DATEADD(day, -30, getdate()))) AND JC.CmpType IN (7,9,10)

 

				SELECT TM.SourceTicketId, TM.ID AS TicketID
					INTO #DeletedTickets
					FROM TicketMaster TM
					LEFT JOIN #AllSourceJobs Job with (nolock)
					ON Job.TicketNumber = TM.SourceTicketId
					WHERE Job.TicketNumber IS NULL


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

					DELETE TSA
						FROM TicketStockAvailability TSA
						INNER JOIN #DeletedTickets DT
						ON TSA.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailability|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TICI
						FROM TicketItemColorInfo TICI
						INNER JOIN TicketItemInfo TII on TICI.ticketItemInfoId = TII.Id
						INNER JOIN #DeletedTickets DT
						ON TII.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemColorInfo|' +  CONVERT(varchar, @@ROWCOUNT)

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
						FROM TicketTask_temp TTK
						INNER JOIN #DeletedTickets DT
						ON TTK.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTask_temp|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TTK
						FROM TicketTask TTK
						INNER JOIN #DeletedTickets DT
						ON TTK.TicketId = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketTask|' +  CONVERT(varchar, @@ROWCOUNT)

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

					-- Delete from Ticket Master
					DELETE TM
						FROM TicketMaster TM
						INNER JOIN #DeletedTickets DT
						ON TM.Id = DT.TicketID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketMaster|' +  CONVERT(varchar, @@ROWCOUNT)
				END

				-- Rebuild indices
				ALTER INDEX ALL ON TicketStockAvailability REBUILD
				Update Statistics TicketStockAvailability With FullScan

				ALTER INDEX ALL ON TicketStockAvailabilityPO REBUILD
				Update Statistics TicketStockAvailabilityPO With FullScan

				ALTER INDEX ALL ON TicketStockAvailabilityRawMaterialTickets REBUILD
				Update Statistics TicketStockAvailabilityRawMaterialTickets With FullScan

				ALTER INDEX ALL ON TicketItemInfo REBUILD
				Update Statistics TicketItemInfo With FullScan

				ALTER INDEX ALL ON TicketNote REBUILD
				Update Statistics TicketNote With FullScan

				ALTER INDEX ALL ON TicketTask REBUILD
				Update Statistics TicketTask With FullScan

				ALTER INDEX ALL ON TimeCardInfo REBUILD
				Update Statistics TimeCardInfo With FullScan

				ALTER INDEX ALL ON TicketShipping REBUILD
				Update Statistics TicketShipping With FullScan

				ALTER INDEX ALL ON TicketStock REBUILD
				Update Statistics TicketStock With FullScan

				ALTER INDEX ALL ON TicketPreProcess REBUILD
				Update Statistics TicketPreProcess With FullScan

				ALTER INDEX ALL ON TicketTool REBUILD
				Update Statistics TicketTool With FullScan

				ALTER INDEX ALL ON TicketScore REBUILD
				Update Statistics TicketScore With FullScan

				ALTER INDEX ALL ON TicketDimensions REBUILD
				Update Statistics TicketDimensions With FullScan

				ALTER INDEX ALL ON OpenTicketColorsV2 REBUILD
				Update Statistics OpenTicketColorsV2 With FullScan

				ALTER INDEX ALL ON TicketGeneralNotes REBUILD
				Update Statistics TicketGeneralNotes With FullScan

				ALTER INDEX ALL ON TicketTaskOverride REBUILD
				Update Statistics TicketTaskOverride With FullScan

				ALTER INDEX ALL ON TicketTaskDependency REBUILD
				Update Statistics TicketTaskDependency With FullScan

				ALTER INDEX ALL ON TicketTaskData REBUILD
				Update Statistics TicketTaskData With FullScan

				ALTER INDEX ALL ON TicketMaster REBUILD
				Update Statistics TicketMaster With FullScan
			
				-- Drop Temporary Tables
				DROP TABLE IF EXISTS #DeletedTicketStockAvailability
				DROP TABLE IF EXISTS #DeletedTickets
				DROP TABLE IF EXISTS #AllSourceJobs
		
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

				SELECT SPM.SourceStockProductId, SPM.Id AS StockProductID
					INTO #DeletedStockProducts
					FROM StockProductMaster SPM
					LEFT JOIN  PM_Item PMI with (nolock)
					ON SPM.SourceStockProductId =  PMI.ItemCode 
					WHERE PMI.ItemCode IS NULL

				IF EXISTS (SELECT 1 FROM #DeletedStockProducts)
				BEGIN

					DELETE RMT
						FROM TicketStockAvailabilityRawMaterialTickets RMT
						INNER JOIN TicketItemInfo TII
							ON RMT.TicketItemInfoId = TII.Id
						INNER JOIN #DeletedStockProducts DSP
							ON TII.StockProductId = DSP.StockProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo_TSARawMaterialTickets|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TICI
						FROM TicketItemColorInfo TICI
						INNER JOIN TicketItemInfo TII ON TII.Id = TICI.TicketItemInfoId
						INNER JOIN #DeletedStockProducts DSP
						ON TII.StockProductId = DSP.StockProductID
					SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemColorInfo|' +  CONVERT(varchar, @@ROWCOUNT)

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

				-- Rebuild indices
				ALTER INDEX ALL ON TicketStockAvailabilityRawMaterialTickets REBUILD
				Update Statistics TicketStockAvailabilityRawMaterialTickets With FullScan

				ALTER INDEX ALL ON TicketItemInfo REBUILD
				Update Statistics TicketItemInfo With FullScan

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
                
				SELECT PM.SourceProductId, PM.Id as ProductID
					INTO #DeletedProducts
					FROM ProductMaster PM
					LEFT JOIN  PM_Item Item with (nolock) ON Item.ItemCode = PM.SourceProductId 
					WHERE Item.ItemCode IS NULL
                
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
                    
					Delete TICI
                        FROM TicketItemColorInfo TICI
						INNER JOIN TicketItemInfo TII ON TICI.TicketItemInfoId = TII.Id
                        INNER JOIN #DeleteStockProducts DP
                        ON TII.StockProductId = DP.Id
                    SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemColorInfo-StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					Delete TII
                        FROM TicketItemInfo TII
                        INNER JOIN #DeleteStockProducts DP
                        ON TII.StockProductId = DP.Id
                    SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo-StockProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

					DELETE TICI
                        FROM TicketItemColorInfo TICI
						INNER JOIN TicketItemInfo TII ON TICI.TicketItemInfoId = TII.Id
                        INNER JOIN #DeletedProducts DP
                        ON TII.ProductId = DP.ProductID
                    SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemColorInfo-ProductMaster|' +  CONVERT(varchar, @@ROWCOUNT)

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

				-- Rebuild indices
				ALTER INDEX ALL ON TicketItemInfo REBUILD
				Update Statistics TicketItemInfo With FullScan
                
				-- Drop Temporary Table #DeletedProducts and #DeleteStockProducts
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
					LEFT JOIN PV_ToolSpec PTS with (nolock) ON PTS.SpecCode = TI.SourceToolingId
					WHERE PTS.SpecCode IS NULL

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

				-- Rebuild indicies
				ALTER INDEX ALL ON TicketTool REBUILD
				Update Statistics TicketTool With FullScan

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
					LEFT JOIN PM_Item PI with (nolock)
					ON SM.SourceStockId = PI.ItemCode
					WHERE PI.ItemCode IS NULL


				IF EXISTS (SELECT 1 FROM #DeletedStockMaterial)
				BEGIN
					SELECT TSA.OriginalStockMaterialId, TSA.Id AS TicketStockAvailabilityId
						INTO #DeletedTicketStockAvailabilityData
						FROM TicketStockAvailability TSA
						LEFT JOIN #DeletedStockMaterial DSM
						ON TSA.OriginalStockMaterialId = DSM.StockMaterialID

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
						LEFT JOIN #DeletedStockMaterial DSM
						ON POI.StockMaterialId = DSM.StockMaterialID

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
						ON POM.StockMaterialId is not null AND POM.StockMaterialId = DSM.StockMaterialID
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

				-- Rebuild indices
				ALTER INDEX ALL ON TicketStock REBUILD
				Update Statistics TicketStock With FullScan

				-- Drop Temporary Table #DeletedStockMaterial
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
					LEFT JOIN  PV_Inventory PVI with (nolock) ON SI.SourceStockInventoryId = PVI.InventoryRef
					WHERE PVI.InventoryRef IS NULL
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
					INNER JOIN TicketItemInfo TII ON RMT.TicketItemInfoId = TII.Id
					LEFT JOIN PV_JobLine PJL with (nolock) ON PJL.TableRecId = TII.SourceTicketItemId
					WHERE PJL.TableRecId IS NULL
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TSARawMaterialTickets_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)
		
				--Delete Ticket Item Color Info
				DELETE TICI from ticketitemcolorinfo TICI
					inner join ticketiteminfo TII on TICI.TicketItemInfoId = TII.id
					LEFT JOIN PV_JobLine PJL with (nolock) ON PJL.TableRecId = TII.SourceTicketItemId
					WHERE PJL.TableRecId IS NULL
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_ticketitemcolorinfo_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)

				-- Delete from Ticket Item Info
				DELETE TII
					FROM TicketItemInfo TII
					LEFT JOIN PV_JobLine PJL with (nolock) ON PJL.TableRecId = TII.SourceTicketItemId
					WHERE PJL.TableRecId IS NULL
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketItemInfo|' +  CONVERT(varchar, @@ROWCOUNT)

				ALTER INDEX ALL ON TicketItemInfo REBUILD
				Update Statistics TicketItemInfo With FullScan

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
					LEFT JOIN [item-coating] IC with (nolock) ON IC.TableRecId = PCI.SourceProductColorId
					WHERE IC.TableRecid IS NULL
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
		
				-- Delete from Purchase Order
				SELECT POM.SourcePurchaseOrderNo
					INTO #DeletedPurchaseOrders
					FROM PurchaseOrderMaster POM
					LEFT JOIN PV_POrder PO
					ON POM.SourcePurchaseOrderNo = CONCAT(PO.CompNum, '_', PO.POrderNum)
					WHERE PO.POrderNum IS NULL

				SELECT POI.SourcePurchaseOrderItemId 
					INTO #DeletedAssociatedPOIs
					FROM PurchaseOrderItem POI
					INNER JOIN PurchaseOrderMaster POM ON POM.ID = POI.PurchaseOrderId
					INNER JOIN #DeletedPurchaseOrders DPO ON DPO.SourcePurchaseOrderNo = POM.SourcePurchaseOrderNo 

				DELETE TSAPO
					FROM TicketStockAvailabilityPO_temp TSAPO
					INNER JOIN PurchaseOrderItem POI
						ON TSAPO.PurchaseOrderItemId = POI.Id
					INNER JOIN #DeletedAssociatedPOIs DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO_temp|' +  CONVERT(varchar, @@ROWCOUNT)

				DELETE TSAPO
					FROM TicketStockAvailabilityPO TSAPO
					INNER JOIN PurchaseOrderItem POI
						ON TSAPO.PurchaseOrderItemId = POI.Id
					INNER JOIN #DeletedAssociatedPOIs DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO|' +  CONVERT(varchar, @@ROWCOUNT)
					
				DELETE POI
					FROM PurchaseOrderItem POI
					INNER JOIN #DeletedAssociatedPOIs DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 
					
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


	-- Remove Deleted PurchaseOrderItems
	IF @IsError = 0	
	  	BEGIN
			SET @blockName = 'PurchaseOrderItemCleaning'; SET @startTime = GETDATE();

			BEGIN TRY
		
				-- Fetch orphan PurchaseOrderItems
				SELECT POI.SourcePurchaseOrderItemId
					INTO #DeletedPurchaseOrderItems
					FROM PurchaseOrderItem POI
					LEFT JOIN PV_POrderLine PVPO
						ON POI.SourcePurchaseOrderItemId = CONCAT(PVPO.CompNum, '_', PVPO.PlantCode, '_', PVPO.POrderNum, '_', PVPO.POrderLineNum)
					WHERE PVPO.POrderLineNum IS NULL

				DELETE TSAPO
					FROM TicketStockAvailabilityPO_temp TSAPO
					INNER JOIN PurchaseOrderItem POI
						ON TSAPO.PurchaseOrderItemId = POI.Id
					INNER JOIN #DeletedPurchaseOrderItems DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO_temp|' +  CONVERT(varchar, @@ROWCOUNT)

				DELETE TSAPO
					FROM TicketStockAvailabilityPO TSAPO
					INNER JOIN PurchaseOrderItem POI
						ON TSAPO.PurchaseOrderItemId = POI.Id
					INNER JOIN #DeletedPurchaseOrderItems DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 

				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_TicketStockAvailabilityPO|' +  CONVERT(varchar, @@ROWCOUNT)

				DELETE POI
					FROM PurchaseOrderItem POI
					INNER JOIN #DeletedPurchaseOrderItems DPOI
						ON POI.SourcePurchaseOrderItemId = DPOI.SourcePurchaseOrderItemId 
					
				SET @infoStr = COALESCE( @infoStr,'') + '#Rows_Deleted_PurchaseOrderItem|' +  CONVERT(varchar, @@ROWCOUNT)

				ALTER INDEX ALL ON PurchaseOrderItem REBUILD
				Update Statistics PurchaseOrderItem With FullScan

				DROP TABLE IF EXISTS #DeletedPurchaseOrderItems

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