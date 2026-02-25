 CREATE TABLE ReportMaster(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  Name VARCHAR(128) Not NULL,
  Description VARCHAR(255) Not NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  DisplayName VARCHAR(128) Not NULL
  )