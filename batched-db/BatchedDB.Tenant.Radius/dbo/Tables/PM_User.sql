CREATE TABLE [dbo].[PM_User]
(
	[UserName] nvarchar(4000) NULL,
	[Password] nvarchar(4000) NULL,
	[PlantCode] nvarchar(4000) NULL,
	[UserCode] nvarchar(4000) NULL,
	[MainLanguage] nvarchar(4000) NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[CompNum] int NULL,
	[JobDescription] nvarchar(4000) NULL,
	[OfficePhone] nvarchar(4000) NULL,
	[HomePhone] nvarchar(4000) NULL,
	[Pager] nvarchar(4000) NULL,
	[CellPhone] nvarchar(4000) NULL,
	[Email] nvarchar(4000) NULL,
	[UserGroup] nvarchar(4000) NULL,
	[LastUpdatedDateTime] nvarchar(4000) NULL,
	[LastActivityUTC] nvarchar(4000) NULL,
	[UserLongName] nvarchar(4000) NULL
)