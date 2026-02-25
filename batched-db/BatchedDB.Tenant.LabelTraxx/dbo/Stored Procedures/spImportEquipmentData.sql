CREATE PROCEDURE spImportEquipmentData
	@TenantId nvarchar(36)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- 1.
	-- Identify updates - By checking matching LT Equipment Id column against EquipmentMaster SourceEquipmentId and Source = 'LabelTraxx' 
	-- Update the EquipmentMaster Name, Description. Set IsEnabled to the inverse of Inactive

	-- EquipmentMaster updates
	update EM 
	set 
		EM.Name = E.Number, 
		EM.DisplayName = E.Number,
		EM.Description = E.Description,
		EM.IsEnabled = (case when E.Inactive = 0 then 1 else 0 end),
		SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
		SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)),
		ModifiedOn = GETUTCDATE()
	from EquipmentMaster EM
	inner join Equipment E on E.ID = EM.SourceEquipmentId and EM.Source = 'LabelTraxx'
	where TenantId = @TenantId


	-- 2.
	-- Identify inserts - By checking (using joins) which LT Equipment records do not have a matching Id in EquipmentCustomField 
	-- where Key is LTEquipmentId - Insert the new records into EquipmentMasterData and EquipmentCustomField data (keys LTEquipmentId, HasTurredRewinder). 
	-- All statuses are set to false. Set create and modified on as current time.
	
	-- EquipmentMaster inserts: 
	insert into EquipmentMaster (ID, TenantId, Source, SourceEquipmentId, Name, DisplayName, Description, SourceCreatedOn, SourceModifiedOn, CreatedOn, ModifiedOn)
	select 
		NEWID() ID,
		@TenantId TenantId,
		'LabelTraxx' Source,
		ID SourceEquipmentId,
		Number Name,
		Number DisplayName,
		Description Description,
		CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
		CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
		GETUTCDATE() CreatedOn,
		GETUTCDATE() ModifiedOn
	from 
		Equipment
	where 
		ID not in (select CAST(SourceEquipmentId as int) from EquipmentMaster where Source = 'LabelTraxx')
	


	-- 3.
	-- Identify deletes - Check any SourceEquipmentIds do not occur in LabelTraxx Equipment table. Delete those records from EquipmentMaster table.
	delete from EquipmentMaster 
	where SourceEquipmentId not in (
		select 
			ID 
		from 
			Equipment
	)
	and Source = 'LabelTraxx'
	



END