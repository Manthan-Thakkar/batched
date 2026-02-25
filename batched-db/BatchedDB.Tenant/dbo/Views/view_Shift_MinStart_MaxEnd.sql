
--:r "C:\Users\amend\Documents\batched-algo-labeltech\sql\Onboarding_Scripts\000_0_1_Populate_MasterEquipmentReference_static_onetime_LabelTech.sql"
--GO
--:r "C:\Users\amend\Documents\batched-algo-labeltech\sql\Onboarding_Scripts\000_0_2_Populate_SubstrateGrouping_static_onetime_LabelTech.sql"
--GO
--:r "C:\Users\amend\Documents\batched-algo-labeltech\sql\Onboarding_Scripts\000_0_3_Populate_EquipmentShiftByDay_LabelTech.sql"
--GO

CREATE   VIEW [dbo].[view_Shift_MinStart_MaxEnd]

AS

select min(minShiftStart) minShiftStart,
	   max(maxShiftEnd) maxShiftEnd
	   from
(
	select 
		FORMAT(min(m.[Default Shift Start]), 'HH:mm') as minShiftStart,
		FORMAT(max(m.[Default Shift End]), 'HH:mm') as maxShiftEnd
	from MasterEquipmentReference m
	where not (m.[Default Shift Start] = '1900-01-01 00:00:00.000' and m.[Default Shift End] = '1900-01-01 00:00:00.000')
	union
	select 
		FORMAT(min(m.[Shift Start]), 'HH:mm') as minShiftStart,
		FORMAT(max(m.[Shift End]), 'HH:mm') as maxShiftEnd
	from EquipmentShiftByDay m
	where not (m.[Shift Start] = '1900-01-01 00:00:00.000' and m.[Shift End] = '1900-01-01 00:00:00.000')
) shifts
