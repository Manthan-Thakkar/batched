CREATE PROCEDURE [dbo].[spCalculateEquipmentDslValues]
	@equipments udt_equipmentInfo ReadOnly
AS
BEGIN
Select 
	em.ID							as __equipmentId,
	CAST( fm.ID as varchar(20))		as __contextId,
	fm.ToothSize				    as EquipmentToothSize_dsl
from EquipmentMaster em	WITH (NOLOCK)
	Left join FlexoMagCylinders fm	WITH (NOLOCK)  on em.SourceEquipmentId = fm.Press
	Where em.ID in (SELECT EquipmentId from @equipments)

Select 
	em.ID							as __equipmentId,
	CAST( EM.ID as varchar(20))		as __contextId ,
	em.[SourceEquipmentId]          as EquipmentNumber_dsl,
	em.IsInlineRewindingRequired	as SupportsInlineRewinding_dsl,
	em.IsInlineSheetingRequired		as SupportsInlineSheeting_dsl,
	em.IsMasterRollBatchingRequired as SupportsMasterRollBatching_dsl,
	em.FacilityId					as EquipmentFacilityID_dsl,
	em.FacilityName					as EquipmentFacilityName_dsl
from EquipmentMaster em	WITH (NOLOCK)
	Where em.ID in (SELECT EquipmentId from @equipments)

END