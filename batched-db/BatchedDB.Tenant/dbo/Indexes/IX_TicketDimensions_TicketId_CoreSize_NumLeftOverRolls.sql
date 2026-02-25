CREATE NONCLUSTERED INDEX [IX_TicketDimensions_TicketId_CoreSize_NumLeftOverRolls] 
	ON [dbo].TicketDimensions
	(TicketId) 
	INCLUDE (CoreSize, CalcNumLeftoverRolls)