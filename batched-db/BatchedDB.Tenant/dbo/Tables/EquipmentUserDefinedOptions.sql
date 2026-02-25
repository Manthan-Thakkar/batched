CREATE TABLE [dbo].[EquipmentUserDefinedOptions]
    (
        [Id] INT NOT NULL PRIMARY KEY,
        [EquipmentId] VARCHAR(36) NOT NULL,
        [Description] NVARCHAR(200) NULL,
        [SpeedChange] REAL NULL,
        [CreatedOnUTC] DATETIME NOT NULL,
        [ModifiedOnUTC] DATETIME NOT NULL,

        CONSTRAINT FK_EquipmentUserDefinedOptions_Equipment
            FOREIGN KEY (EquipmentId) REFERENCES EquipmentMaster(Id)
    );