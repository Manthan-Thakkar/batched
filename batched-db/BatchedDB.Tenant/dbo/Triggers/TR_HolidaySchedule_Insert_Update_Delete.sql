CREATE TRIGGER [dbo].[TR_HolidaySchedule_Insert_Update_Delete]
    ON [dbo].[HolidaySchedule]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DROP TABLE IF EXISTS #ModifiedEquipments;
	
	DECLARE @timestamp datetime = GETUTCDATE();
	
	SELECT DISTINCT EM.ID AS EquipmentId
		INTO #ModifiedEquipments
		FROM 
			(SELECT I.Id AS HolidayId
			FROM inserted I
			UNION
			SELECT D.Id AS HolidayId
			FROM deleted D) AS TempHolidays
		INNER JOIN
			FacilityHoliday FH ON FH.HolidayId = TempHolidays.HolidayId
		INNER JOIN
			EquipmentMaster EM ON EM.FacilityId = FH.FacilityId
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