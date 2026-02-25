CREATE NONCLUSTERED INDEX [IX_FacilityHoliday_HolidayId]
ON [dbo].FacilityHoliday (HolidayId)
		INCLUDE ([FacilityId])