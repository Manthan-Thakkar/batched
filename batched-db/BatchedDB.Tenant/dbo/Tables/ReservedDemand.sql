CREATE TABLE ReservedDemand (
    Id VARCHAR(36) NOT NULL,
    ReservationEventId VARCHAR(36) NOT NULL,
    ActualDemand REAL NOT NULL,
    NetReservedDemand REAL NOT NULL,
    CreatedOnUtc DATETIME NOT NULL,
    ModifiedOnUtc DATETIME NOT NULL,
    PRIMARY KEY (Id),
    CONSTRAINT FK_ReservedDemandToReservationEvents FOREIGN KEY (ReservationEventId) REFERENCES ReservationEvents(Id),
);