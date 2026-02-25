CREATE TABLE [dbo].[EquipmentDowntime]
(
	[Id]					VARCHAR(36) NOT NULL,
	[EquipmentId]			VARCHAR(36) NOT NULL CONSTRAINT [FK_EquipmentDowntime_EquipmentMasterId] FOREIGN KEY REFERENCES EquipmentMaster(Id),
	[StartsOn]				DATETIME NOT NULL,
	[EndsAt]				DATETIME NOT NULL,
	[IsPlannedDowntime]		BIT NOT NULL,
	[Name]					NVARCHAR(64) NOT NULL,
	[CreatedOn]				DATETIME NOT NULL,
	[ModifiedOn]			DATETIME NULL,
	[GroupId]               VARCHAR(36) NOT NULL
    CONSTRAINT [PK_EquipmentDowntimeId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)