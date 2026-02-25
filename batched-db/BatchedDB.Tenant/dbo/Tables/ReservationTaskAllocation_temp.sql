CREATE TABLE ReservationTaskAllocation_temp (
    Id VARCHAR(36) NOT NULL,
    ReservationEventId VARCHAR(36) NOT NULL,
    TicketId VARCHAR(36) NOT NULL,
    TaskName NVARCHAR(255) NOT NULL,
    CreatedOnUtc DATETIME NOT NULL,
    ModifiedOnUtc DATETIME NOT NULL,
    PRIMARY KEY (Id),
    CONSTRAINT Fk_ReservationTaskEventAllocation_temp FOREIGN KEY (ReservationEventId) REFERENCES ReservationEvents(Id),
    CONSTRAINT Fk_ReservationTaskEventAllocation_temp_TicketMaster FOREIGN KEY (TicketId) REFERENCES TicketMaster(Id)
);