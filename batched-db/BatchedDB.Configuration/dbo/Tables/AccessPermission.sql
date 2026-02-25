  CREATE TABLE AccessPermission(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  RolePermissionId VARCHAR(36)  Foreign key references RolePermission(ID),
  AccessId VARCHAR(36)  Foreign key references Access(Id),
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  IsEnabled BIT NULL,
  CreatedBy NVARCHAR(4000) NULL,
  ModifiedBy NVARCHAR(4000) NULL);
