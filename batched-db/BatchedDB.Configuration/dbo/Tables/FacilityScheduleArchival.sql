CREATE TABLE FacilityScheduleArchival(
	  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
	  FacilityId VARCHAR(36) NOT NULL,
	  ArchivalDays INT,
	  ArchivalTime TIME, 
	  ArchivalTimeUTC TIME, 
	  ArchivalTimeUTCDST TIME, 
	  IsEnabled BIT,
	  CreatedOnUTC DATETIME,
	  ModifiedOnUTC DATETIME,
	  CreatedBy VARCHAR(100),
	  ModifiedBy VARCHAR(100),
	  CONSTRAINT [FK_ScheduleFacilityId] FOREIGN KEY ([FacilityId]) REFERENCES [dbo].[Facility] ([ID])
 );