CREATE PROCEDURE [dbo].[spImportTicketToolData_Radius]
    -- Standard parameters for all stored procedures
    @TenantId       nvarchar(36),
    @CorelationId varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE
        @spName                 varchar(100) = 'spImportTicketToolData',
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

        -- #PV_Jobs temp table WITH concatenated ticket number
    SELECT 
        J.*,JC.JobCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
    INTO #PV_Jobs
    FROM PV_job J
        INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
    where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
        BEGIN
            SET @blockName = 'GeneratingTicketTools'; SET @startTime = GETDATE();
            DECLARE @MissingTicketTool int;
        BEGIN TRY   

		SELECT  
            distinct
		    J.JobCode ,
		    TS.ToolTypeCode,
		    JTS.SeqNum,
		    JTS.CompNum ,
		    J.PlantCode,
		    TS.SpecName,
		    TS.SpecCode,
		    J.TicketNumber AS TicketNumber
		    INTO #MatchingTicketTools 
		FROM #PV_Jobs J
		INNER JOIN PV_JobToolSpec  JTS ON JTS.JobCode=J.JobCode and JTS.PlantCode = J.PlantCode --and JTS.JobCmpNum=J.JobCmpNum 
		INNER JOIN PV_ToolSpec TS ON JTS.CompNum = TS.CompNum and JTS.SpecCode = TS.SpecCode
        UNION
        SELECT DISTINCT
            J.JobCode,
            WS.ToolTypeCode,
            WS.SeqNum,
            WS.CompNum,
            J.PlantCode,
            WS.SpecName,
            WS.SpecCode,
            J.TicketNumber
        FROM #PV_Jobs J
        LEFT JOIN PV_JobToolSpec JTS ON JTS.JobCode = J.JobCode AND JTS.PlantCode = J.PlantCode
        INNER JOIN WIToolSpec WS ON J.JobCode = WS.Korder
        WHERE JTS.JobCode IS NULL

        
        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
        END

    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
        BEGIN
        SET @blockName = 'DeleteTicketTools'; SET @startTime = GETDATE();
        BEGIN TRY       
            --Delete the records of TicketTools. 
            Truncate Table [dbo].[TicketTool]
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
        DECLARE @MissingTicketMaster int;
        DECLARE @MissingToolInventory int;
        BEGIN TRY
            ----Insert the records into TicketTool using Ticket table
            INSERT INTO [dbo].[TicketTool] ([Id], [TicketId], ToolingId, [Sequence], [CreatedOn], [ModifiedOn], [Description])
            SELECT
                NEWID(),
                TM.ID,
                TI.Id,
                ticketTools.SeqNum,
                GETUTCDATE(),
                GETUTCDATE(),
				ticketTools.SpecName -- Confirm
            FROM
            #MatchingTicketTools as ticketTools
            INNER JOIN  TicketMaster TM on ticketTools.TicketNumber = TM.SourceTicketId
			inner join ToolingInventory TI on tickettools.SpecCode = TI.SourceToolingId


            SELECT @MissingTicketMaster = COUNT(1)
                    FROM #MatchingTicketTools 
                    WHERE TicketNumber NOT IN (SELECT SourceTicketId FROM TicketMaster)
            SELECT @MissingToolInventory = COUNT(1)
                    FROM #MatchingTicketTools 
                    WHERE SpecCode NOT IN (SELECT SourceToolingId FROM ToolingInventory)

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

            IF(@MissingTicketMaster > 0 or @MissingToolInventory > 0)
            BEGIN
                SET @warningStr ='MappingNotFound_TicketMaster_Ticket|'+ Convert(varchar, @MissingTicketMaster)
                            +'#MappingNotFound_ToolingInventory_Ticket|'+ Convert(varchar, @MissingToolInventory)
            END
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
    DROP TABLE IF EXISTS #PV_Jobs;
    DROP TABLE IF EXISTS #MatchingTicketTools;
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
