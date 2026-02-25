CREATE PROCEDURE [dbo].[spUpdateScheduleStatus]
@entity VARCHAR(50),
@refId VARCHAR(36)
AS
BEGIN
    DECLARE @IsError bit = 0
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE
           scheduleRunStatus
        SET
            [Status] = 'Complete'
        WHERE
            Entity = @entity
            And RefId = @refId
    END TRY
    BEGIN CATCH
        SET @IsError = 1
        Rollback;
    END CATCH
    IF @IsError = 0
    BEGIN
        COMMIT;
    END
END
