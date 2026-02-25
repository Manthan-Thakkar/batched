 CREATE TABLE FacilityValueStreamScheduleEvent(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  ScheduleTimeSpanId VARCHAR(36) NOT NULL,
  FacilityId VARCHAR(36) NOT NULL,
  ValueStreamId VARCHAR(36),
  UTCTimeSpan TIME, 
  UTCDSTTimeSpan TIME, 
  CreatedOnUTC DATETIME,
  ModifiedOnUTC DATETIME,
  IsEnabled BIT DEFAULT 0 NOT NULL,
  CreatedBy VARCHAR(100),
  ModifiedBy VARCHAR(100),
  CONSTRAINT [FK_TimeSpanId] FOREIGN KEY ([ScheduleTimeSpanId]) REFERENCES [dbo].[ScheduleTimeSpan] ([ID]),
  CONSTRAINT [FK_FacilityId] FOREIGN KEY ([FacilityId]) REFERENCES [dbo].[Facility] ([ID])
 );
