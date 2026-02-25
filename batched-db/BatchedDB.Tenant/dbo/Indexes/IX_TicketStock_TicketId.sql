CREATE NONCLUSTERED INDEX [IX_TicketStock_TicketId] ON [dbo].[TicketStock]
(
	[TicketId] ASC
)
INCLUDE([Id], [StockMaterialId], [Sequence], [Width], [RequiredQuantity])