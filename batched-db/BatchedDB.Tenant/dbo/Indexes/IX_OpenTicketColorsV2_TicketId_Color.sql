CREATE NONCLUSTERED INDEX [IX_OpenTicketColorsV2_TicketId_Color] 
	ON [dbo].OpenTicketColorsV2
	(TicketId) 
	INCLUDE (Color)