CREATE TABLE [dbo].[TicketStockOverride]
(
    [Id]                			VARCHAR(36) PRIMARY KEY		NOT NULL,
	[TicketId]						VARCHAR(36)					NOT NULL CONSTRAINT [FK_TicketStockOverride_TicketMasterId] FOREIGN KEY REFERENCES TicketMaster(Id),
	[TaskName]						VARCHAR(36)					NOT NULL,
    [Sequence]                      SMALLINT                    NOT NULL,
    [OverriddenStockMaterialId]		VARCHAR(36)					NOT NULL CONSTRAINT [FK_TicketStockOverride_StockMaterialId] FOREIGN KEY REFERENCES StockMaterial(Id),
    [OverriddenWidth]   			REAL						NULL,
    [OverriddenLength]  			REAL		                NULL,
    [CreatedBy]		      			VARCHAR(50)                 NOT NULL,
    [ModifiedBy]	     			VARCHAR(50)                 NOT NULL,
    [CreatedOnUTC]      			DATETIME                    NOT NULL,
    [ModifiedOnUTC]     			DATETIME                    NOT NULL,
    [IsActive]                      BIT                         NOT NULL
);