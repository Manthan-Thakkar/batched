CREATE PROCEDURE [dbo].[spSinkRulesImports]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
		
	--	==============================logging variables (do not change)=======================================
		DECLARE 
			@spName					varchar(100) = 'spSinkRulesImports',
			@__ErrorInfoLog			__ErrorInfoLog,
			@maxCustomMessageSize	int = 4000, --keep this exactly 4000
			@blockName				varchar(100),
			@warningStr				nvarchar(4000),
			@infoStr				nvarchar(4000),
			@errorStr				nvarchar(4000),
			@IsError				bit = 0,
			@startTime				datetime,
			@tempTableRowCount		int,
			@mainTableRowCount		int;
	--	======================================================================================================
	
	
	-- Process Ticket Attributes
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'ticket-attribute'; SET @startTime = GETDATE();
		Begin TRY			
			
			Truncate table ticketAttributeValues;
			select @tempTableRowCount = count(*) from TicketAttributeValues_Temp;
			Alter Table TicketAttributeValues_Temp SWITCH To TicketAttributeValues;
			select @mainTableRowCount = count(*) from TicketAttributeValues;

			SET @infoStr = 'message|TicketAttributeValues_Temp SWITCH To TicketAttributeValues - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END
	
	-- Process Ticket Tasks
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'ticket-task'; SET @startTime = GETDATE();
		Begin TRY			
		
		ALTER TABLE [dbo].[TicketTask_Temp] NOCHECK CONSTRAINT [FK_TicketTask_Temp_Actual_EquipmentMasterId]
		ALTER TABLE [dbo].[TicketTask_Temp] NOCHECK CONSTRAINT [FK_TicketTask_Temp_Original_EquipmentMasterId]
		ALTER TABLE [dbo].[TicketTask_Temp] NOCHECK CONSTRAINT [FK_TicketTask_Temp_TicketMasterId]

		Truncate table TicketTask;
		
		ALTER TABLE [dbo].[TicketTask_Temp] WITH CHECK CHECK CONSTRAINT [FK_TicketTask_Temp_Actual_EquipmentMasterId]
		ALTER TABLE [dbo].[TicketTask_Temp] WITH CHECK CHECK CONSTRAINT [FK_TicketTask_Temp_Original_EquipmentMasterId]
		ALTER TABLE [dbo].[TicketTask_Temp] WITH CHECK CHECK CONSTRAINT [FK_TicketTask_Temp_TicketMasterId]


		select @tempTableRowCount = count(*) from TicketTask_Temp;
		Alter Table TicketTask_Temp SWITCH To TicketTask;
		select @mainTableRowCount = count(*) from TicketTask;

		SET @infoStr = 'message|TicketTask_Temp SWITCH To TicketTask - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH

		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END
	
	-- Process Reservations
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'reservations'; SET @startTime = GETDATE();
		Begin TRY

		ALTER TABLE [dbo].[ReservationTaskAllocation_temp] NOCHECK CONSTRAINT [Fk_ReservationTaskEventAllocation_temp]
		ALTER TABLE [dbo].[ReservationTaskAllocation_temp] NOCHECK CONSTRAINT [Fk_ReservationTaskEventAllocation_temp_TicketMaster]
		
		TRUNCATE TABLE ReservationTaskAllocation;

		ALTER TABLE [dbo].[ReservationTaskAllocation_temp] WITH CHECK CHECK CONSTRAINT [Fk_ReservationTaskEventAllocation_temp]
		ALTER TABLE [dbo].[ReservationTaskAllocation_temp] WITH CHECK CHECK CONSTRAINT Fk_ReservationTaskEventAllocation_temp_TicketMaster

		SELECT @tempTableRowCount = count(*) FROM ReservationTaskAllocation_Temp;
		ALTER TABLE ReservationTaskAllocation_temp SWITCH To ReservationTaskAllocation;
		SELECT @mainTableRowCount = count(*) FROM ReservationTaskAllocation;
			
		SET @infoStr = 'message|ReservationTaskAllocation_temp SWITCH To ReservationTaskAllocation - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		ALTER TABLE [dbo].[ReservedDemand_temp] NOCHECK CONSTRAINT [FK_ReservedDemand_tempToReservationEvents]

		TRUNCATE TABLE ReservedDemand

		ALTER TABLE [dbo].[ReservedDemand_temp] WITH CHECK CHECK CONSTRAINT [FK_ReservedDemand_tempToReservationEvents]
		
		SELECT @tempTableRowCount = count(*) FROM ReservedDemand_temp;
		ALTER TABLE ReservedDemand_temp SWITCH To ReservedDemand;
		SELECT @mainTableRowCount = count(*) FROM ReservedDemand;
			
		SET @infoStr = 'message|ReservedDemand_temp SWITCH To ReservedDemand - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)
		
		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END

	
	-- Process Ticket Data Cache
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'Ticket-Data-Cache'; SET @startTime = GETDATE();
		Begin TRY		
		
			Truncate table TicketDataCache;

			select @tempTableRowCount = count(*) from TicketDataCache_temp;
			Alter Table TicketDataCache_temp SWITCH To TicketDataCache;
			select @mainTableRowCount = count(*) from TicketDataCache;

			SET @infoStr = 'message|TicketDataCache_temp SWITCH To TicketDataCache - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END


	-- Process Unassigned-jobs
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'unassigned-jobs'; SET @startTime = GETDATE();
		Begin TRY	
		select @tempTableRowCount = count(*) from UnassignedJobs_temp;
			IF @tempTableRowCount <> 0	
			BEGIN		
				Truncate table UnassignedJobs;

				Alter Table UnassignedJobs_temp SWITCH To UnassignedJobs;
				select @mainTableRowCount = count(*) from UnassignedJobs;

				SET @infoStr = 'message|UnassignedJobs_temp SWITCH To UnassignedJobs - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount);
			END
			ELSE
			BEGIN
				SET @infoStr = 'message|UnassignedJobs_temp SWITCH To UnassignedJobs - temp table detected empty, skipping switch';
			END
		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END
	
	-- Process TicketStockAvailability
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'TicketStockAvailability'; SET @startTime = GETDATE();
		BEGIN TRY

		IF EXISTS ( SELECT * FROM ConfigurationMaster CM 
					INNER JOIN ConfigurationValue CV ON CM.Id = CV.ConfigId 
					WHERE CM.Name = 'EnableAutomaticStockAvailability' AND CV.Value = 'True')
			BEGIN
				-- First, disable constraints and then truncate each table
				alter table [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] nocheck constraint FK_TSA_temp_TicketItemInfo_TicketItemInfoId;
				alter table [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] nocheck constraint FK_TSA_temp_TicketStockAvailabilityId;

				Truncate Table TicketStockAvailabilityRawMaterialTickets;
			
				alter table [dbo].[TicketStockAvailabilityPO_temp] nocheck constraint FK_PurchaseOrderItem_temp_PurchaseOrderItemId;
				alter table [dbo].[TicketStockAvailabilityPO_temp] nocheck constraint FK_TicketStockAvailabilityPO_temp_TicketStockAvailabilityId;

				Truncate Table TicketStockAvailabilityPO;

				ALTER TABLE [dbo].[TicketStockAvailability_Temp] NOCHECK CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_ActualStockMaterialId]
				ALTER TABLE [dbo].[TicketStockAvailability_Temp] NOCHECK CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_OriginalStockMaterialId]
				ALTER TABLE [dbo].[TicketStockAvailability_Temp] NOCHECK CONSTRAINT [FK_TicketStockAvailability_Temp_TicketMaster_TicketId]
						
			
				DELETE FROM TicketStockAvailability;

				-- TicketStockAvailability
				ALTER TABLE [dbo].[TicketStockAvailability_Temp] with check check CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_ActualStockMaterialId]
				ALTER TABLE [dbo].[TicketStockAvailability_Temp] with check check CONSTRAINT [FK_TicketStockAvailability_Temp_StockMaterial_OriginalStockMaterialId]
				ALTER TABLE [dbo].[TicketStockAvailability_Temp] with check check CONSTRAINT [FK_TicketStockAvailability_Temp_TicketMaster_TicketId]


				select @tempTableRowCount = count(*) from TicketStockAvailability_Temp;
				Alter Table TicketStockAvailability_temp SWITCH To TicketStockAvailability;
				select @mainTableRowCount = count(*) from TicketStockAvailability;
			
				SET @infoStr = 'message|TicketStockAvailability_temp SWITCH To TicketStockAvailability - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

				 --TicketStockAvailabilityPO
				 alter table [dbo].[TicketStockAvailabilityPO_temp] with check check constraint FK_PurchaseOrderItem_temp_PurchaseOrderItemId;
				 alter table [dbo].[TicketStockAvailabilityPO_temp] with check check constraint FK_TicketStockAvailabilityPO_temp_TicketStockAvailabilityId;

				select @tempTableRowCount = count(*) from TicketStockAvailabilityPO_Temp;
				Alter Table TicketStockAvailabilityPO_temp SWITCH To TicketStockAvailabilityPO;
				select @mainTableRowCount = count(*) from TicketStockAvailabilityPO;
			
				SET @infoStr = 'message|TicketStockAvailabilityPO_temp SWITCH To TicketStockAvailabilityPO - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)


				-- TicketStockAvailabilityRawMaterialTickets
				alter table [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] with check check constraint FK_TSA_temp_TicketItemInfo_TicketItemInfoId;
				alter table [dbo].[TicketStockAvailabilityRawMaterialTickets_temp] with check check constraint FK_TSA_temp_TicketStockAvailabilityId;

				select @tempTableRowCount = count(*) from TicketStockAvailabilityRawMaterialTickets_Temp;
				Alter Table TicketStockAvailabilityRawMaterialTickets_temp SWITCH To TicketStockAvailabilityRawMaterialTickets;
				select @mainTableRowCount = count(*) from TicketStockAvailabilityRawMaterialTickets;
			
				SET @infoStr = 'message|TicketStockAvailabilityRawMaterialTickets_temp SWITCH To TicketStockAvailabilityRawMaterialTickets - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)
			END

		END TRY
		BEGIN CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1; 
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END

	-- Process Feasible-Routes
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'Feasible-Routes'; SET @startTime = GETDATE();
		Begin TRY		
		
			Truncate table feasibleRoutes;

			select @tempTableRowCount = count(*) from feasibleRoutes_temp;
			Alter Table feasibleRoutes_temp SWITCH To feasibleRoutes;
			select @mainTableRowCount = count(*) from FeasibleRoutes;

			SET @infoStr = 'message|feasibleRoutes_temp SWITCH To feasibleRoutes - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END

	-- Process ChangeoverMinutes
	IF @IsError = 0	
	BEGIN
		
		SET @blockName = 'changeover-minutes'; SET @startTime = GETDATE();
		Begin TRY	
		
			Truncate table ChangeoverMinutes;
			select @tempTableRowCount = count(*) from ChangeoverMinutes_temp;
			Alter Table ChangeoverMinutes_temp SWITCH To ChangeoverMinutes;
			select @mainTableRowCount = count(*) from ChangeoverMinutes;

			SET @infoStr = 'message|ChangeoverMinutes_temp SWITCH To ChangeoverMinutes - '+ Convert(varchar, @tempTableRowCount)+ ' rows switched to '+Convert(varchar, @mainTableRowCount)

		END TRY
		Begin CATCH
		
--		==================================[Do not change]================================================
			SET @IsError = 1; 
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	END

	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT TRANSACTION
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	ELSE
	BEGIN
		ROLLBACK TRANSACTION
	END
--		=================================================================================================
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
		SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
END

