CREATE TABLE EquipmentScheduleMapping(
Id VARCHAR(36) PRIMARY KEY,
ShiftCalendarScheduleId VARCHAR(36) FOREIGN KEY REFERENCES ShiftCalendarScheduleV2(ID) NOT NULL,
EquipmentId VARCHAR(36) FOREIGN KEY REFERENCES EquipmentMaster(ID) NOT NULL,
CreatedOnUTC datetime,
ModifiedOnUTC datetime
)
