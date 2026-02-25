CREATE TABLE [dbo].[TicketUserDefinedOptions]
    (
        [Id] VARCHAR(36) NOT NULL PRIMARY KEY,
        [TicketId] VARCHAR(36) NOT NULL,
        [SourceEquipUDID] INT NOT NULL,
        [IsEnabled] BIT NULL,
        [CreatedOnUTC] DATETIME NOT NULL,
        [ModifiedOnUTC] DATETIME NOT NULL,

        CONSTRAINT FK_TicketUserDefinedOptions_Ticket
            FOREIGN KEY (TicketId) REFERENCES TicketMaster(Id),

        CONSTRAINT FK_TicketUserDefinedOptions_EquipmentUserDefinedOptions
            FOREIGN KEY (SourceEquipUDID) REFERENCES EquipmentUserDefinedOptions(Id)
    );