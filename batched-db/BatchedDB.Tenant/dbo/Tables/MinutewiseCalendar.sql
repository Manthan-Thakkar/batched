CREATE TABLE [dbo].[MinutewiseCalendar] (
	[TheDate]           DATE			NOT NULL,
	[TheDateTime]       DATETIME		NOT NULL,
	[TimeIndex]         BIGINT		    NOT NULL,
	CONSTRAINT [PK_MinutewiseCalendarTheDateTime] PRIMARY KEY([TheDateTime]),
	CONSTRAINT [FK_MinutewiseCalendar_CalendarTheDate] FOREIGN KEY([TheDate]) REFERENCES Calendar(TheDate),
	CONSTRAINT [AK_MinutewiseCalendar_TimeIndex] UNIQUE ([TimeIndex]),
)