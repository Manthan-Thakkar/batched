BEGIN TRY
BEGIN TRANSACTION

	DECLARE @StartDateTime  DATETIME;
	SELECT @StartDateTime = CAST(cast(DATEADD(d, -730, getdate()) AS DATE) AS DATETIME)
	DECLARE @minimumTime DATETIME;
	SELECT @minimumTime = MIN(THEDATETIME) FROM MinutewiseCalendar

	IF (@minimumTime IS NULL OR @minimumTime != @StartDateTime)
	BEGIN
			TRUNCATE TABLE [dbo].[MinutewiseCalendar]

			IF EXISTS(
			SELECT 1 FROM sys.indexes
			WHERE name='IX_MinutewiseCalendar_TheDate' 
			AND object_id = OBJECT_ID('dbo.MinutewiseCalendar'))
			BEGIN
				DROP INDEX [IX_MinutewiseCalendar_TheDate] ON [dbo].[MinutewiseCalendar]
			END

			IF EXISTS(
			Select 1 from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
			where TABLE_NAME = 'MinutewiseCalendar'
			and CONSTRAINT_TYPE = 'PRIMARY KEY')
			BEGIN
				ALTER TABLE [MinutewiseCalendar]
				DROP CONSTRAINT [PK_MinutewiseCalendarTheDateTime];
			END

			IF EXISTS(
			Select 1 from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
			where TABLE_NAME = 'MinutewiseCalendar'
			and CONSTRAINT_TYPE = 'FOREIGN KEY')
			BEGIN	
				ALTER TABLE [MinutewiseCalendar]
				DROP CONSTRAINT [FK_MinutewiseCalendar_CalendarTheDate];
			END

			IF EXISTS(
			Select 1 from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
			where TABLE_NAME = 'MinutewiseCalendar'
			and CONSTRAINT_TYPE = 'UNIQUE')
			BEGIN
				ALTER TABLE [MinutewiseCalendar]
				DROP CONSTRAINT [AK_MinutewiseCalendar_TimeIndex];
			END


		DECLARE @batch_size int = 2629440 / 40
		DECLARE @CutoffDateTime datetime;
		Declare @current_size int = 0;

		SELECT @CutoffDateTime = CAST(cast(DATEADD(d, 1095, getdate()) AS DATE) AS DATETIME)

		WHILE @StartDateTime <= @CutoffDateTime
		BEGIN

			;WITH seq(n) AS 
			(
			  SELECT 0 UNION ALL SELECT n + 1 FROM seq
			  WHERE n + 1 < @batch_size
			),
			d(e) AS 
			(
			  SELECT n as e FROM seq
			)
	
			Insert into [MinutewiseCalendar] ([TheDate], [TheDateTime],[TimeIndex])
			Select 							  
				CONVERT(date, DATEADD(minute, e , @StartDateTime)) as TheDate,
				DATEADD(minute, e, @StartDateTime) as TheDateTime,
				@current_size  + e + 1						  
			from d 
			OPTION (MAXRECURSION 0);

			SET @StartDateTime = DATEADD(minute, @batch_size, @StartDateTime)
			Set @current_size += @batch_size 
		END

		ALTER TABLE [MinutewiseCalendar]
		add CONSTRAINT [PK_MinutewiseCalendarTheDateTime] PRIMARY KEY([TheDateTime])
	
		
		ALTER TABLE [MinutewiseCalendar]
		add CONSTRAINT [AK_MinutewiseCalendar_TimeIndex] UNIQUE ([TimeIndex])
		CREATE NONCLUSTERED INDEX [IX_MinutewiseCalendar_TheDate] ON [dbo].[MinutewiseCalendar]
		(
			[TheDate] ASC
		)
		INCLUDE([TimeIndex])
	END


COMMIT
END TRY

BEGIN CATCH
	SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
	ROLLBACK TRANSACTION
END CATCH
GO