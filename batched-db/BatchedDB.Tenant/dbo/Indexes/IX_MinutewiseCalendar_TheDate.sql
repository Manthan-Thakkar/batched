CREATE NONCLUSTERED INDEX [IX_MinutewiseCalendar_TheDate]
	ON [dbo].[MinutewiseCalendar] ([TheDate])
	INCLUDE ([TimeIndex])
