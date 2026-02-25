CREATE TRIGGER TR_LagDelayConfig_Insert_Update_Delete
ON LagDelayConfig
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
            i.FromId <> d.FromId OR 
            i.ToId <> d.ToId OR
            i.Lag <> d.Lag OR 
            i.Delay <> d.Delay OR 
            i.Type <> d.Type OR
            (i.Id IS NULL OR d.Id IS NULL)  
    )
    BEGIN
        -- Insert or update the entry in RulesAudit table
        DECLARE @CurrentDateTimeUtc datetime = GETUTCDATE()

        IF EXISTS (SELECT * FROM RulesAudit WHERE [Type] = 'LagDelay')
        BEGIN
            -- Update the existing entry
            UPDATE RulesAudit
            SET ModifiedOnUtc = @CurrentDateTimeUtc
            WHERE [Type] = 'LagDelay'
        END
        ELSE
        BEGIN
            -- Insert a new entry
            INSERT INTO RulesAudit (Id, [Type], ModifiedOnUtc)
            VALUES (NEWID(), 'LagDelay', @CurrentDateTimeUtc)
        END
    END
END