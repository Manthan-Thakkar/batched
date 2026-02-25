CREATE TABLE FieldMaster (
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  Name VARCHAR(255) Not NULL,
  JsonFieldName VARCHAR(255) Not NULL,
  ReportId varchar(36) foreign key references  ReportMaster(Id)  NULL ,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  SortField varchar(255)  null,
  Action varchar(255)  null
  )
