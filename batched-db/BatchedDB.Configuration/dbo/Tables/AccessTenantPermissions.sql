  CREATE TABLE AccessTenantPermissions(
  Id VARCHAR(36)  PRIMARY KEY NOT NULL,
  RolePermissionId VARCHAR(36)  Foreign key references RolePermission(ID),
  AccessId VARCHAR(36)  Foreign key references Access(Id),
  TenantId VARCHAR(36) NOT NULL,
  IsEnabled bit NOT NULL,
  CreatedOn DATETIME,
  ModifiedOn DATETIME,
  CreatedBy NVARCHAR(4000) NULL,
  ModifiedBy NVARCHAR(4000) NULL);