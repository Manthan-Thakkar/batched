CREATE TABLE DowntimeRecurrences (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    DowntimeGroupId VARCHAR(36) NOT NULL,
    RecurrenceType VARCHAR(36) NOT NULL,
    Frequency INT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    StartsOn TIME(0) NOT NULL,
    EndsAt TIME(0) NOT NULL,
    IsRecurringMonthlyOnWeekDay BIT NOT NULL,
    RecurrenceWeekDays VARCHAR(50),
    RecurrenceDay INT,
    RecurrenceDayOfWeekIndex VARCHAR(10),
    RecurrenceMonth VARCHAR(5),
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL
);