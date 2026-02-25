CREATE TABLE [dbo].[EquipmentScheduleAnalysis]
(
	[Id] varchar(36) NOT NULL PRIMARY KEY,
	[EquipmentId] varchar(36) NOT NULL,
	[SourceEquipmentId]	varchar(64),
	[ScheduledTasksToBeCompleted] int,
	[ActualTasksCompleted] int,
	[AnalysisDate] date,
	[CreatedOn] datetime,
	[ModifiedOn] datetime
)
