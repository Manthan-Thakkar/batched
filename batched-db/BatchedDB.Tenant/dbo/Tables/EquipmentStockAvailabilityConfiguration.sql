CREATE TABLE [dbo].[EquipmentStockAvailabilityConfiguration]
(
	Id										VARCHAR(36) NOT NULL PRIMARY KEY,
	WorkcenterStockAvailabilityConfigId		VARCHAR(36) NOT NULL,
	EquipmentId								VARCHAR(36) NOT NULL,
	WasteToleranceLimit						REAL NULL,
	WidthWasteLimit							REAL NULL,
	LengthWasteLimit						REAL NULL,
	MaxAllowedWidth							REAL NULL,
	MaxAllowedLength						REAL NULL,
	WasteThresholdUnit						VARCHAR(255) NULL,
	IsFirstAvailableTimeEnforced			BIT NOT NULL DEFAULT 0,
	CreatedOnUtc							DATETIME NOT NULL,
	ModifiedOnUtc							DATETIME NOT NULL,
	CONSTRAINT [FK_EquipStockAvailabilityConfig_WorkcenterStockAvailabilityConfigId] FOREIGN KEY (WorkcenterStockAvailabilityConfigId) REFERENCES WorkcenterStockAvailabilityConfiguration(Id)
)
