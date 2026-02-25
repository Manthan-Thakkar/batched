CREATE PROCEDURE spLogScheduleEvents
@tenantId  	NVARCHAR(36),
@scheduleId		NVARCHAR(36),
@status			NVARCHAR(36),
@type			NVARCHAR(10),
@errorStr		NVARCHAR(4000) = null,
@facilityId  	VARCHAR(36) = null,
@valueStreams  VARCHAR(4000) = null,
@scheduledOn	DATETIME = null

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @IsError BIT = 0

	--DELETE LAST 60 DAYS LOGS 
	BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY

			DELETE ScheduleEventLog
			WHERE CreatedOn < DATEADD(day,-60, GETUTCDATE()) 

		END TRY

		BEGIN CATCH
			SET @IsError = 1;
			Rollback;

		END CATCH

		IF @IsError = 0
		BEGIN
			COMMIT;
		END
	END

	--LOG SCHEDULE EVENTS
	BEGIN

	SET @IsError = 0;
	BEGIN TRANSACTION;
	BEGIN TRY
		INSERT INTO ScheduleEventLog 
				  (Id, TenantId, ScheduleId, Status, Type, Error, CreatedOn, ModifiedOn, FacilityId, ValueStreams, ScheduledOn)
			VALUES(NEWID(), @tenantId, @scheduleId, @status, @type, @errorStr, GETUTCDATE(), GETUTCDATE(), @facilityId, @valueStreams, @scheduledOn);
	END TRY

	BEGIN CATCH
		SET @IsError = 1;
			Rollback;
	END CATCH

	IF @IsError = 0
		BEGIN
			COMMIT;
		END

	END

END