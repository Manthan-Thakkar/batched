CREATE PROCEDURE [dbo].[spInitializeScheduleStatus]
@entity VARCHAR(50),
@desc VARCHAR(500),
@timeoutInMs INT,
@refId VARCHAR(36)
AS
BEGIN
    DECLARE @IsError bit = 0
    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE
            scheduleRunStatus
        WHERE ExpiryTimeStamp < GetUTCDATE()
        DECLARE @currTimestamp DATETIME = GetUTCDATE()
        INSERT INTO scheduleRunStatus VALUES
        (
            NEWID(),
            @entity,
            'In-Progress',
            @desc,
            DATEADD(MILLISECOND, @timeoutInMs, @currTimestamp),
            @currTimestamp,
            @refId,
            GetUTCDATE(),
            GetUTCDATE()
        )
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