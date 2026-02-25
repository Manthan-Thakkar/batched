CREATE TABLE [dbo].[AuditField](
	[Id] [varchar](36) CONSTRAINT [PK_AuditField] PRIMARY KEY  NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Value] [varchar](1000) NULL,
	[AuditId] [varchar](36) CONSTRAINT [FK_AuditField_AuditMaster] FOREIGN KEY REFERENCES AuditMaster(Id) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	DataType varchar(20) NOT NULL);