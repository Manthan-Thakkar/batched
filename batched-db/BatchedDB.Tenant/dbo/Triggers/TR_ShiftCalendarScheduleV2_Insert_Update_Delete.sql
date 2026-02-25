CREATE TRIGGER [TR_ShiftCalendarScheduleV2_Insert_Update_Delete]
    ON ShiftCalendarScheduleV2
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	
	DECLARE @timestamp datetime = GETUTCDATE()
	;WITH ModifiedEquipmentsCTE AS
	(
		SELECT ESM.EquipmentId AS EquipmentId
		FROM inserted I 
		INNER JOIN EquipmentScheduleMapping ESM ON ESM.ShiftCalendarScheduleId = I.Id
		UNION
		SELECT ESM.EquipmentId AS EquipmentId
		FROM deleted D
		INNER JOIN EquipmentScheduleMapping ESM ON ESM.ShiftCalendarScheduleId = D.Id
	)

	SELECT * 
	INTO #ModifiedEquipments
	FROM ModifiedEquipmentsCTE

	INSERT INTO EquipmentAudit(EquipmentId, ModifiedOn)
	SELECT EquipmentId, @timestamp FROM #ModifiedEquipments
	WHERE EquipmentId NOT IN (SELECT EquipmentId FROM EquipmentAudit)
	
	UPDATE EA 
	SET ModifiedOn = @timestamp
	FROM EquipmentAudit EA
	WHERE EquipmentId IN (SELECT EquipmentId FROM #ModifiedEquipments)

	DROP TABLE IF EXISTS #ModifiedEquipments;

END