CREATE TABLE [dbo].[item-coating]
(
	[item-code] nvarchar(4000) NULL,
	[ReversePrint] bit NULL,
	[kco] int NULL,
	[coat-seq] int NULL,
	[type] nvarchar(4000) NULL,
	[coat-coverage] decimal(18, 0) NULL,
	[coat-mat-desc] nvarchar(4000) NULL,
	[coat-side] int NULL,
	[TableRecid] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[coat-mat-code] nvarchar(4000) NULL,
	[PartNum] int NULL,
	[SameAsPartNum] int NULL
)