CREATE NONCLUSTERED INDEX [IX_TicketTool_TicketId_Sequence_Description]
    ON [dbo].[TicketTool]
    (TicketId)
    INCLUDE(Sequence, Description)