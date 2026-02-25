 CREATE TABLE [dbo].[EquipmentSpeed]
    (
        [Id] VARCHAR(36) NOT NULL PRIMARY KEY NONCLUSTERED,
        [EquipmentId] VARCHAR(36) NOT NULL,
        [Level] SMALLINT NOT NULL,
        [LengthFrom] REAL NOT NULL,
        [LengthTo] REAL NOT NULL,
        [Speed] REAL NOT NULL,
        [CreatedOnUTC] DATETIME NOT NULL,
        [ModifiedOnUTC] DATETIME NOT NULL,

        CONSTRAINT FK_EquipmentSpeedMaster_Equipment
            FOREIGN KEY (EquipmentId) REFERENCES EquipmentMaster(Id)
    );