CREATE TYPE [dbo].[udt_TaskStockStatus] AS TABLE(
	TicketId			varchar(36)		NOT NULL,
	TaskName			nvarchar(255)	NOT NULL,
	TaskStockStatus 	varchar(36)		NULL,
	IsProductionReady	bit				NOT NULL
)