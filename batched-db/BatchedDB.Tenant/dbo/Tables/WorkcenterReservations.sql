CREATE TABLE WorkcenterReservations (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    ReservationId VARCHAR(36) NOT NULL,
    WorkcenterTypeId VARCHAR(36) NOT NULL,
    WorkcenterName VARCHAR(32) NOT NULL,
    ReservedHours INT NOT NULL,
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL,
    CONSTRAINT FK_WorkcenterReservations FOREIGN KEY (ReservationId) REFERENCES Reservations(Id)
);