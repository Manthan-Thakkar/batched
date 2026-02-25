/****** Object:  StoredProcedure [dbo].[spSeedTenantData]    Script Date: 27-10-2022 21:14:01 ******/
CREATE PROCEDURE [dbo].[spSeedTenantData]
    -- Standard parameters for all stored procedures
    @TenantId       nvarchar(36),
    @CorelationId varchar(100),
    @ticketAttribute dbo.[udt_TicketAttribute] ReadOnly,
    @ticketAttributeFormula dbo.[udt_TicketAttributeFormula] ReadOnly,
    @taskClassificationGroup dbo.[udt_TaskClassificationGroup] ReadOnly,
    @masterRollClassificationGroup dbo.[udt_MasterRollClassificationGroup] ReadOnly,
    @timezone dbo.[udt_TimeZone] Readonly
AS
    DECLARE @oldTicketAttributeId varchar(36)
    DECLARE @newTicketAttributeId varchar(36)
    DECLARE @processedTicketAttribute udt_TicketAttribute
BEGIN

    SET NOCOUNT ON;

    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE
        @spName                 varchar(100) = 'spSeedTenantData',
        @__ErrorInfoLog         __ErrorInfoLog,
        @maxCustomMessageSize   int = 4000, --keep this exactly same as 4000
        @blockName              varchar(100),
        @warningStr             nvarchar(4000),
        @infoStr                nvarchar(4000),
        @errorStr               nvarchar(4000),
        @IsError                bit = 0,
        @startTime              datetime;
--  ======================================================================================================

    END

    BEGIN TRANSACTION;

    IF @IsError = 0
    BEGIN
        SET @blockName = 'Seeding Tenant Data';
        SET @startTime = GETDATE();
        Begin TRY  
        
            INSERT INTO @processedTicketAttribute(ID, Name, Description, TenantId, DataType, UnitOfMeasurement, Scope, IsEnabled, RequiredForMaterialPlanning, IsProcessed)
            SELECT  Id, Name,Description, TenantId, DataType, UnitOfMeasurement, Scope, IsEnabled, RequiredForMaterialPlanning, 0 from @ticketAttribute
            
            WHILE( SELECT COUNT(1) FROM @processedTicketAttribute where IsProcessed = 0) > 0
            BEGIN
                SELECT Top 1 @oldTicketAttributeId = Id from @processedTicketAttribute where IsProcessed = 0
                SET @newTicketAttributeId = NEWID()
                
                INSERT INTO TicketAttribute (Id, Name, Description, TenantId, DataType, UnitOfMeasurement, Scope, IsEnabled, RequiredForMaterialPlanning, CreatedOn, ModifiedOn)
                    SELECT @newTicketAttributeId, Name, Description, TenantId, DataType, UnitOfMeasurement, Scope, IsEnabled, RequiredForMaterialPlanning, GETDATE(), GETDATE()
                    FROM @ticketAttribute
                    WHERE Id = @oldTicketAttributeId
                
                INSERT INTO TicketAttributeFormula (Id, FormulaType, FormulaText, TicketAttributeId, RuleText, CreatedOn, ModifiedOn)
                    SELECT NEWID(),FormulaType, FormulaText, @newTicketAttributeId, RuleText, GETDATE(), GETDATE()
                    FROM @ticketAttributeFormula
                    WHERE TicketAttributeId = @oldTicketAttributeId
                
                INSERT INTO TaskClassificationGroup (Id, WorkcenterTypeId, TicketAttributeId, CreatedOn, ModifiedOn)
                    SELECT NEWID(), WorkcenterTypeId, @newTicketAttributeId, GETDATE(), GETDATE()
                    FROM @taskClassificationGroup
                    WHERE TicketAttributeId = @oldTicketAttributeId
                
                INSERT INTO MasterRollClassificationGroup (Id, WorkcenterTypeId, TicketAttributeId, CreatedOn, ModifiedOn)
                    SELECT NEWID(), WorkcenterTypeId, @newTicketAttributeId, GETDATE(), GETDATE()
                    FROM @masterRollClassificationGroup
                    WHERE TicketAttributeId = @oldTicketAttributeId
                
                Update @processedTicketAttribute set IsProcessed = 1 where ID = @oldTicketAttributeId
            END
            SET @infoStr = 'TotalTicketAttributesSeeded|' +  CONVERT(varchar, (SELECT COUNT(1) FROM @ticketAttribute));
            
            DECLARE @configurationMasterID varchar(36)
            --Insert Windows Timezone information
            SET @configurationMasterID = NEWID()
            
            INSERT INTO ConfigurationMaster (Id, Name, IsMany, IsDisabled, CreatedOn, ModifiedOn)
            VALUES (@configurationMasterID, 'Timezone', 0, 0, GETDATE(), GETDATE())
            
            INSERT INTO ConfigurationValue(Id, Value, ConfigId, IsDisabled, CreatedOn, ModifiedOn)
            SELECT NEWID(), Id ,@configurationMasterID, 0, GETDATE(),GETDATE()
            FROM @timezone

            --Insert Linux Timezone Information
            SET @configurationMasterID = NEWID()
            
            INSERT INTO ConfigurationMaster (Id, Name, IsMany, IsDisabled, CreatedOn, ModifiedOn)
            VALUES (@configurationMasterID, 'LinuxTimezone', 0, 0, GETDATE(), GETDATE())
            
            INSERT INTO ConfigurationValue(Id, Value, ConfigId, IsDisabled, CreatedOn, ModifiedOn)
            SELECT NEWID(), LinuxTZ ,@configurationMasterID, 0, GETDATE(),GETDATE()
            FROM @timezone
        END TRY
        Begin CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--      =======================[Concate more error strings after this]===================================
        --  SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'    
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
--      ========================[final commit log (do not change)]=======================================
    IF @IsError = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM sys.database_principals
            WHERE name = N'pbi_readonly_user'
        )
        BEGIN
            CREATE USER [pbi_readonly_user] FOR LOGIN [pbi_readonly_user];
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM sys.database_role_members drm
            INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
            INNER JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
            WHERE r.name = N'db_datareader'
              AND m.name = N'pbi_readonly_user'
        )
        BEGIN
            ALTER ROLE [db_datareader] ADD MEMBER [pbi_readonly_user];
        END;
    END
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(),
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================
END
