CREATE TABLE [dbo].[TenantSizeType]
(
	[ID]			varchar(36)		NOT NULL,
	[Type]			nvarchar(64)	NOT NULL,
	[DisplayText]	nvarchar(255)	NOT NULL,
	CONSTRAINT [PK_TenantSizeType] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
