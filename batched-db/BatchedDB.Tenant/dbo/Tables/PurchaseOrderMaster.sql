CREATE TABLE [dbo].[PurchaseOrderMaster]
(
	[Id] varchar(36) NOT NULL PRIMARY KEY,
	[SourcePurchaseOrderNo] nvarchar(512) NOT NULL,
	[SourceTicketId] nvarchar(4000),
	[Description] nvarchar(4000),
	[PurchaseOrderDate] datetime,
	[PromisedDeliveryDate] datetime,
	[StockMaterialId] nvarchar(36),
	[PurchaseOrderType] nvarchar(4000),
	[IsOpen] bit,
	[RequestedDeliveryDate] datetime,
	[Notes] nvarchar(4000),
	[CreatedOn] datetime NOT NULL,
	[ModifiedOn] datetime NOT NULL,
	[ToolingId] nvarchar(36),
	[Supplier] nvarchar(4000),
	[TotalCost] DECIMAL(18,4) NULL,
	[CostMSI] DECIMAL(18,4) NULL,
	[MasterWidth] REAL NULL
)
