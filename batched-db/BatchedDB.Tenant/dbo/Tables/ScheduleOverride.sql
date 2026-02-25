 CREATE TABLE ScheduleOverride(
  ID VARCHAR(36)  PRIMARY KEY NOT NULL,
  TicketId varchar(36) NOT NULL,
  Number nvarchar(255) NOT NULL,
  TaskName nvarchar(255) NOT NULL,
  EquipmentId varchar(36)  NULL,
  EquipmentName varchar(255)  NULL,
  StartsAt datetime  NULL,
  EndsAt datetime  NULL,
  WorkcenterId varchar(36)  NULL,
  IsScheduled bit NOT NULL,
  Notes  nvarchar(4000) NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  EstimatedMinutes real NULL,
  IsCompleted bit NULL
  );