CREATE TABLE [dbo].[ShiftCalendarDatesV1]
(
	[Id]				VARCHAR(36) NOT NULL,
	[ShiftCalendarId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftCalendarDatesV1_ShiftCalendarScheduleV1Id] FOREIGN KEY REFERENCES ShiftCalendarScheduleV1(Id),
	[StartDate]			DATETIME NOT NULL,
	[EndDate]			DATETIME NOT NULL,
	[CreatedOn]			DATETIME,
	[ModifiedOn]		DATETIME,
    CONSTRAINT [PK_ShiftCalendarDatesV1Id] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)