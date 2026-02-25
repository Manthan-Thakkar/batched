CREATE TABLE ReportViewField(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  ReportViewId varchar(36) foreign key references  ReportView(Id),
  FieldName VARCHAR(255) Not NULL,
  DisplayName VARCHAR(255) NULL,
  JsonName VARCHAR(255) Not NULL,
  Type VARCHAR(255) not null,
  Category VARCHAR(255) not null,
  IsDefault bit Not NULL,
  Sequence int not null,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  SortField varchar(255)  null,
  Action varchar(255)  null
  )