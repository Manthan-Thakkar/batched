CREATE TABLE [dbo].[PM_Notes]
(
	[TableRecId] bigint NULL,
	[NotesTable] nvarchar(4000) NULL,
	[NotesLine] int NULL,
	[NotesEntry] nvarchar(4000) NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[CreatedDate] datetime NULL,
	[CreatedTimeSecs] int NULL,
	[CreatedTime] nvarchar(4000) NULL,
	[NotesDate] datetime NULL,
	[NotesSeconds] int NULL,
	[NotesDisplayTime] nvarchar(4000) NULL
) 