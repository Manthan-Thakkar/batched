CREATE TABLE [dbo].[StockMaterialSubstitute]
(
	Id							varchar(36),
	StockMaterialId				varchar(36) not null CONSTRAINT [FK_StockMaterialSubstitute_StockMaterialId] FOREIGN KEY REFERENCES StockMaterial(Id),
	AlternateStockMaterialId	varchar(36) not null CONSTRAINT [FK_StockMaterialSubstitute_AlternateStockMaterialId] FOREIGN KEY REFERENCES StockMaterial(Id),
	[Sequence]					int,
	CreatedOn					DateTime not null,
	ModifiedOn					DateTime not null,
    CONSTRAINT [PK_StockMaterialSubstituteID] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
