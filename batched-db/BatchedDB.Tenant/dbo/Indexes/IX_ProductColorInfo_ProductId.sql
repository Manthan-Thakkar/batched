CREATE NONCLUSTERED INDEX [IX_ProductColorInfo_ProductId] 
	ON [dbo].[ProductColorInfo] ([ProductId] )
INCLUDE([Id],[SourceColor],[SourceInkType],[SourceNotes],[Unit],[Anilox],[SourceColorItemType],[ColorSide])