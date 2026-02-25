CREATE PROCEDURE [dbo].[spImportShippingMethods]
    -- Standard parameters for all stored procedures
    @TenantId       nvarchar(36),
    @CorelationId   varchar(100)
AS      
BEGIN
    SET NOCOUNT ON;

    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE 
        @spName                 varchar(100) = 'spImportShippingMethods',
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
    -- ================ UPDATE EXISTING RECORDS ==================
    SET @blockName = 'UpdateShippingMethods'; 
    SET @startTime = GETDATE();
    BEGIN TRY 
        UPDATE SM
        SET SM.[Name] = L.[Name],
            SM.[GroupName] = L.[GroupName]
        FROM [dbo].[ShippingMethod] AS SM
        INNER JOIN [dbo].[List] AS L ON SM.SourceShippingMethodId = L.ID AND L.[Name] IS NOT NULL
        
    END TRY
    BEGIN CATCH
    --  ==================================[Do not change]================================================
            SET @IsError = 1; 
            Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())

    --  ==================================[Do not change]================================================
    END CATCH

    INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'InsertShippingMethods'; 
        SET @startTime = GETDATE();
        BEGIN TRY
            -- ================ INSERT NEW RECORDS ==================
            INSERT INTO [dbo].[ShippingMethod] ([ID], [SourceShippingMethodId], [Name], [GroupName])
                SELECT 
                    NEWID(),
                    L.[ID],
                    L.[Name],
                    L.[GroupName]
                FROM [dbo].[List] AS L WHERE L.[Name] IS NOT NULL AND NOT EXISTS (
                                                                             SELECT 1
                                                                             FROM [dbo].[ShippingMethod] AS SM
                                                                             WHERE TRY_CAST(SM.SourceShippingMethodId AS INT) = L.ID
                                                                         );
        END TRY
        BEGIN CATCH
        -- ==================================[Do not change]================================================
            SET @IsError = 1; 
            ROLLBACK;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        -- ==================================[Do not change]================================================
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
     
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
    
END