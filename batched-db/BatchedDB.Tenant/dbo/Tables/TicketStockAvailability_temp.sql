CREATE TABLE [dbo].[TicketStockAvailability_temp]
	(
		[Id]							VARCHAR(36)		NOT NULL,
		[TicketId]						VARCHAR(36)		NOT NULL,
		[FacilityId]					VARCHAR(36)		NOT NULL,
		[TaskName]						NVARCHAR(255)	NOT NULL DEFAULT '',
		[Sequence]						SMALLINT		NOT NULL DEFAULT 0,						
		[TaskDueDateTime]				DATETIME		NOT NULL,
		[OriginalStockMaterialId]		VARCHAR(36)		NOT NULL,
		[OriginalWidth]					REAL			NOT NULL,
		[OriginalLength]				REAL			NULL,
		[StockStatus]					VARCHAR(36)		NOT NULL,
		[FirstAvailableTime]			DATETIME		NULL,
		[ActualStockMaterialId]			VARCHAR(36)		NULL,
		[ActualWidth]					REAL			NULL,
		[ActualLength]					REAL			NULL,
		[RequiredQuantity]				REAL			NOT NULL,
		[CreatedOnUTC]					DATETIME		NOT NULL,
		[ModifiedOnUTC]					DATETIME		NOT NULL,

		CONSTRAINT [PK_TicketStockAvailability_temp]	PRIMARY KEY NONCLUSTERED ([Id] ASC)
	);