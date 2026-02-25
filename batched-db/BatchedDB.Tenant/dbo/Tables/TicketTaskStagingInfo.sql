CREATE TABLE TicketTaskStagingInfo (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    TicketId VARCHAR(36) NOT NULL,
    Taskname VARCHAR(36) NOT NULL,
    IsArtProofsStaged BIT NULL,
    IsPlatesStaged BIT NULL,
    IsInksStaged BIT NULL,
    IsCylindersStaged BIT NULL,
    IsToolsStaged BIT NULL,
    IsSubstratesStaged BIT NULL,
    IsCoresStaged BIT NULL,
    CreatedOnUtc DATETIME NOT NULL,
    ModifiedOnUtc DATETIME NOT NULL,
    CONSTRAINT FK_TicketMaster FOREIGN KEY (TicketId) REFERENCES TicketMaster(Id)
);