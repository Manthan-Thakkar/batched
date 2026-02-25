CREATE NONCLUSTERED INDEX [IX_TicketMaster_OrderDate_SourceTicketId]
    ON [dbo].[TicketMaster]
    ([OrderDate])
    INCLUDE([SourceTicketId])