CREATE TRIGGER TR_EquipmentConstraint_Insert_Update_Delete
ON EquipmentConstraint
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Check if TicketAttributeId or RuleText has changed
    IF EXISTS 
    (
        SELECT *
        FROM inserted i
        FULL JOIN deleted d ON i.Id = d.Id
        WHERE 
            i.EquipmentId <> d.EquipmentId OR 
            i.RuleText <> d.RuleText OR 
            i.IsEnabled <> d.IsEnabled OR
            i.Scope <> d.Scope OR
            i.TicketAttributeId <> d.TicketAttributeId OR
            i.Operator <> d.Operator OR
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'EquipmentConstraint')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'EquipmentConstraint'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'EquipmentConstraint', @CurrentDateTimeUtc)
        END
    END
END