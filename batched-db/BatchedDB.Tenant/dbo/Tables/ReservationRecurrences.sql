CREATE TABLE ReservationRecurrences (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    RecurrenceType VARCHAR(36) NOT NULL,
    Frequency INT NOT NULL,
    IsRecurringMonthlyOnWeekDay BIT NOT NULL,
    RecurrenceWeekDays VARCHAR(50),
    RecurrenceDay INT,
    RecurrenceDayOfWeekIndex VARCHAR(10),
    RecurrenceMonth VARCHAR(5),
    EndDate DATETIME,
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL
);