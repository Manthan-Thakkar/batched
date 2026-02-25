CREATE TABLE TicketAttributeValues(
  ID VARCHAR(36)  PRIMARY KEY NOT NULL,
  TicketId varchar(36) NOT NULL,
  Name NVARCHAR(64) NOT NULL,
  Value NVARCHAR(max) NULL,
  DataType NVARCHAR(100) NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME
  );