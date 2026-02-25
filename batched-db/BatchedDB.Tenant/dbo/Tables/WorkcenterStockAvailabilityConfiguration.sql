CREATE TABLE [dbo].[WorkcenterStockAvailabilityConfiguration]
(
	Id								VARCHAR(36) NOT NULL PRIMARY KEY,
	StockAvailabilityConfigId		VARCHAR(36) NOT NULL,
	WorkcenterTypeId				VARCHAR(36) NOT NULL,
	WasteToleranceLimit				REAL NULL,
	WidthWasteLimit					REAL NULL,
	LengthWasteLimit				REAL NULL,
	MaxAllowedWidth					REAL NULL,
	MaxAllowedLength				REAL NULL,
	WasteThresholdUnit				VARCHAR(255) NULL,
	IsFirstAvailableTimeEnforced	BIT NOT NULL DEFAULT 0,
	CreatedOnUtc					DATETIME NOT NULL,
	ModifiedOnUtc					DATETIME NOT NULL,
	CONSTRAINT [FK_WorkcenterStockAvailabilityConfig_StockAvailabilityConfigId] FOREIGN KEY (StockAvailabilityConfigId) REFERENCES StockAvailabilityConfiguration(Id)
)
