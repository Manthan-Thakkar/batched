CREATE NONCLUSTERED INDEX [IX_TicketShipping_TicketId_ShipByDateTime_ShippedOnDate] ON [dbo].[TicketShipping]
(
	[TicketId]
) 
INCLUDE ([ShipByDateTime], [ShippedOnDate]) 