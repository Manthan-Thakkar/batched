CREATE NONCLUSTERED INDEX [IX_EquipmentMaster_EquipmentId_FacilityId] ON [dbo].[EquipmentMaster]
(
	[ID] ASC
)
INCLUDE([WorkcenterTypeId],[FacilityId])