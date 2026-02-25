CREATE TRIGGER TR_TicketAttributeFormula_Insert_Update_Delete
ON TicketAttributeFormula
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
            i.TicketAttributeId <> d.TicketAttributeId OR 
            i.RuleText <> d.RuleText OR 
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'TicketAttributeFormula')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'TicketAttributeFormula'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'TicketAttributeFormula', @CurrentDateTimeUtc)
        END
    END
END