CREATE TRIGGER TR_EquipmentChangeover_Insert_Update_Delete
ON EquipmentChangeover
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS 
    (
        SELECT *
        FROM inserted i
        FULL JOIN deleted d ON i.Id = d.Id
        WHERE 
            i.ApplicableRuleText <> d.ApplicableRuleText OR 
            i.RuleText <> d.RuleText OR 
            i.ComparisonType <> d.ComparisonType OR
            i.EquipmentId <> i.EquipmentId OR
            i.ChangeTimeInMinutes <> d.ChangeTimeInMinutes OR
            i.SavedRuleText <> d.SavedRuleText OR
            i.Scope <> d.Scope OR
            i.TicketAttributeId <> d.TicketAttributeId OR
            i.IsEnabled <> d.IsEnabled OR
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'EquipmentChangeover')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'EquipmentChangeover'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'EquipmentChangeover', @CurrentDateTimeUtc)
        END
    END
END