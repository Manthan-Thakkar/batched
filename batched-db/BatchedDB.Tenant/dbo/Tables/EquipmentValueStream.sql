CREATE TABLE [dbo].[EquipmentValueStream](
  [Id]				VARCHAR(36)		PRIMARY KEY NOT NULL,
  [EquipmentId]		VARCHAR(36)		NOT NULL,
  [ValueStreamId]	VARCHAR(36)		NOT NULL,
  [CreatedOnUTC]	DATETIME		NOT NULL,
  [ModifiedOnUTC]	DATETIME		NOT NULL,

  CONSTRAINT [FK_EquipmentValueStream_EquipmentId]		FOREIGN KEY([EquipmentId])		REFERENCES [dbo].[EquipmentMaster]([ID]),
  CONSTRAINT [FK_EquipmentValueStream_ValueStreamId]	FOREIGN KEY([ValueStreamId])	REFERENCES [dbo].[ValueStream]([Id])
  );