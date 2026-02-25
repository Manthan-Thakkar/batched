CREATE NONCLUSTERED INDEX [IX_TicketStockAvailability_TicketId_FacilityId_StockId_Width_Length]
	ON [dbo].[TicketStockAvailability]
	(Ticketid) 
	INCLUDE ([FacilityId], [ActualStockMaterialId], [ActualWidth],[ActualLength])