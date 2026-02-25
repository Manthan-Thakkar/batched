CREATE TABLE TicketTaskOverride(
  ID				VARCHAR(36)  PRIMARY KEY NOT NULL,
  TicketId			VARCHAR(36) NOT NULL CONSTRAINT [FK_TicketTaskOverride_TicketId] FOREIGN KEY REFERENCES TicketMaster(Id),
  TaskName			NVARCHAR(255) NOT NULL,
  EstimatedMinutes	REAL NULL,
  IsCompleted		BIT NULL,
  CreatedOnUTC		DATETIME,
  ModifiedOnUTC		DATETIME,
  );