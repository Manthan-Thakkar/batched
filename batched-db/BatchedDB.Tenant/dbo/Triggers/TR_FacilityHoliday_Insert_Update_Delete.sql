CREATE TRIGGER [dbo].[TR_FacilityHoliday_Insert_Update_Delete]
    ON [dbo].[FacilityHoliday]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DROP TABLE IF EXISTS #ModifiedEquipments;
	
	DECLARE @timestamp datetime = GETUTCDATE();
	
	SELECT DISTINCT EM.ID AS EquipmentId
		INTO #ModifiedEquipments
		FROM 
			(SELECT DISTINCT I.FacilityId AS FacilityId
			FROM inserted I
			UNION
			SELECT DISTINCT D.FacilityId AS FacilityId
			FROM deleted D) AS TempFacilities
		INNER JOIN 
			EquipmentMaster EM ON EM.FacilityId = TempFacilities.FacilityId 
				AND EM.IsEnabled = 1
				AND EM.AvailableForScheduling = 1
		
	INSERT INTO EquipmentAudit(EquipmentId, ModifiedOn)
	SELECT EquipmentId, @timestamp FROM #ModifiedEquipments
	WHERE EquipmentId NOT IN (SELECT EquipmentId FROM EquipmentAudit)
	
	UPDATE EA 
	SET ModifiedOn = @timestamp
	FROM EquipmentAudit EA
	WHERE EquipmentId IN (SELECT EquipmentId FROM #ModifiedEquipments)

	DROP TABLE IF EXISTS #ModifiedEquipments;
END