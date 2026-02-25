CREATE TABLE [dbo].[PV_JobComponent]
(
	[CompNum] int NULL,
	[PlantCode] nvarchar(4000) NULL,
	[JobCode] nvarchar(4000) NULL,
	[TableRecId] bigint NULL,
	[JobCmpNum] int NULL,
	[JobCmpLevel] int NULL,
	[CmpType] int NULL,
	[EstCmpNum] int NULL,
	[JobCompDesc] nvarchar(4000) NULL,
	[NumberUp] int NULL,
	[PrintRepeat] decimal(18, 0) NULL,
	[NumPrintChanges] int NULL,
	[PrintGearCode] nvarchar(4000) NULL,
	[PrintGearTeeth] int NULL,
	[DieRepeat] decimal(18, 0) NULL,
	[DieGearCode] nvarchar(4000) NULL,
	[DieGearTeeth] int NULL,
	[CmpSize1] decimal(18, 0) NULL,
	[CmpSize2] decimal(18, 0) NULL
) 