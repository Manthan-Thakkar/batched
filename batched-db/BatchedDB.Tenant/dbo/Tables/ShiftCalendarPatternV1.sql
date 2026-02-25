CREATE TABLE [dbo].[ShiftCalendarPatternV1]
(
	[Id]				VARCHAR(36) NOT NULL,
	[ShiftCalendarId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftCalendarPatternV1_ShiftCalendarScheduleV1Id] FOREIGN KEY REFERENCES ShiftCalendarScheduleV1(Id),
	[DayOfWeek]			NVARCHAR(16)  NOT NULL,
	[StartTime]			TIME NOT NULL,
	[EndTime]			TIME NOT NULL,
	[CreatedOn]			DATETIME,
	[ModifiedOn]		DATETIME,
    CONSTRAINT [PK_ShiftCalendarPatternV1Id] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)