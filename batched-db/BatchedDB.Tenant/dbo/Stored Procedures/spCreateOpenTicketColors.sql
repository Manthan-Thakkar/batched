CREATE  PROCEDURE [dbo].[spCreateOpenTicketColors]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spCreateOpenTicketColors',
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
		SET @blockName = 'Deleting Ticket Colors'; SET @startTime = GETDATE();

		Begin TRY	

				Delete from OpenTicketColorsV2

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
		SET @blockName = 'Inserting Ticket Colors'; SET @startTime = GETDATE();

		Select Distinct TicketId Into #TicketsToProcess from TicketTask

		Begin TRY	
	INSERT INTO OpenTicketColorsV2 
			SELECT
			TicketId,Color
			from (
						Select Distinct ti.TicketId, UPPER([dbo].udf_GetAlphanumericString(pc.SourceColor)) as Color
							FROM
								dbo.ProductColorInfo pc 
							INNER JOIN 
								dbo.ticketItemInfo ti
								ON pc.ProductId =ti.ProductId
							WHERE 
								ti.TicketId in (Select TicketId From #TicketsToProcess) and pc.SourceColor <> '' and pc.SourceColor Not Like '%No Varnish%' and UPPER([dbo].udf_GetAlphanumericString(pc.SourceColor))<>'ADHESIVEKILL' and UPPER(pc.SourceColor) <> 'CMYK'

						Union ALL

						Select Distinct ti.TicketId, 'C' as Color
						FROM
								dbo.ProductColorInfo pc 
							INNER JOIN 
								dbo.ticketItemInfo ti
								ON pc.ProductId =ti.ProductId
							WHERE 
								ti.TicketId in (Select TicketId From #TicketsToProcess) and UPPER(pc.SourceColor) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketId, 'M' as Color
						FROM
								dbo.ProductColorInfo pc 
							INNER JOIN 
								dbo.ticketItemInfo ti
								ON pc.ProductId =ti.ProductId
							WHERE 
								ti.TicketId in (Select TicketId From #TicketsToProcess) and UPPER(pc.SourceColor) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketId, 'Y' as Color
						FROM
								dbo.ProductColorInfo pc 
							INNER JOIN 
								dbo.ticketItemInfo ti
								ON pc.ProductId =ti.ProductId
							WHERE 
								ti.TicketId in (Select TicketId From #TicketsToProcess) and UPPER(pc.SourceColor) = 'CMYK'

						Union ALL

						Select Distinct ti.TicketId, 'K' as Color
						FROM
							dbo.ProductColorInfo pc 
							INNER JOIN 
								dbo.ticketItemInfo ti
								ON pc.ProductId =ti.ProductId
							WHERE 
								ti.TicketId in (Select TicketId From #TicketsToProcess) and UPPER(pc.SourceColor) = 'CMYK') as ticketColors

		
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
		-- Delete temporary table
	DROP TABLE IF EXISTS #FelxoTickets
					   		
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