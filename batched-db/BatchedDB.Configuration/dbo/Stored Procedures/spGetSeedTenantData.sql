/****** Object:  StoredProcedure [dbo].[spGetSeedTenantData]    Script Date: 27-10-2022 18:32:37 ******/
CREATE PROCEDURE [dbo].[spGetSeedTenantData] 
	@tenantId nvarchar (36)
AS 
BEGIN 
  SET NOCOUNT ON;

  select ID, Name, Description, @tenantId, DataType, UnitOfMeasurement, Scope, IsEnabled, RequiredForMaterialPlanning, 0
  from TicketAttribute where IsEnabled=1

  select FormulaType, FormulaText, TicketAttributeId, RuleText 
  from TicketAttributeFormula 
  join TicketAttribute on (TicketAttribute.ID=TicketAttributeFormula.TicketAttributeId and TicketAttribute.IsEnabled=1)

  select WorkcenterTypeId, TicketAttributeId 
  from TaskClassificationGroup 
  join TicketAttribute on (TicketAttribute.ID=TaskClassificationGroup.TicketAttributeId and TicketAttribute.IsEnabled=1)

  select WorkcenterTypeId, TicketAttributeId 
  from MasterRollClassificationGroup 
  join TicketAttribute on (TicketAttribute.ID=MasterRollClassificationGroup.TicketAttributeId and TicketAttribute.IsEnabled=1)

  select  timezone.ID, timezone.Name, timezone.StandardName, timezone.DaylightSavingName, timezone.DayLightSaving, LinuxTZ
  from Tenant
  join timezone on (Tenant.ID=@tenantId and Tenant.TimeZone=timezone.ID)
  join WindowsLinuxTimezone on timezone.ID = WindowsId

  INSERT INTO [dbo].[ScheduleArchiveInfo]([Id],[TenantId],[TotalArchiveDays],[ArchiveTimeUTC],[ArchiveTimeTenantTimezone], [IsEnabled], [CreatedOnUTC],[ModifiedOnUTC],[CreatedBy],[ModifiedBy])
    SELECT
		NEWID(),
		@TenantId,
		90,
		CONVERT(TIME,
			CONVERT(DATETIMEOFFSET,
				CONVERT(DATETIMEOFFSET,
					CONVERT(datetime, '00:00:00') AT TIME ZONE timezone
				) AT TIME ZONE 'UTC')
		),
		CONVERT( TIME, CONVERT(datetime, '00:00:00') AT TIME ZONE timezone),
		1,
		GETUTCDATE(),
		GETUTCDATE(),
		'Batched',
		'Batched'
	FROM TENANT T
	WHERE T.Id = @TenantId
 
END

