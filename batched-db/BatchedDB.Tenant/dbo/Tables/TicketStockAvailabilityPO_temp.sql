CREATE TABLE [dbo].[TicketStockAvailabilityPO_temp]
	(
		[Id]							VARCHAR(36)		NOT NULL,
		[PurchaseOrderItemId]			VARCHAR(36)		NOT NULL,
		[TicketStockAvailabilityId]		VARCHAR(36)		NOT NULL,
		[QuantityUsed]					REAL			NOT NULL,
		[CreatedOnUTC]					DATETIME		NOT NULL,
		[ModifiedOnUTC]					DATETIME		NOT NULL,

		CONSTRAINT [PK_TicketStockAvailabilityPO_temp]	PRIMARY KEY NONCLUSTERED ([Id] ASC)
	);