CREATE TABLE [dbo].[PV_WorkcConfig]
(
	[CompNum] int NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[WorkcCode] nvarchar(4000) NULL,
	[ConfigNum] int NULL,
	[ConfigName] nvarchar(4000) NULL,
	[RunUnits] int NULL,
	[MaxPrintUnits] int NULL,
	[MaxCols1] int NULL,
	[MaxCols2] int NULL,
	[MaxWebs] int NULL,
	[UV] bit NULL,
	[PlateChangeTime] int NULL,
	[MROperationCode] nvarchar(4000) NULL,
	[RunOperationCode] nvarchar(4000) NULL
)