CREATE TABLE LagDelayConfig(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  FromId VARCHAR(36) Not Null,
  ToId VARCHAR(36) Not Null,
  [Type] NVARCHAR(50) NOT NULL,
  [Lag] real ,
  [Delay] real,
  CreatedOn DATETIME,
  ModifiedOn DATETIME);