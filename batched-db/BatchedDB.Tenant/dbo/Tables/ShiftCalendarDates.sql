CREATE TABLE [dbo].[ShiftCalendarDates]
(
	[Id]				VARCHAR(36) NOT NULL,
	[ShiftCalendarId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftCalendarDates_ShiftCalendarScheduleId] FOREIGN KEY REFERENCES ShiftCalendarSchedule(Id),
	[StartDate]			DATETIME NOT NULL,
	[EndDate]			DATETIME NOT NULL,
	[CreatedOn]			DATETIME,
	[ModifiedOn]		DATETIME,
    CONSTRAINT [PK_ShiftCalendarDatesId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)