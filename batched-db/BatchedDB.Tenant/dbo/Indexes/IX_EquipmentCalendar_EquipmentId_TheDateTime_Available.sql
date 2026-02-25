	CREATE NONCLUSTERED INDEX [IX_EquipmentCalendar_EquipmentId_TheDateTime_Available] ON [dbo].[EquipmentCalendar] (
		[EquipmentId],
		[TheDateTime] DESC,
		[Available]
		) INCLUDE (
		[AdjustedTimeIndex]
		);
		