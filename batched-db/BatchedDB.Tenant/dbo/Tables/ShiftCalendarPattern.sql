CREATE TABLE [dbo].[ShiftCalendarPattern]
(
	[Id]				VARCHAR(36) NOT NULL,
	[ShiftCalendarId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftCalendarPattern_ShiftCalendarScheduleId] FOREIGN KEY REFERENCES ShiftCalendarSchedule(Id),
	[DayOfWeek]			NVARCHAR(16)  NOT NULL,
	[StartTime]			TIME NOT NULL,
	[EndTime]			TIME NOT NULL,
	[CreatedOn]			DATETIME,
	[ModifiedOn]		DATETIME,
    CONSTRAINT [PK_ShiftCalendarPatternId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
