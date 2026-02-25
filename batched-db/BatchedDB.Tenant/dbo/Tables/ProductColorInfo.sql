CREATE TABLE [dbo].[ProductColorInfo]
(
	Id						varchar(36),	
	ProductId				varchar(36) NOT NULL CONSTRAINT [FK_ProductColorInfo_ProductId] FOREIGN KEY REFERENCES ProductMaster(Id),
	Source					varchar(36) NOT NULL,
	SourceProductColorId	nvarchar(4000),
	SourceColor				nvarchar(4000),
	Unit					int NULL,
	SourceInkType			nvarchar(4000),
	CreatedOn				Datetime NOT NULL,
	ModifiedOn				Datetime NOT NULL,
    SourceNotes			    nvarchar(4000),
	Anilox					varchar(255) NULL,
	SourceColorItemType		NVARCHAR(4000) NULL,
	ColorSide				int NULL,
    CONSTRAINT [PK_ProductColorInfoID] PRIMARY KEY NONCLUSTERED ([Id])
)
