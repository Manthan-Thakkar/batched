CREATE TABLE [dbo].[TicketStockAvailabilityPO]
	(
		[Id]							VARCHAR(36)		NOT NULL,
		[PurchaseOrderItemId]			VARCHAR(36)		NOT NULL,
		[TicketStockAvailabilityId]		VARCHAR(36)		NOT NULL,
		[QuantityUsed]					REAL			NOT NULL,
		[CreatedOnUTC]					DATETIME		NOT NULL,
		[ModifiedOnUTC]					DATETIME		NOT NULL,

		CONSTRAINT [PK_TicketStockAvailabilityPO]							PRIMARY KEY NONCLUSTERED ([Id] ASC),
		CONSTRAINT [FK_PurchaseOrderItem_PurchaseOrderItemId]				FOREIGN KEY ([PurchaseOrderItemId])			REFERENCES [dbo].[PurchaseOrderItem]([Id]),
		CONSTRAINT [FK_TicketStockAvailability_TicketStockAvailabilityId]	FOREIGN KEY ([TicketStockAvailabilityId])	REFERENCES [dbo].[TicketStockAvailability]([Id])
	);