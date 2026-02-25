CREATE TRIGGER TR_TaskClassificationGroup_Insert_Update_Delete
ON TaskClassificationGroup
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS 
    (
        SELECT *
        FROM inserted i
        FULL JOIN deleted d ON i.Id = d.Id
        WHERE 
            i.WorkcenterTypeId <> d.WorkcenterTypeId OR
            i.TicketAttributeId <> d.TicketAttributeId OR
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'TaskClassificationGroup')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'TaskClassificationGroup'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'TaskClassificationGroup', @CurrentDateTimeUtc)
        END
    END
END