CREATE PROCEDURE [dbo].[spImportTicketToolCylinderData]
    -- Standard parameters for all stored procedures
    @TenantId       NVARCHAR(36),
    @CorelationId   VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN
--  ==============================logging variables (do NOT change)=======================================
    DECLARE
        @spName                 VARCHAR(100) = 'spImportTicketToolCylinderData',
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
    DROP TABLE IF EXISTS #MatchingTicketTools;
	DROP TABLE IF EXISTS #EquipmentWithCylindersEnabled;


    DECLARE @IsUpdatedLT AS BIT = IIF(EXISTS(SELECT 1 FROM TicketTools_LT), 1, 0);
        ---- Check whether the tenant is using LabelTraxx version >= 9.3
        ---- "TicketTools_LT" table will be populated for the tenants with LabelTraxx version >= 9.3


    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
    BEGIN
        SET @blockName = 'DeleteTicketTools'; SET @startTime = GETDATE();
        BEGIN TRY       
            --Delete the TOOLING records of TicketTools. 
            DELETE FROM [dbo].[TicketTool] WHERE [Sequence] = 0;
            SET @infoStr ='TotalRowsAffected|'+ Convert(VARCHAR, @@ROWCOUNT);
        END TRY
        BEGIN CATCH
--      ==================================[Do NOT change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE());
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT;
    END


    -- BLOCK END
    IF @IsError = 0
    BEGIN
        SET @blockName = 'InsertTicketCylinderTools'; SET @startTime = GETDATE();
        DECLARE @MissingTicketMaster INT;
        DECLARE @MissingToolInventory INT;
        
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

                [TempTicketTools] AS (
                    SELECT [Number] AS [TicketNumber], [ToolNumber], [Sequence], [Description]
                    FROM (
                        SELECT [T].[Number], [T].[MainTool] AS [ToolNumber], 1 AS [Sequence] , [LTT].[Notes] AS [Description]
                        FROM [dbo].[Ticket] [T] WITH (NOLOCK)
                            INNER JOIN [LatestTempTooling] [LTT] ON [T].[MainTool] = [LTT].[Number]
                            
                        UNION ALL
                            
                        SELECT [Number], [ToolNo2] AS [ToolNumber], 2 AS [Sequence], [Tool2Descr] AS [Description]
                        FROM [dbo].[Ticket] WITH (NOLOCK)
                            
                        UNION ALL
                            
                        SELECT [Number], [ToolNo3] AS [ToolNumber], 3 AS [Sequence], [Tool3Descr] AS [Description]
                        FROM [dbo].[Ticket] WITH (NOLOCK)
                            
                        UNION ALL
                            
                        SELECT [Number], [ToolNo4] AS [ToolNumber], 4 AS [Sequence], [Tool4Descr] AS [Description]
                        FROM [dbo].[Ticket] WITH (NOLOCK)
                            
                        UNION ALL
                            
                        SELECT [Number], [ToolNo5] AS [ToolNumber], 5 AS [Sequence], [Tool5Descr] AS [Description]
                        FROM [dbo].[Ticket] WITH (NOLOCK)
                    ) AS [MTT]
                )
                
                SELECT
                    [TTT].[TicketNumber],
                    [TTT].[Sequence],
                    ISNULL(CAST([TTT].[ToolNumber] AS NVARCHAR(200)), CAST([TTLT].[ToolNo] AS NVARCHAR(200))) AS [ToolNumber],
                    IIF([TTT].[ToolNumber] IS NULL, [TTLT].[ToolDescr], [TTT].[Description]) AS [Description],
                    IIF(@IsUpdatedLT = 1, IIF([TTT].[Sequence] = 1, 1, [TTLT].[RoutingNo]), NULL) AS [RoutingNo]
                        ---- Set RoutingNumber as "Null" for the tenants with LabelTraxx version < 9.3
                        ---- Set RoutingNumber as "1" for Press task (sequence = 1) of the tenants with LabelTraxx version >= 9.3

                INTO [dbo].[#MatchingTicketTools]
                FROM [TempTicketTools] AS [TTT]
                    LEFT JOIN [dbo].[TicketTools_LT] AS [TTLT] WITH (NOLOCK) ON [TTT].[TicketNumber] = [TTLT].[TicketNumber] AND [TTT].[Sequence] = [TTLT].[RoutingNo]
                WHERE [TTT].[ToolNumber] IS NOT NULL OR [TTLT].[ToolNo] IS NOT NULL;


            SELECT [EM].[SourceEquipmentId]
			INTO [dbo].[#EquipmentWithCylindersEnabled]
            FROM [dbo].[EquipmentMaster] AS [EM] WITH (NOLOCK)
                INNER JOIN [dbo].[StagingRequirementGroup] AS [SRQ] WITH (NOLOCK) ON [EM].[WorkcenterTypeId] = [SRQ].[WorkcenterTypeId]
			    INNER JOIN [dbo].[StagingRequirement] AS [SR] WITH (NOLOCK) ON [SRQ].[StagingRequirementId] = [SR].[Id]
			WHERE [SR].[Name] = 'Cylinders';
            

            ;WITH
                [DistinctToolingInventory] AS (
                    SELECT [SourceToolingId], [ToolType], MIN([Id]) AS [Id]
                    FROM [dbo].[ToolingInventory] WITH (NOLOCK)
                    WHERE [ToolType] = 'Cylinder'
                    GROUP BY [SourceToolingId], [ToolType]
                )

            UPDATE [dbo].[TicketTool] 
            SET [RequiredQuantity] = [TAV].[Value],
		        [ModifiedOn] = GETUTCDATE()
            FROM [dbo].[TicketTool] [TT]
                INNER JOIN [dbo].[TicketMaster] AS [TM] WITH (NOLOCK) ON [TT].[TicketId] = [TM].[ID]
                INNER JOIN [dbo].[TicketAttributeValues_temp] AS [TAV] WITH (NOLOCK) ON [TM].[ID] = [TAV].[TicketId] AND [TAV].[Name] = 'NumberOfCylinders'
                INNER JOIN [dbo].[#EquipmentWithCylindersEnabled] AS [ECE] ON [TM].[Press] = [ECE].[SourceEquipmentId]
                INNER JOIN [DistinctToolingInventory] AS [TI] ON [TI].[Id] = [TT].[ToolingId];


			;WITH
                -- Identify tickets which already have a cylinder 
                [TicketsWithCylinders] AS (
                    SELECT [TT].[TicketId] 
                    FROM [dbo].[TicketTool] AS [TT] WITH (NOLOCK)
                        INNER JOIN [dbo].[ToolingInventory] AS [TI] WITH (NOLOCK) ON [TT].[ToolingId] = [TI].[Id]
                    WHERE [TI].[ToolType] = 'Cylinder'
                    GROUP BY [TT].[TicketId]
                ),

                -- For tickets that don't already have a cylinder, identify compatible cylinder.
                [RollsCalculation] AS (
                    SELECT DISTINCT
                        [TM].[ID] AS [TicketId],
                        [TI2].[Id] AS [ToolingId],
                        0 AS [Sequence],
                        GETUTCDATE() AS [CreatedOn],
                        GETUTCDATE() AS [ModifiedOn],
                        [TT].[Description] AS [Description],
                        [TAV].[Value] AS [RequiredQuantity],
                        [TT].[RoutingNumber]
                    FROM [dbo].[TicketTool] AS [TT] WITH (NOLOCK)
                        INNER JOIN [dbo].[ToolingInventory] AS [TI] WITH (NOLOCK) ON [TT].[ToolingId] = [TI].[Id] AND [TT].[Sequence] = 1
                        INNER JOIN [dbo].[TicketMaster] AS [TM] WITH (NOLOCK) ON [TM].[ID] = [TT].[TicketId]
                        INNER JOIN [dbo].[EquipmentMaster] AS [EM] WITH (NOLOCK) ON [EM].[SourceEquipmentId] = [TM].[Press] --Assume only press step can use cylinders ON flexo workcenter
                        LEFT JOIN [dbo].[ToolingInventory] AS [TI2] WITH (NOLOCK) ON [TI2].[DieSize] = [TI].[DieSize] AND [TI2].[GearTeeth] = [TI].[GearTeeth] AND [TI2].[ToolType] = 'Cylinder' AND [TI2].[AvailableQuantity] > 0
                        INNER JOIN [dbo].[TicketAttributeValues_temp] AS [TAV] WITH (NOLOCK) ON [TM].[ID] = [TAV].[TicketId] AND [TAV].[Name] = 'NumberOfCylinders'
                        INNER JOIN [dbo].[#EquipmentWithCylindersEnabled] AS [ECE] ON [TM].[Press] = [ECE].[SourceEquipmentId]
                        LEFT JOIN [TicketsWithCylinders] AS [TWC] ON [TM].[ID] = [TWC].[TicketId]
                    WHERE [TI].[IsEnabled] = 1 AND [TI2].[IsEnabled] = 1 AND [TI].[IsEnabled] = 1 AND [TI2].[IsEnabled] = 1 AND [TWC].[TicketId] IS NULL
                )

                --Insert compatible cylinders INTo ticket tool
                INSERT INTO [dbo].[TicketTool] ([Id], [TicketId], ToolingId, [Sequence], [CreatedOn], [ModifiedOn], [Description], [RequiredQuantity], [RoutingNumber])
                SELECT
                    NEWID(),
                    [TicketId],
                    [ToolingId],
                    0, -- If compatible cylinder is calculated, sequence is 0
                    GETUTCDATE(),
                    GETUTCDATE(),
                    [Description],
                    [RequiredQuantity],
                    [RoutingNumber]
                FROM [RollsCalculation]; 


            SELECT @MissingTicketMaster = COUNT(1)
            FROM [dbo].[#MatchingTicketTools] AS [MTT]
                LEFT JOIN [dbo].[TicketMaster] AS [TM] WITH(NOLOCK) ON [TM].[SourceTicketId] = [MTT].[TicketNumber]
            WHERE [TM].[ID] IS NULL;
                    
            SELECT @MissingToolInventory = COUNT(1)
            FROM [dbo].[#MatchingTicketTools] AS [MTT]
                LEFT JOIN [dbo].[ToolingInventory] AS [TI] WITH(NOLOCK) ON [TI].[SourceToolingId] = [MTT].[ToolNumber]
            WHERE [TI].[Id] IS NULL;

            IF(@MissingTicketMaster > 0 or @MissingToolInventory > 0)
            BEGIN
                SET @warningStr ='MappingNotFound_TicketMaster_Ticket|'+ Convert(VARCHAR, @MissingTicketMaster)
                            +'#MappingNotFound_ToolingInventory_Ticket|'+ Convert(VARCHAR, @MissingToolInventory);
            END
            
            SET @infoStr ='TotalRowsAffected|'+ Convert(VARCHAR, @@ROWCOUNT);

        END TRY
        BEGIN CATCH
--      ==================================[Do NOT change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END


    -- Delete temporary table
    DROP TABLE IF EXISTS #MatchingTicketTools;
	DROP TABLE IF EXISTS #EquipmentWithCylindersEnabled;


--      ========================[final commit log (do NOT change)]=======================================
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(),
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error');
    END
    
    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================
END
