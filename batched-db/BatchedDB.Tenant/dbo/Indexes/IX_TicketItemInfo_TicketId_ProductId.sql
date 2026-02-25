CREATE NONCLUSTERED INDEX [IX_TicketItemInfo_TicketId_ProductId]
    ON [dbo].[TicketItemInfo]
    (TicketId)
    INCLUDE(ProductId)