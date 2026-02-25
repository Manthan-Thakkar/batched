CREATE NONCLUSTERED INDEX [IX_TicketAttributeValues_TicketId_Name] ON [dbo].[TicketAttributeValues]
(
	[TicketId] ASC,
	[Name] ASC
)
INCLUDE([Value],[DataType],[CreatedOn],[ModifiedOn])