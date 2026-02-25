CREATE TABLE [dbo].[RestrictedClients](
  [Id]			VARCHAR(36)  PRIMARY KEY NOT NULL,
  [RoleId]		VARCHAR(36)  Foreign key references Role(Id),
  [ClientId]	VARCHAR(36)  Foreign key references Client(ID),
  [CreatedOn]	DATETIME,
  [ModifiedOn]	DATETIME);