CREATE TYPE [dbo].[udt_TaskAttributes] AS TABLE(
	[TicketId] [varchar](36) NOT NULL,
	[Name] [nvarchar](64) NOT NULL,
	[Value] [nvarchar](max) NULL,
	[DataType] [nvarchar](64) NULL
)