CREATE TABLE [dbo].[MultiRdsRollout_TT]
(
	[Id] [varchar](36) NOT NULL,
	[TenantId] [varchar](36) NOT NULL CONSTRAINT [FK_MultiRdsRollout_TT_Tenant_TenantId] FOREIGN KEY REFERENCES Tenant(ID),
	[IsEnabled] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	CONSTRAINT [PK_MultiRdsRollout_TT] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
