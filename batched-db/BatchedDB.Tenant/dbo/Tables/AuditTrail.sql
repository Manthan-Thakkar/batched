CREATE TABLE [dbo].[AuditTrail](
	[Id] [varchar](36) CONSTRAINT [PK_AuditTrail] PRIMARY KEY  NOT NULL,
	[FieldName] [varchar](100) NOT NULL,
	[FieldAction] [varchar](20) NOT NULL,
	[Old] [varchar](1000) NULL,
	[New] [varchar](1000) NULL,
	[DataType] [varchar](20) NOT NULL,
	[AuditId] [varchar](36) CONSTRAINT [FK_AuditTrail_AuditMaster] FOREIGN KEY REFERENCES AuditMaster(Id) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL);