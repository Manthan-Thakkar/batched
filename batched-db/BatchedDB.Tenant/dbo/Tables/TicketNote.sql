CREATE TABLE TicketNote(
  ID VARCHAR(36) PRIMARY KEY NOT NULL,
  TicketId VARCHAR(36)  FOREIGN KEY REFERENCES TicketMaster(Id),
  SourceTicketNoteId VARCHAR(255),
  SourceTicketId NVARCHAR(255),
  EquipmentId VARCHAR(36)  FOREIGN KEY REFERENCES EquipmentMaster(Id),
  SourceEquipmentId nvarchar(255) NOT NULL,
  Description nvarchar(4000) NULL,
  Notes nvarchar(4000) NULL,
  IsEnabled bit NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  )