CREATE TRIGGER [TR_EquipmentScheduleMapping_Insert_Delete]
    ON [dbo].[EquipmentScheduleMapping]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @timestamp datetime = GETUTCDATE()
	;WITH ModifiedEquipmentsCTE AS
	(
		SELECT I.EquipmentId AS EquipmentId
		FROM inserted I 
		UNION
		SELECT D.EquipmentId AS EquipmentId
		FROM deleted D
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