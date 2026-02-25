CREATE TABLE [dbo].[ShiftCalendarSchedule]
(
	[Id]			VARCHAR(36) NOT NULL,
	[EquipmentId]   VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftCalendarSchedule_EquipmentMasterId] FOREIGN KEY REFERENCES EquipmentMaster(Id),
	[CreatedOn]		DATETIME,
	[ModifiedOn]	DATETIME,
    [CalendarName] VARCHAR(255) NULL, 
    CONSTRAINT [PK_ShiftCalendarScheduleId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
