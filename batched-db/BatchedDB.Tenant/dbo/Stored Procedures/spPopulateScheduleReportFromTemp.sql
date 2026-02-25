CREATE PROCEDURE [dbo].[spPopulateScheduleReportFromTemp]
    -- Standard parameters for all stored procedures
    @EquipmentIds AS UDT_SINGLEFIELDFILTER readonly,
	@TenantId       nvarchar(36),
    @CorelationId varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN
--  ==============================logging variables (do not change)=======================================
    DECLARE
        @spName                 varchar(100) = 'spPopulateScheduleReportFromTemp',
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
    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0
        BEGIN
            SET @blockName = 'DeleteFromScheduleReport'; SET @startTime = GETDATE();
            DECLARE @MissingTicketTool int;
        BEGIN TRY   

            --Cancel transaction if temp table empty
			IF NOT EXISTS(SELECT * FROM ScheduleReport_Temp WHERE ((SELECT Count(1) FROM @EquipmentIds) = 0  OR EquipmentId  IN (SELECT field FROM @EquipmentIds)))
			   THROW 50001, 'ScheduleReport_Temp is empty, failing operation', 1

            DELETE FROM ScheduleReport
			WHERE ((SELECT Count(1) FROM @EquipmentIds) = 0 
            OR EquipmentId  IN (SELECT field FROM @EquipmentIds)
            OR EquipmentId  IN (SELECT EquipmentId FROM EquipmentAudit ea
                INNER JOIN EquipmentMaster em on ea.EquipmentId = em.ID
                WHERE ea.ModifiedOn >=DATEADD(day,-7, GETDATE()) 
                AND (em.IsEnabled = 0 OR em.AvailableForScheduling = 0)));        
            SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
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
        SET @blockName = 'CopyTempIntoScheduleReport'; SET @startTime = GETDATE();
        BEGIN TRY       

            INSERT INTO ScheduleReport
            SELECT * FROM ScheduleReport_Temp
			WHERE ((SELECT Count(1) FROM @EquipmentIds) = 0  OR EquipmentId  IN (SELECT field FROM @EquipmentIds));    

            SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
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
