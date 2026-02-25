CREATE TABLE ReservationEvents (
    Id VARCHAR(36) NOT NULL,
    ReservationId VARCHAR(36) NOT NULL,
    ReservationEventDate DATETIME NOT NULL,
    WorkcenterId VARCHAR(36) NOT NULL,
    EquipmentId VARCHAR(36) NULL,
    ExpirationDate DATETIME NOT NULL,
    IsExpired BIT NOT NULL,
    ReservedDemand INT NOT NULL,
    CreatedOnUtc DATETIME NOT NULL,
    ModifiedOnUtc DATETIME NOT NULL,
    PRIMARY KEY (Id),
    CONSTRAINT Fk_ReservationEventToReservation FOREIGN KEY (ReservationId) REFERENCES Reservations(Id),
    CONSTRAINT Fk_ReservationEventToEquipment FOREIGN KEY (EquipmentId) REFERENCES EquipmentMaster(Id)
);