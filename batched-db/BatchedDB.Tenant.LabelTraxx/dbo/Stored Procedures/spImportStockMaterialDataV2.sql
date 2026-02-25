CREATE PROCEDURE [dbo].[spImportStockMaterialDataV2]
    @TenantId       nvarchar(36),
    @CorelationId varchar(100),
    @Since DateTime = NULL
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE 
        @spName                 varchar(100) = 'spImportStockMaterialDataV2',
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
    
    
    SELECT SM.ID StockMaterialId, S.StockNum StockId, S.LinerCaliper LinerCaliper 
    INTO #MatchingStocks
    FROM StockMaterial SM
    INNER JOIN Stock S on S.StockNum = SM.SourceStockId AND S.StockNum IS NOT NULL
    WHERE SM.Source='LabelTraxx' and SM.TenantId = @TenantId;

    

    -- DUPLICATE CHECK BLOCK
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'DuplicateStockCheck'; SET @startTime = GETDATE();
        BEGIN TRY           
            DECLARE @duplicateRecs int = 
            (
                SELECT COUNT(1) FROM (
                    select COUNT(1) no_of_recs, StockNum 
                    from Stock 
                    group by StockNum 
                    having COUNT(1) > 1
                ) DupeCounter
            )
            SET @infoStr = 'TotalDuplicates_Stock_StockNum|' +  CONVERT(varchar, @duplicateRecs);
            IF @duplicateRecs > 1 
            BEGIN
                SET @warningStr = @infoStr
                SET @infoStr = NULL;

                DECLARE @DupeActiveRecs int = 
                (
                    SELECT COUNT(1) FROM (
                        SELECT COUNT(1) no_of_recs, StockNum, Inactive 
                        FROM Stock
                        WHERE Inactive = 0
                        GROUP by StockNum, Inactive
                        HAVING COUNT(1) > 1
                    ) DupeCounter
                )
                
                IF @DupeActiveRecs > 1 
                BEGIN
                    SET @warningStr = @warningStr + '#' + 'TotalDuplicateActiveRecords_Stock_StockNum|' +  CONVERT(varchar, @DupeActiveRecs);
                END
            END
        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--      =======================[Concate more error strings after this]===================================
        --  SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'    
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END

    -- NULL CHECK BLOCK
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'NullStockCheck'; SET @startTime = GETDATE();
        Begin TRY           
            DECLARE @NullRecs int = 
            (
                SELECT COUNT(1) FROM Stock where StockNum is null
            )
            SET @infoStr = 'TotalNullRecords_Stock_StockNum|' +  CONVERT(varchar, @NullRecs);
            IF @NullRecs > 1 
            BEGIN
                SET @warningStr = @infoStr;
                SET @infoStr = NULL;
            END
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
                    
    --Identify the matching records in the StockMaterial table based upon matching Stock.StockNum and StockMaterial.SourceStockId with additional conditions of Source='LabelTraxx' and TenantId = @tenantId
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'UpdateStockProduct'; SET @startTime = GETDATE();
        BEGIN TRY   
    
            --update StockMaterial
            UPDATE SM 
            set 
                FaceColor = ISNULL(S.FaceColor,''), 
                FaceStock = ISNULL(S.FaceStock,''),
                LinerCaliper = CASE WHEN ISNUMERIC( cast(S.LinerCaliper as varchar)) = 0 THEN NULL ELSE S.LinerCaliper END,
                Classification = ISNULL(S.Classification,''),
                AdhesiveClass = S.AdhClass,
                IsEnabled = IIF(S.Inactive=0, 1, 0),
                ModifiedOn = GETUTCDATE(),
                SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
                SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
                MFGSpecNum = S.MFGSpecNum,
                FaceCaliper = CASE WHEN ISNUMERIC( cast(S.FaceCaliper as varchar)) = 0 THEN NULL ELSE S.FaceCaliper END,
                MasterWidth = S.MasterWidth,
                CostMSI = S.CostMSI,
                Adhesive = S.Adhesive,
                TopCoat = S.TopCoat,
                DefaultCoreSize  = S.Default_CoreSize,
                [Type] = 'Roll'
            FROM StockMaterial SM
            INNER JOIN #MatchingStocks MS on SM.Id = MS.StockMaterialId
            INNER JOIN Stock S ON S.StockNum = SM.SourceStockId AND S.StockNum IS NOT NULL
            WHERE @Since IS NULL
            OR S.UpdateTimeDateStamp >= @Since
        
            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

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

    IF @IsError = 0 
    BEGIN
        SET @blockName = 'InsertStockProduct'; SET @startTime = GETDATE();
        BEGIN TRY       
            --insert StockMaterial

            INSERT INTO StockMaterial(Id,TenantId,Source,SourceStockId,FaceColor,FaceStock,LinerCaliper,Classification,AdhesiveClass,IsEnabled,SourceCreatedOn,SourceModifiedOn,CreatedOn,ModifiedOn,MFGSpecNum, FaceCaliper, MasterWidth, CostMSI, Adhesive, TopCoat,  DefaultCoreSize)
            SELECT 
                NEWID(), 
                @TenantId,
                'LabelTraxx',
                StockNum,
                ISNULL(S.FaceColor,''),
                ISNULL(S.FaceStock,''),
                CASE WHEN ISNUMERIC( cast(S.LinerCaliper as varchar)) = 0 THEN NULL ELSE S.LinerCaliper END,
                ISNULL(S.Classification,''),
                S.AdhClass,
                IIF(S.Inactive=0, 1, 0),
                CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
                CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
                GETUTCDATE(),
                GETUTCDATE(),
                S.MFGSpecNum,
                CASE WHEN ISNUMERIC( cast(S.FaceCaliper as varchar)) = 0 THEN NULL ELSE S.FaceCaliper END,
                S.MasterWidth,
                S.CostMSI,
                S.Adhesive,
                S.TopCoat,
                S.Default_CoreSize
            FROM Stock S
            WHERE StockNum NOT IN (SELECT StockId FROM #MatchingStocks) and S.StockNum is not null
            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

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

    IF @IsError = 0 
    BEGIN
        SET @blockName = 'UpdateStockSubstitute'; SET @startTime = GETDATE();
        BEGIN TRY   
            
            DECLARE @rowCount int = 0;

            UPDATE SMS
            SET
                SMS.AlternateStockMaterialId = SM2.Id,
                ModifiedOn = GETUTCDATE()
            FROM StockMaterialSubstitute SMS 
            INNER JOIN StockMaterial SM ON SMS.StockMaterialId = SM.Id
            INNER JOIN Stock S ON SM.SourceStockId = S.StockNum
            INNER JOIN Stock S2 ON S.StockSubstitute_1 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            where SMS.Sequence = 1

            SET @rowCount = @rowCount + @@ROWCOUNT;

            UPDATE SMS
            SET
                SMS.AlternateStockMaterialId = SM2.Id,
                ModifiedOn = GETUTCDATE()
            FROM StockMaterialSubstitute SMS 
            INNER JOIN StockMaterial SM ON SMS.StockMaterialId = SM.Id
            INNER JOIN Stock S ON SM.SourceStockId = S.StockNum
            INNER JOIN Stock S2 ON S.StockSubstitute_2 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            where SMS.Sequence = 2

            SET @rowCount = @rowCount + @@ROWCOUNT;

            UPDATE SMS
            SET
                SMS.AlternateStockMaterialId = SM2.Id,
                ModifiedOn = GETUTCDATE()
            FROM StockMaterialSubstitute SMS 
            INNER JOIN StockMaterial SM ON SMS.StockMaterialId = SM.Id
            INNER JOIN Stock S ON SM.SourceStockId = S.StockNum
            INNER JOIN Stock S2 ON S.StockSubstitute_3 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            WHERE SMS.Sequence = 3

            SET @rowCount = @rowCount + @@ROWCOUNT;

            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @rowCount)

        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--      =======================[Concate more error strings after this]===================================
        --  SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'    
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
                

    IF @IsError = 0 
    BEGIN
        SET @blockName = 'InsertStockSubstitutes'; SET @startTime = GETDATE();
        Begin TRY       
            --insert StockMaterial

            INSERT INTO StockMaterialSubstitute(Id, StockMaterialId, AlternateStockMaterialId, [Sequence], CreatedOn, ModifiedOn)
            SELECT DISTINCT
                NEWID(), SM.Id, SM2.Id, 1, GETUTCDATE(), GETUTCDATE()
            FROM Stock S
            INNER JOIN StockMaterial SM ON S.StockNum = SM.SourceStockId
            INNER JOIN Stock S2 ON S.StockSubstitute_1 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            WHERE S.StockSubstitute_1 IS NOT NULL AND S.StockNum IS NOT NULL AND 
            SM2.Id not in (SELECT SMS.AlternateStockMaterialId FROM StockMaterialSubstitute SMS
            INNER JOIN StockMaterial OSM ON SMS.StockMaterialId = OSM.Id WHERE OSM.Id = SM.Id
            AND SMS.[Sequence] = 1)
        
            UNION ALL

            SELECT DISTINCT
                NEWID(), SM.Id, SM2.Id, 2, GETUTCDATE(), GETUTCDATE()
            from Stock S
            INNER JOIN StockMaterial SM ON S.StockNum = SM.SourceStockId
            INNER JOIN Stock S2 ON S.StockSubstitute_2 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            WHERE S.StockSubstitute_2 IS NOT NULL AND S.StockNum IS NOT NULL AND 
            SM2.Id not IN (SELECT SMS.AlternateStockMaterialId FROM StockMaterialSubstitute SMS
            INNER JOIN StockMaterial OSM ON SMS.StockMaterialId = OSM.Id WHERE OSM.Id = SM.Id
            AND SMS.[Sequence] = 2)

            UNION ALL
        
            SELECT DISTINCT
                NEWID(), SM.Id, SM2.Id, 3, GETUTCDATE(), GETUTCDATE()
            FROM Stock S
            INNER JOIN StockMaterial SM ON S.StockNum = SM.SourceStockId
            INNER JOIN Stock S2 ON S.StockSubstitute_3 = S2.StockNum
            INNER JOIN StockMaterial SM2 ON S2.StockNum = SM2.SourceStockId
            WHERE S.StockSubstitute_3 IS NOT NULL AND S.StockNum IS NOT NULL  AND 
            SM2.Id not IN (SELECT SMS.AlternateStockMaterialId FROM StockMaterialSubstitute SMS
            INNER JOIN StockMaterial OSM ON SMS.StockMaterialId = OSM.Id WHERE OSM.Id = SM.Id
            AND SMS.[Sequence] = 3)



            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

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

    
    
    IF @IsError = 0 
    BEGIN
        SET @blockName = 'DeleteStockSubstitutes'; SET @startTime = GETDATE();
        BEGIN TRY       
            
            SELECT SMS.StockMaterialId, SMS.AlternateStockMaterialId
            INTO #DeletedStockSubstitutes
                FROM StockMaterialSubstitute SMS
            INNER JOIN StockMaterial SM1 ON SMS.StockMaterialId = SM1.ID
            INNER JOIN StockMaterial SM2 ON SMS.AlternateStockMaterialId = SM2.ID
            LEFT JOIN STOCK S ON S.StockNum = SM1.SourceStockId
            WHERE  (SMS.Sequence = 1 AND S.StockSubstitute_1 IS NULL)
            OR (SMS.Sequence = 2 AND S.StockSubstitute_2 IS NULL)
            OR (SMS.Sequence = 3 AND S.StockSubstitute_3 IS NULL)

            DELETE SMS
            FROM StockMaterialSubstitute SMS
            INNER JOIN #DeletedStockSubstitutes DS on DS.StockMaterialId = SMS.StockMaterialId and DS.AlternateStockMaterialId = SMS.AlternateStockMaterialId

            SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--      =======================[Concate more error strings after this]===================================
        --  SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'    
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END


    DROP TABLE IF EXISTS #MatchingStocks
    DROP TABLE IF EXISTS #DeletedStockSubstitutes

--      ========================[final commit log (do not change)]=======================================
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================



END