  CREATE TABLE ReportView(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  ReportId varchar(36) foreign key references  ReportMaster(Id),
  Name VARCHAR(255) Not NULL,
  IsEnabled bit Not NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  IsDefault bit null
  )
