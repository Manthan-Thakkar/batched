CREATE TABLE ScheduleCalendarOverflowLogs(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  SourceTicket VARCHAR(36) NOT NULL,
  TaskName VARCHAR(255) NOT NULL,
  SourceEquipment VARCHAR(36) NOT NULL,
  RunId VARCHAR(500),
  CreatedOn DATETIME
)
