CREATE TABLE EquipmentCalendar
(
	EquipmentId			VARCHAR(36)			NOT NULL,
	SourceEquipmentId	NVARCHAR(4000)		NOT NULL,
	TheDateTime			DATETIME			NOT NULL, 
	TimeIndex			BIGINT				NOT NULL,
	AdjustedTimeIndex	BIGINT				NULL,
	Available			BIT					NOT NULL,
	DowntimeReason		VARCHAR(100)		NULL
) 
