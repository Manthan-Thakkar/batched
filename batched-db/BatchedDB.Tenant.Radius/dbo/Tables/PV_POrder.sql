CREATE TABLE [dbo].[PV_POrder]
(
	[POrderNum] int NULL,
	[POrderDate] datetime NULL,
	[Suppcode] nvarchar(4000) NULL,
	[OurContact] nvarchar(4000) NULL,
	[YourContact] nvarchar(4000) NULL,
	[SuppRef] nvarchar(4000) NULL,
	[POrderText] nvarchar(4000) NULL,
	[POrderStat] int NULL,
	[TableRecId] bigint NULL,
	[LastUserCode] nvarchar(4000) NULL,
	[CompNum] int NULL,
	[POAddrNum] int NULL,
	[TermsCode] nvarchar(4000) NULL,
	[CurrCode] nvarchar(4000) NULL,
	[SuppContactCode] nvarchar(4000) NULL,
	[ReqDate] datetime NULL,
	[LastUpdatedDateTime] nvarchar(4000) NULL
)