CREATE TABLE [dbo].[TicketGeneralNotes](
	[ID]			VARCHAR(36)		PRIMARY KEY NOT NULL,
	[TicketId]		VARCHAR(36)		CONSTRAINT [FK_TicketGeneralNotes_TicketId] FOREIGN KEY REFERENCES TicketMaster(Id),
	[Notes]			NVARCHAR(4000)	NOT NULL,
	[CreatedOnUTC]	DATETIME,
	[ModifiedOnUTC]	DATETIME,
	[CreatedBy]		NVARCHAR(100)
 )