CREATE TABLE [dbo].[StockMaterial]
(
	Id					varchar(36),
	TenantId			varchar(36) not null,
	Source				nvarchar(64) not null,
	SourceStockId		nvarchar(255) not null,
	[Group]				nvarchar(255) null,
	FaceColor			nvarchar(255) not null,
	FaceStock			nvarchar(4000) not null,
	LinerCaliper		nvarchar(64) null,
	Classification		nvarchar(4000) not null,
	AdhesiveClass		NVARCHAR (4000) NULL,
	[Type]				varchar(255),
	IsEnabled			bit not null,
	SourceCreatedOn		DateTime null,
	SourceModifiedOn	DateTime null,
	CreatedOn			DateTime not null,
	ModifiedOn			DateTime not null,
	MFGSpecNum			NVARCHAR (4000) NULL,
	PurchaseOrderLeadTime	int not null default 60, --Lead time for unconfirmed purchase orders in days.
	StockInLeadTime			int not null default 14, --Lead time for stock out material to be in stock in days.
	ExcludeFromMaterialPlanning bit not null default 0,
	[FaceCaliper]				NVARCHAR(64)	NULL,
	[MasterWidth]				REAL			NOT NULL DEFAULT 0,
	[CostMSI]					REAL			NOT NULL DEFAULT 0,
	[Adhesive]					NVARCHAR(4000)	NULL,
	[DefaultCoreSize]			REAL			NOT NULL DEFAULT 0,	
	[TopCoat]					NVARCHAR(4000)	NULL,
    CONSTRAINT [PK_StockMaterialID] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);

GO
CREATE NONCLUSTERED INDEX NCI_StockMaterial_SourceStockIdTenantId
	ON [dbo].[StockMaterial] ([Source],[SourceStockId],[TenantId])
