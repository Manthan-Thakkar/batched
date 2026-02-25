CREATE TABLE [dbo].[ScheduleAnalysis]
(
	[Id] varchar(36) NOT NULL PRIMARY KEY,
	[FacilityId] varchar(36),
	[ScheduledTicketsToBeCompleted] int,
	[ActualTicketsCompleted] int,
	[ScheduledMinutesToBeCompleted] int,
	[ActualMinutesCompleted] int,
	[ScheduledTicketsToBeShipped] int,
	[ActualTicketsShippedOnTime] int,
	[AnalysisDate] date,
	[CreatedOn] datetime,
	[ModifiedOn] datetime
)
