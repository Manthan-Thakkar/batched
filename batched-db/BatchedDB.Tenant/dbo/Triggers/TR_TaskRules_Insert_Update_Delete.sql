CREATE TRIGGER TR_TaskRules_Insert_Update_Delete
ON TaskRules
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Check if TaskInfoId or RuleText has changed
    IF EXISTS 
    (
        SELECT *
        FROM inserted i
        FULL JOIN deleted d ON i.Id = d.Id
        WHERE 
            i.TaskInfoId <> d.TaskInfoId OR 
            i.RuleText <> d.RuleText OR 
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'TaskRules')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'TaskRules'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'TaskRules', @CurrentDateTimeUtc)
        END
    END
END