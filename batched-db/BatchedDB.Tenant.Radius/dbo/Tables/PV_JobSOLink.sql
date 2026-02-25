CREATE TABLE [dbo].[PV_JobSOLink]
(
	[CompNum] int NULL,
	[PlantCode] nvarchar(4000) NULL,
	[JobCode] nvarchar(4000) NULL,
	[SOPlantCode] nvarchar(4000) NULL,
	[SOrderNum] int NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[JobLineNum] int NULL,
	[SOrderLineNum] int NULL
)