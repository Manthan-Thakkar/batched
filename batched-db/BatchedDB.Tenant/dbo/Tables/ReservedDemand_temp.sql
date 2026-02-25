CREATE TABLE ReservedDemand_temp (
    Id VARCHAR(36) NOT NULL,
    ReservationEventId VARCHAR(36) NOT NULL,
    ActualDemand REAL NOT NULL,
    NetReservedDemand REAL NOT NULL,
    CreatedOnUtc DATETIME NOT NULL,
    ModifiedOnUtc DATETIME NOT NULL,
    PRIMARY KEY (Id),
    CONSTRAINT FK_ReservedDemand_tempToReservationEvents FOREIGN KEY (ReservationEventId) REFERENCES ReservationEvents(Id),
);