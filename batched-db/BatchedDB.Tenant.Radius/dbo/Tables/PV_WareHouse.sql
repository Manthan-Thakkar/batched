CREATE TABLE [dbo].[PV_Warehouse]
(
	[WhouseName] nvarchar(4000) NULL,
	[WhouseCode] nvarchar(4000) NULL,
	[PlantCode] nvarchar(4000) NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[CompNum] int NULL,
	[AddressNum] int NULL,
	[ExternalWH] int NULL,
	[ExternalWHReasonCode] nvarchar(4000) NULL,
	[LastUpdatedDateTime] nvarchar(4000) NULL
)