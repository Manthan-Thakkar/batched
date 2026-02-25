  CREATE TABLE TaskRules(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  TaskInfoId VARCHAR(36) FOREIGN KEY REFERENCES TaskInfo(Id), 
  RuleName VARCHAR(255),
  RuleText nvarchar(2048),
  CreatedOn DATETIME,
  ModifiedOn DATETIME);