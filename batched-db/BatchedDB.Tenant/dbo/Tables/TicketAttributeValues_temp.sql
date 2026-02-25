CREATE TABLE [dbo].[TicketAttributeValues_temp](
	[ID] [varchar](36) NOT NULL,
	[TicketId] [varchar](36) NOT NULL,
	[Name] [nvarchar](64) NOT NULL,
	[Value] [nvarchar](max) NULL,
	[DataType] [nvarchar](100) NOT NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedOn] [datetime] NULL,
	CONSTRAINT [PK_TicketAttributeValues_temp] PRIMARY KEY NONCLUSTERED([ID] ASC)
)
