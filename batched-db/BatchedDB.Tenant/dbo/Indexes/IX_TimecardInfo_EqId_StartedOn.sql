CREATE NONCLUSTERED INDEX [IX_TimecardInfo_EqId_StartedOn]
ON
	[dbo].[TimecardInfo]
	([EquipmentId], [StartedOn])
	INCLUDE ([SourceTicketId])