CREATE TABLE [dbo].[StockMaterialGroup]
(
	Id			varchar(36),
	[Name]		nvarchar(255) not null,
	TenantId	varchar(36) not null,
	CreatedOn	DateTime not null,
	ModifiedOn	DateTime not null,
	CONSTRAINT UC_StockMaterialGroup UNIQUE ([Name],TenantId),
    CONSTRAINT [PK_StockMaterialGroupID] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
