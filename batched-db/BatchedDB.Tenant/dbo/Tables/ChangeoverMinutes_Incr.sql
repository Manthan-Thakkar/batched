
CREATE TABLE [dbo].[ChangeoverMinutes_Incr](
	[ID] [varchar](36) NOT NULL,
	[TicketIdFrom] [varchar](36) NOT NULL,
	[TicketIdTo] [varchar](36) NOT NULL,
	[EquipmentId] [varchar](36) NOT NULL,
	[ChangeoverMinutes] [float] NULL,
	[SavedChangeoverMinutes] [float] NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedOn] [datetime] NULL,
	[Count] int ,
	Description varchar(4000),
	CONSTRAINT [PK_ChangeoverMinutes_Incr] PRIMARY KEY NONCLUSTERED([ID] ASC)
)
