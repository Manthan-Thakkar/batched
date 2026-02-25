  CREATE TABLE [dbo].[TicketItemColorInfo](
	[Id] [varchar](36) PRIMARY KEY NOT NULL,
	[TicketItemInfoId] [varchar](36) FOREIGN KEY REFERENCES TicketItemInfo(Id),
	[CoatingType] [nvarchar](100) NULL,
	[SourceInkType] [nvarchar](100) NULL,
	[SourceInk] [nvarchar](100) NULL,
	[CoatSide] [int] NOT NULL,
	[CreatedOnUTC] [datetime] NULL,
	[ModifiedOnUTC] [datetime] NULL,
  )