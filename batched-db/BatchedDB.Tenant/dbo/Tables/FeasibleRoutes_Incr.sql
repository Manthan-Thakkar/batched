CREATE TABLE [dbo].[FeasibleRoutes_Incr]
(
	[ID] [varchar](36) NOT NULL,
	[TicketId] [varchar](36) NOT NULL,
	[TaskId] [varchar](36) NOT NULL,
	[EquipmentId] [varchar](36) NOT NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedOn] [datetime] NULL,
	[RouteFeasible] [bit] NULL,
	[ConstraintDescription] [nvarchar](max) NULL,
	[EstHoursBySpeed] [REAL] NULL,
	CONSTRAINT [PK_FeasibleRoutes_Incr] PRIMARY KEY NONCLUSTERED([ID] ASC)
)