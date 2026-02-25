CREATE TABLE [dbo].[ShiftOverride]
(
	[Id]			VARCHAR(36) NOT NULL,
	[EquipmentId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftOverride_EquipmentMasterId] FOREIGN KEY REFERENCES EquipmentMaster(Id),
	[ExceptionDate]	DATETIME NOT NULL,
	[IsEnabled]		BIT NOT NULL,
	[CreatedOn]		DATETIME,
	[ModifiedOn]	DATETIME,	
    CONSTRAINT [PK_ShiftOverrideId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
