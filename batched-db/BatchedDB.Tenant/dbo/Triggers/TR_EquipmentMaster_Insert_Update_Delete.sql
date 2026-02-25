CREATE TRIGGER [TR_EquipmentMaster_Insert_Update_Delete]
    ON EquipmentMaster
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @timestamp datetime = GETUTCDATE();
	CREATE TABLE #ModifiedEquipments (EquipmentId varchar(36))
	IF UPDATE (AvailableForScheduling) OR Update(IsEnabled)
	BEGIN
		INSERT INTO #ModifiedEquipments
		SELECT DISTINCT i.ID AS EquipmentId
		FROM inserted i
		INNER JOIN deleted d
		ON i.ID = d.ID
		WHERE i.AvailableForScheduling != d.AvailableForScheduling OR i.IsEnabled != d.IsEnabled
	END

	INSERT INTO EquipmentAudit(EquipmentId, ModifiedOn)
	SELECT EquipmentId, @timestamp FROM #ModifiedEquipments
	WHERE EquipmentId NOT IN (SELECT EquipmentId FROM EquipmentAudit)
	
	UPDATE EA 
	SET ModifiedOn = @timestamp
	FROM EquipmentAudit EA
	WHERE EquipmentId IN (SELECT EquipmentId FROM #ModifiedEquipments)

	DROP TABLE IF EXISTS #ModifiedEquipments;

END