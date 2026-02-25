CREATE TRIGGER TR_MasterRollClassificationGroup_Insert_Update_Delete
ON MasterRollClassificationGroup
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

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'MasterRollClassificationGroup')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'MasterRollClassificationGroup'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'MasterRollClassificationGroup', @CurrentDateTimeUtc)
        END
    END
END