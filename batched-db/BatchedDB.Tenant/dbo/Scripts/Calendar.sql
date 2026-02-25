BEGIN TRY
BEGIN TRANSACTION

	DECLARE @StartDate  DATETIME;
	SELECT	@StartDate = CAST(DATEADD(d, -730, getdate()) AS DATE)
	DECLARE @minimumDate DATETIME;
	SELECT @minimumDate = MIN(THEDATE) FROM Calendar

	IF (@minimumDate IS NULL OR @minimumDate != @StartDate)
	BEGIN
	
		TRUNCATE TABLE CALENDAR;

		DECLARE @CutoffDate DATETIME;
		SELECT @CutoffDate = CAST(DATEADD(d, 1095, getdate()) AS DATE)

		;WITH seq(n) AS 
		(
		  SELECT 0 UNION ALL SELECT n + 1 FROM seq
		  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
		),
		d(d) AS 
		(
		  SELECT DATEADD(DAY, n, @StartDate) FROM seq
		),
		src AS
		(
		  SELECT
			TheDate         = CONVERT(date, d),
			TheDateTime     = CONVERT(datetime, d),
			TheDay          = DATEPART(DAY,       d),
			TheDayName      = Left(DATENAME(WEEKDAY,   d), 3),
			TheWeek         = DATEPART(WEEK,      d),
			TheISOWeek      = DATEPART(ISO_WEEK,  d),
			TheDayOfWeek    = DATEPART(WEEKDAY,   d),
			TheMonth        = DATEPART(MONTH,     d),
			TheMonthName    = DATENAME(MONTH,     d),
			TheQuarter      = DATEPART(Quarter,   d),
			TheYear         = DATEPART(YEAR,      d),
			TheFirstOfMonth = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
			TheLastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
			TheDayOfYear    = DATEPART(DAYOFYEAR, d)
		  FROM d
		),
		dim AS
		(
		  SELECT
			TheDate, 
			TheDateTime,
			TheDay,
			TheDaySuffix        = CONVERT(char(2), CASE WHEN TheDay / 10 = 1 THEN 'th' ELSE 
									CASE RIGHT(TheDay, 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
									WHEN '3' THEN 'rd' ELSE 'th' END END),
			TheDayName,
			TheDayOfWeek,
			TheDayOfWeekInMonth = CONVERT(tinyint, ROW_NUMBER() OVER 
									(PARTITION BY TheFirstOfMonth, TheDayOfWeek ORDER BY TheDate)),
			TheDayOfYear,
			IsWeekend           = CASE WHEN TheDayOfWeek IN (CASE @@DATEFIRST WHEN 1 THEN 6 WHEN 7 THEN 1 END,7)
									THEN 1 ELSE 0 END,
			TheWeek,
			TheISOweek,
			TheFirstOfWeek      = DATEADD(DAY, 1 - TheDayOfWeek, TheDate),
			TheLastOfWeek       = DATEADD(DAY, 6, DATEADD(DAY, 1 - TheDayOfWeek, TheDate)),
			TheWeekOfMonth      = CONVERT(tinyint, DENSE_RANK() OVER 
									(PARTITION BY TheYear, TheMonth ORDER BY TheWeek)),
			TheMonth,
			TheMonthName,
			TheFirstOfMonth,
			TheLastOfMonth      = MAX(TheDate) OVER (PARTITION BY TheYear, TheMonth),
			TheFirstOfNextMonth = DATEADD(MONTH, 1, TheFirstOfMonth),
			TheLastOfNextMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 2, TheFirstOfMonth)),
			TheQuarter,
			TheFirstOfQuarter   = MIN(TheDate) OVER (PARTITION BY TheYear, TheQuarter),
			TheLastOfQuarter    = MAX(TheDate) OVER (PARTITION BY TheYear, TheQuarter),
			TheYear,
			TheISOYear          = TheYear - CASE WHEN TheMonth = 1 AND TheISOWeek > 51 THEN 1 
									WHEN TheMonth = 12 AND TheISOWeek = 1  THEN -1 ELSE 0 END,      
			TheFirstOfYear      = DATEFROMPARTS(TheYear, 1,  1),
			TheLastOfYear,
			IsLeapYear          = CONVERT(bit, CASE WHEN (TheYear % 400 = 0) 
									OR (TheYear % 4 = 0 AND TheYear % 100 <> 0) 
									THEN 1 ELSE 0 END),
			Has53Weeks          = CASE WHEN DATEPART(ISO_WEEK, TheLastOfYear) = 53 THEN 1 ELSE 0 END,
			Has53ISOWeeks       = CASE WHEN DATEPART(WEEK,     TheLastOfYear) = 53 THEN 1 ELSE 0 END,
			MMYYYY              = CONVERT(char(2), CONVERT(char(8), TheDate, 101))
								  + CONVERT(char(4), TheYear),
			Style101            = CONVERT(char(10), TheDate, 101),
			Style103            = CONVERT(char(10), TheDate, 103),
			Style112            = CONVERT(char(8),  TheDate, 112),
			Style120            = CONVERT(char(10), TheDate, 120)
		  FROM src
		)

		Insert INTO Calendar (TheDate,TheDateTime,TheDay,TheDaySuffix,TheDayName,TheDayOfWeek,TheDayOfWeekInMonth,TheDayOfYear,IsWeekend,TheWeek,TheISOweek,TheFirstOfWeek,TheLastOfWeek,TheWeekOfMonth,TheMonth,TheMonthName,TheFirstOfMonth,TheLastOfMonth,TheFirstOfNextMonth,TheLastOfNextMonth,TheQuarter,TheFirstOfQuarter,TheLastOfQuarter,TheYear,TheISOYear,TheFirstOfYear,TheLastOfYear,IsLeapYear,Has53Weeks,Has53ISOWeeks,MMYYYY,Style101,Style103,Style112,Style120)
		select 
			dim.TheDate,
			dim.TheDateTime,
			dim.TheDay,
			dim.TheDaySuffix,
			dim.TheDayName,
			dim.TheDayOfWeek,
			dim.TheDayOfWeekInMonth,
			dim.TheDayOfYear,
			dim.IsWeekend,
			dim.TheWeek,
			dim.TheISOweek,
			dim.TheFirstOfWeek,
			dim.TheLastOfWeek,
			dim.TheWeekOfMonth,
			dim.TheMonth,
			dim.TheMonthName,
			dim.TheFirstOfMonth,
			dim.TheLastOfMonth,
			dim.TheFirstOfNextMonth,
			dim.TheLastOfNextMonth,
			dim.TheQuarter,
			dim.TheFirstOfQuarter,
			dim.TheLastOfQuarter,
			dim.TheYear,
			dim.TheISOYear,
			dim.TheFirstOfYear,
			dim.TheLastOfYear,
			dim.IsLeapYear,
			dim.Has53Weeks,
			dim.Has53ISOWeeks,
			dim.MMYYYY,
			dim.Style101,
			dim.Style103,
			dim.Style112,
			dim.Style120
		FROM dim
		order by TheDate
		OPTION (MAXRECURSION 0);
	END

COMMIT

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_MinutewiseCalendar_CalendarTheDate'
      AND parent_object_id = OBJECT_ID('MinutewiseCalendar')
)
BEGIN

	ALTER TABLE [MinutewiseCalendar]
	ADD CONSTRAINT [FK_MinutewiseCalendar_CalendarTheDate] FOREIGN KEY([TheDate]) REFERENCES Calendar(TheDate)
END 
	

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