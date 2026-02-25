 CREATE TABLE ScheduleEvent(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  TenantId VARCHAR(36)   FOREIGN KEY REFERENCES Tenant(Id) NOT NULL,
  EventName nvarchar(255),
  Description nvarchar(255),
  TimeSpan time,
  UTCTimeSpan time, 
  UTCDSTTimeSpan time, 
  IsDisabled bit not null,
  CreatedOn DATETIME,
  ModifiedOn DATETIME);