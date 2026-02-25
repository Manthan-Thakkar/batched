CREATE PROCEDURE [dbo].[spImportTicketNotesData]
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
		@spName					varchar(100) = 'spImportTicketNotesData',
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
		DECLARE @UpdateTicketNumberMappingMissingCount int
		DECLARE @UpdatePressNumberMappingMissingCount int
		

		SET @blockName = 'Update Ticket Notes'; SET @startTime = GETDATE();

		Begin TRY		


				if (@Since IS NULL)
					Begin
						Truncate Table TicketNote
					End
				Else
					Begin
						update TicketNote 
						set 
							TicketId				= ticMstr.ID, 
							SourceTicketId			= ticUsr.TICKETNUMBER,
							EquipmentId				= equipMstr.ID,
							SourceEquipmentId		= ticUsr.PRESS_NUMBER,
							[Description]			= ticUsr.DESCRIPTION,
							Notes					= ticUsr.NOTES,
							IsEnabled				= ticUsr.USETHISOPTION,
							ModifiedOn				= GETUTCDATE()
						from TicketNote TN
						Inner Join Ticket_UserDefined ticUsr on tn.SourceTicketNoteId = ticUsr.PK_UUID
						INNER JOIN EquipmentMaster equipMstr
						ON ticUsr.PRESS_NUMBER = equipMstr.SourceEquipmentId 
						INNER JOIN TicketMaster ticMstr ON ticMstr.SourceTicketId = ticUsr.Ticketnumber
						where @Since IS NULL
						OR ticUsr.UpdateTimeDateStamp >= @Since
					End   
				--End

			------
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
		DECLARE @InsertMappingMissingEquipmentMasterCount int
		DECLARE @InsertMappingMissingTicketMasterCount int
		SET @blockName = 'InsertTicketNotes'; SET @startTime = GETDATE();

		Begin TRY
		-- Insert the new records
		INSERT INTO [dbo].[TicketNote]([ID] ,[TicketId],[SourceTicketNoteId],[SourceTicketId],[EquipmentId],[SourceEquipmentId],[Description],[Notes],[IsEnabled],[CreatedOn],[ModifiedOn])
		SELECT 
				NEWID(),
				ticMstr.ID,
				ticUsr.PK_UUID,
				ticUsr.TICKETNUMBER,
				equipMstr.ID,
				ticUsr.PRESS_NUMBER,
				ticUsr.DESCRIPTION,
				ticUsr.NOTES,
				ticUsr.Usethisoption,
				GETUTCDATE(),
				GETUTCDATE()
			FROM Ticket_UserDefined ticUsr INNER JOIN EquipmentMaster equipMstr
			ON ticUsr.PRESS_NUMBER = equipMstr.SourceEquipmentId 
			INNER JOIN TicketMaster ticMstr ON ticMstr.SourceTicketId = ticUsr.Ticketnumber
			Where  ticUsr.PK_UUID NOT IN (SELECT SourceTicketNoteId FROM TicketNote)
		------
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)	

		--- Equipment master mapping not found
		Select @InsertMappingMissingEquipmentMasterCount = count(1) from 
		Ticket_UserDefined Where  PRESS_NUMBER Not in (Select SourceEquipmentId from EquipmentMaster)

		IF(@InsertMappingMissingEquipmentMasterCount > 0)
		BEGIN
			SET  @warningStr ='MappingNotFound_Ticket_UserDefined_EquipmentMaster|'+ Convert(varchar, @InsertMappingMissingEquipmentMasterCount)
		END
		----

		--- TicketMaster Mapping not found
		Select @InsertMappingMissingTicketMasterCount = count(1) from 
		Ticket_UserDefined Where TICKETNUMBER Not in (Select SourceTicketId from TicketMaster)

		IF(@InsertMappingMissingTicketMasterCount > 0)
		BEGIN
			SET  @warningStr =COALESCE( @warningStr,'')+  '#MappingNotFound_Ticket_UserDefined_TicketMaster|'+ Convert(varchar, @InsertMappingMissingTicketMasterCount)
		END
		------
			
		END TRY
		Begin CATCH
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