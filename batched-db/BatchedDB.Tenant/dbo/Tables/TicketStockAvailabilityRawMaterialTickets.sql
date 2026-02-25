CREATE TABLE [dbo].[TicketStockAvailabilityRawMaterialTickets]
	(
		[Id]							VARCHAR(36)		NOT NULL,
		[TicketItemInfoId]				VARCHAR(36)		NOT NULL,
		[TicketStockAvailabilityId]		VARCHAR(36)		NOT NULL,
		[QuantityUsed]					REAL			NOT NULL,
		[CreatedOnUTC]					DATETIME		NOT NULL,
		[ModifiedOnUTC]					DATETIME		NOT NULL,

		CONSTRAINT [PK_TicketStockAvailabilityRawMaterialTickets]		PRIMARY KEY NONCLUSTERED ([Id] ASC),
		CONSTRAINT [FK_TSA_TicketItemInfo_Id]							FOREIGN KEY ([TicketItemInfoId])			REFERENCES [dbo].TicketItemInfo([Id]),
		CONSTRAINT [FK_TSA_TicketStockAvailabilityId]					FOREIGN KEY ([TicketStockAvailabilityId])	REFERENCES [dbo].[TicketStockAvailability]([Id])
	);