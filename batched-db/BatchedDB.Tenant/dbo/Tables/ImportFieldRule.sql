CREATE TABLE ImportFieldRule(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  Name NVARCHAR(100) NOT NULL,
  RuleText VARCHAR(2048) NOT NULL,
  DataType NVARCHAR(20) NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  IsEnabled bit  not null
  );