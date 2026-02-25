 CREATE NONCLUSTERED INDEX IX_TicketUserDefinedOptions_Ticket_SourceEquipUDID
    ON dbo.TicketUserDefinedOptions (TicketId, SourceEquipUDID);