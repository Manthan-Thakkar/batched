CREATE NONCLUSTERED INDEX [IX_EquipmentMaster_SourceEquipmentId]
ON
	[dbo].[EquipmentMaster]
	([SourceEquipmentId])
	INCLUDE ([ID])
