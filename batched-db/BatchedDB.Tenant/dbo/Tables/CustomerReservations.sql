CREATE TABLE CustomerReservations (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    ReservationId VARCHAR(36) NOT NULL,
    CustomerId VARCHAR(36) NOT NULL,
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL,
    CONSTRAINT FK_CustomerReservations FOREIGN KEY (ReservationId) REFERENCES Reservations(Id),
    CONSTRAINT FK_CustomerMaster FOREIGN KEY (CustomerId) REFERENCES CustomerMaster(Id)
);