CREATE TABLE [dbo].[EquipmentCalendarScheduleV1]
(
	[Id]			VARCHAR(36) NOT NULL,
	[EquipmentId]   VARCHAR(36) NOT NULL CONSTRAINT [FK_EquipmentCalendarScheduleV1_EquipmentMasterId] FOREIGN KEY REFERENCES EquipmentMaster(Id),
	[ShiftCalendarId] VARCHAR(36) NOT NULL CONSTRAINT [FK_EquipmentCalendarScheduleV1_ShiftCalendarScheduleV1Id] FOREIGN KEY REFERENCES ShiftCalendarScheduleV1(Id),
	[CreatedOn]		DATETIME,
	[ModifiedOn]	DATETIME, 
    CONSTRAINT [PK_EquipmentCalendarScheduleV1Id] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)