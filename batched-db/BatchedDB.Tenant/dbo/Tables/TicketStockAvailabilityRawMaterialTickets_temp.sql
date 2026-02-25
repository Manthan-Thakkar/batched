CREATE TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets_temp]
	(
		[Id]							VARCHAR(36)		NOT NULL,
		[TicketItemInfoId]				VARCHAR(36)		NOT NULL,
		[TicketStockAvailabilityId]		VARCHAR(36)		NOT NULL,
		[QuantityUsed]					REAL			NOT NULL,
		[CreatedOnUTC]					DATETIME		NOT NULL,
		[ModifiedOnUTC]					DATETIME		NOT NULL,

		CONSTRAINT [PK_TicketStockAvailabilityRawMaterialTickets_temp]		PRIMARY KEY NONCLUSTERED ([Id] ASC),
	);