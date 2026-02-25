CREATE TABLE [dbo].[OpenTicketColorsV2](
	[TicketId] varchar(36) Foreign key references TicketMaster (Id),
	[Color] [nvarchar](4000) NULL
) 


