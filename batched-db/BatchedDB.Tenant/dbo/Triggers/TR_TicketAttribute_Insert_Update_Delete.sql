CREATE TRIGGER TR_TicketAttribute_Insert_Update_Delete
ON TicketAttribute
AFTER INSERT, UPDATE, DELETE
AS
BEGIN

    -- Check if any values have changed or new record inserted or deleted
    IF EXISTS 
    (
        SELECT *
        FROM inserted i
        FULL JOIN deleted d ON i.Id = d.Id
        WHERE
            i.Name <> d.Name OR 
            i.IsEnabled <> d.IsEnabled OR 
            i.RequiredForMaterialPlanning <> d.RequiredForMaterialPlanning OR 
            i.DataType <> d.DataType OR
            i.Scope <> d.Scope OR
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'TicketAttribute')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'TicketAttribute'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'TicketAttribute', @CurrentDateTimeUtc)
        END
    END
END