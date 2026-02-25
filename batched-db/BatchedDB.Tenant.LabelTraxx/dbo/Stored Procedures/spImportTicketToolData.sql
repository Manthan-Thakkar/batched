 CREATE PROCEDURE [dbo].[spImportTicketToolData]
    -- Standard parameters for all stored procedures
    @TenantId       VARCHAR(36),
    @CorelationId   VARCHAR(100),
	@Since          DateTime = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN
    --  ==============================logging variables (do not change)=======================================
        DECLARE
            @spName                 VARCHAR(100) = 'spImportTicketToolData',
            @__ErrorInfoLog         __ErrorInfoLog,
            @maxCustomMessageSize   INT = 4000, --keep this exactly same AS 4000
            @blockName              VARCHAR(100),
            @warningStr             NVARCHAR(4000),
            @infoStr                NVARCHAR(4000),
            @errorStr               NVARCHAR(4000),
            @IsError                BIT = 0,
            @startTime              DATETIME;
    --  ======================================================================================================
    END

    BEGIN TRANSACTION;

    -- Delete temporary table
    DROP TABLE IF EXISTS [dbo].[#MatchingTicketTools];
    DROP TABLE IF EXISTS [dbo].[#DistinctToolingInventory];


    DECLARE @IsUpdatedLT AS BIT = IIF(EXISTS(SELECT 1 FROM TicketTools_LT), 1, 0);
        ---- Check whether the tenant is using LabelTraxx version >= 9.3
        ---- "TicketTools_LT" table will be populated for the tenants with LabelTraxx version >= 9.3


    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
    BEGIN
        SET @blockName = 'GeneratingTicketTools'; SET @startTime = GETDATE();
        
        BEGIN TRY
            
            ;WITH
                [TempTooling] AS (
                    SELECT [Number], [Notes], ROW_NUMBER() OVER (PARTITION BY [Number] ORDER BY [ModifiedDate] DESC, [ModifiedTime] DESC) AS [RowNumber]
                    FROM [dbo].[Tooling] WITH (NOLOCK)
                ),
            
                [LatestTempTooling] AS (
                    SELECT [Number], [Notes]
                    FROM [TempTooling]
                    WHERE [RowNumber] = 1
                ),
    
               [TempTicketToolsNoTool1Descr] AS
                    (SELECT [T].[Number] AS [TicketNumber], 
                           [ToolData].[ToolNumber], 
                           [ToolData].[Sequence], 
                           [ToolData].[Description]
                    FROM [dbo].[Ticket] [T] WITH (NOLOCK)
                    CROSS APPLY (
                        VALUES 
                            ([T].[MainTool], 1, NULL),
                            ([T].[ToolNo2], 2, [T].[Tool2Descr]),
                            ([T].[ToolNo3], 3, [T].[Tool3Descr]),
                            ([T].[ToolNo4], 4, [T].[Tool4Descr]),
                            ([T].[ToolNo5], 5, [T].[Tool5Descr])
                    ) AS [ToolData]([ToolNumber], [Sequence], [Description])
               ),

	           [TempTicketTools] as
                     (SELECT [TTT].[TicketNumber],
                           [TTT].[Sequence],
                           [TTT].[ToolNumber],
                           -- Get description from Tooling for MainTool (Sequence=1), otherwise use inline description
                           CASE WHEN [TTT].[Sequence] = 1 THEN [LTT].[Notes] ELSE [TTT].[Description] END AS [Description]
                    FROM [TempTicketToolsNoTool1Descr] [TTT]
                    LEFT JOIN [LatestTempTooling] [LTT] ON [TTT].[ToolNumber] = [LTT].[Number] AND [TTT].[Sequence] = 1
                    WHERE [TTT].[Sequence] <> 1 OR [LTT].[Number] IS NOT NULL)
                
               SELECT
                    [TTT].[TicketNumber],
                    [TTT].[Sequence],
                    ISNULL(CAST([TTT].[ToolNumber] AS NVARCHAR(200)), CAST([TTLT].[ToolNo] AS NVARCHAR(200))) AS [ToolNumber],
                    IIF([TTT].[ToolNumber] IS NULL, [TTLT].[ToolDescr], [TTT].[Description]) AS [Description],
                    IIF(@IsUpdatedLT = 1,IIF([TTT].ToolNumber IS NOT NULL, 1, [TTLT].[RoutingNo]), NULL) AS [RoutingNo]
                        ---- Set RoutingNumber as "Null" for the tenants with LabelTraxx version < 9.3
                        ---- Set RoutingNumber as "1" for all tools in the Ticket table for tenants with LabelTraxx version >= 9.3

               INTO [dbo].[#MatchingTicketTools]
               FROM [TempTicketTools] AS [TTT]
                    LEFT JOIN [dbo].[TicketTools_LT] AS [TTLT] WITH (NOLOCK) ON [TTT].[TicketNumber] = [TTLT].[TicketNumber] AND [TTT].[Sequence] = [TTLT].[RoutingNo]
               WHERE [TTT].[ToolNumber] IS NOT NULL OR [TTLT].[ToolNo] IS NOT NULL;


        END TRY

        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH

        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;

    END
    

    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
    BEGIN
        SET @blockName = 'DeleteTicketTools'; SET @startTime = GETDATE();

        BEGIN TRY       
            --delete any ticket tool records which are not identical
            DELETE [TT]
            FROM [dbo].[TicketTool] AS [TT] WITH (NOLOCK)
                INNER JOIN [dbo].[TicketMaster] AS [TM] WITH (NOLOCK) ON [TT].[TicketId] = [TM].[ID]
                INNER JOIN [dbo].[ToolingInventory] AS [TI] WITH (NOLOCK) ON [TT].[ToolingId] = [TI].[Id]
                WHERE [TT].[Sequence] <> 0
                AND NOT EXISTS (
                    SELECT 1 
                    FROM [dbo].[#MatchingTicketTools] AS [MTT]
                    WHERE [MTT].[TicketNumber] = [TM].[SourceTicketId] 
                        AND [MTT].[ToolNumber] = [TI].[SourceToolingId] 
                        AND [MTT].[Sequence] = [TT].[Sequence]
                );
            
            SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
        END TRY
        
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH

        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END


    IF @IsError = 0
    BEGIN
        SET @blockName = 'InsertTicketTools'; SET @startTime = GETDATE();
    
        BEGIN TRY
            
            SELECT [SourceToolingId], [ToolType], MIN([Id]) AS [Id]
            INTO [dbo].[#DistinctToolingInventory]
            FROM [dbo].[ToolingInventory] WITH (NOLOCK)
            GROUP BY [SourceToolingId], [ToolType];


            ----Insert the records into TicketTool using Ticket table
            INSERT INTO [dbo].[TicketTool] ([Id], [TicketId], ToolingId, [Sequence], [CreatedOn], [ModifiedOn], [Description], [RequiredQuantity], [RoutingNumber])
            SELECT NEWID(), [TM].[ID], [TI].[Id], [MTT].[Sequence], GETUTCDATE(), GETUTCDATE(), [MTT].[Description], 1, [MTT].[RoutingNo]
            FROM [dbo].[#MatchingTicketTools] AS [MTT]
                INNER JOIN [dbo].[TicketMaster] AS [TM] WITH (NOLOCK) ON [TM].[SourceTicketId] = [MTT].[TicketNumber]
                INNER JOIN [dbo].[#DistinctToolingInventory] AS [TI] ON [TI].[SourceToolingId] = [MTT].[ToolNumber]
            WHERE NOT EXISTS (
                    SELECT 1
                    FROM [dbo].[TicketTool] AS [TT]
                    WHERE [TT].[TicketId] = [TM].[ID] 
                        AND [TT].[Sequence] = [MTT].[Sequence] 
                        AND [TT].[ToolingId] = [TI].[Id]
                )
            ORDER BY [MTT].[TicketNumber] ASC, [MTT].[Sequence] ASC;


            SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
        
        END TRY
        
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH
        
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END


    -- Delete temporary table
    DROP TABLE IF EXISTS [dbo].[#MatchingTicketTools];
    DROP TABLE IF EXISTS [dbo].[#DistinctToolingInventory];

--      ========================[final commit log (do not change)]=======================================
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(),
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    
    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================
END

