CREATE TABLE TaskInfo(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  Name VARCHAR(100) , 
  Description VARCHAR(255),
  IsEnabled bit not null,
  CreatedOn DATETIME,
  ModifiedOn DATETIME);