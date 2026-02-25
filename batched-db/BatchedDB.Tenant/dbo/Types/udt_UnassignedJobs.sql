CREATE TYPE [dbo].[udt_UnassignedJobs] AS TABLE(
	[TicketId] [varchar](36) NULL,
	[DueDateBucket] [varchar](36) NULL
)