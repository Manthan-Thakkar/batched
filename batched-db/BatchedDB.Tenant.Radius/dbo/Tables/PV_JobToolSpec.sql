CREATE TABLE [dbo].[PV_JobToolSpec]
(
	[CompNum] int NULL,
	[PlantCode] nvarchar(4000) NULL,
	[JobCode] nvarchar(4000) NULL,
	[JobCmpNum] int NULL,
	[SpecCode] nvarchar(4000) NULL,
	[SpecName] nvarchar(4000) NULL,
	[ToolTypeCode] nvarchar(4000) NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[SeqNum] int NULL
) 