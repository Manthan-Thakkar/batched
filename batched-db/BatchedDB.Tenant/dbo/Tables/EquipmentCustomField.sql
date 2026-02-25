CREATE TABLE [dbo].[EquipmentCustomField]
(
	[ID]			[varchar](36)	NOT NULL,
	[EquipmentId]	[varchar](36)	NOT NULL,
	[KeyName]		[nvarchar](255) NULL,
	[KeyValue]		[nvarchar](255) NULL,
	[CreatedOn]		[datetime]		NULL,
	[ModifiedOn]	[datetime]		NULL,
	CONSTRAINT [PK_EquipmentCustomFieldID] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_EquipmentCustomField_EquipmentMasterID] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[EquipmentMaster] ([ID])
);

