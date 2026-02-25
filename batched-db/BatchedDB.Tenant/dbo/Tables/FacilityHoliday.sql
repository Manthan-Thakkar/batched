CREATE TABLE [dbo].[FacilityHoliday]
(
	[Id]			VARCHAR(36) NOT NULL,
	[HolidayId]		VARCHAR(36) NOT NULL CONSTRAINT [FK_FacilityHoliday_HolidayScheduleId] FOREIGN KEY REFERENCES HolidaySchedule(Id),
	[FacilityId]	VARCHAR(36) NOT NULL,
	[CreatedOn]		DATETIME,
	[ModifiedOn]	DATETIME,
    CONSTRAINT [PK_FacilityHolidayId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)