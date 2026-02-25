CREATE TABLE Reservations (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    Name VARCHAR(50) NOT NULL,
    FacilityId VARCHAR(36),
    ReservedHours INT NOT NULL,
    StartDate DATETIME NOT NULL,
    IsRecurring BIT NOT NULL,
    ReservationRecurrenceId VARCHAR(36),
    ExpirationDays INT NOT NULL,
    CreatedBy VARCHAR(20) NOT NULL,
    ModifiedBy VARCHAR(20) NOT NULL,
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL,
    CONSTRAINT FK_Facility FOREIGN KEY (FacilityId) REFERENCES Facility(Id),
    CONSTRAINT FK_ReservationRecurranceDetails FOREIGN KEY (ReservationRecurrenceId) REFERENCES ReservationRecurrences(Id)
);	