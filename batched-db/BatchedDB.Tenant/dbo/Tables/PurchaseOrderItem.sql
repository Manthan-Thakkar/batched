CREATE TABLE [dbo].[PurchaseOrderItem]
	(
		[Id]						VARCHAR(36)		NOT NULL,
		[FacilityId]				VARCHAR(36)		NOT NULL,
		[PurchaseOrderId]			VARCHAR(36)		NOT NULL,
		[SourcePurchaseOrderItemId]	VARCHAR(36)		NOT NULL,
		[StockMaterialId]			VARCHAR(36)		NOT NULL,
		[Width]						REAL			NOT NULL,
		[Length]					REAL			NULL,
		[PromisedDeliveryDate]		DATETIME		NULL,
		[OrderedQty]				REAL			NOT NULL,
		[ReceivedQty]				REAL			NOT NULL,
		[OpenQty]					REAL			NOT NULL,
		[CutNumber]					NVARCHAR(50)	NULL,
		[NumberOfCuts]				REAL			NULL,
		[ExactWidths]				BIT				NOT NULL DEFAULT 0,
		[CreatedOnUTC]				DATETIME		NOT NULL,
		[ModifiedOnUTC]				DATETIME		NOT NULL,

		CONSTRAINT [PK_PurchaseOrderItem]						PRIMARY KEY NONCLUSTERED ([Id] ASC),
		CONSTRAINT [FK_PurchaseOrderMaster_PurchaseOrderId]		FOREIGN KEY ([PurchaseOrderId])		REFERENCES [dbo].[PurchaseOrderMaster]([Id]),
		CONSTRAINT [FK_StockMaterial_StockMaterialId]			FOREIGN KEY ([StockMaterialId])		REFERENCES [dbo].[StockMaterial]([Id])
	);