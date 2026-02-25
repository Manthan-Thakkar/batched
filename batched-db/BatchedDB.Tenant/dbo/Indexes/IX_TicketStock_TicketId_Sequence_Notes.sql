CREATE NONCLUSTERED INDEX [IX_TicketStock_TicketId_Sequence_Notes]
    ON [dbo].[TicketStock]
    (TicketId)
    INCLUDE(Sequence, Notes)