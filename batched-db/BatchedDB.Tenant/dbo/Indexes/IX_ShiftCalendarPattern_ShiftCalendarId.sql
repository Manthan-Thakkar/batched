CREATE NONCLUSTERED INDEX [IX_ShiftCalendarPattern_ShiftCalendarId]
ON [dbo].ShiftCalendarPattern (ShiftCalendarId)
			INCLUDE ([StartTime],[EndTime],[DayOfWeek])