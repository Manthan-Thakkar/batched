IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ProductColorInfo_ProductId'
      AND object_id = OBJECT_ID('dbo.ProductColorInfo')
)
BEGIN
CREATE NONCLUSTERED INDEX [IX_ProductColorInfo_ProductId] 
	ON [dbo].[ProductColorInfo] ([ProductId] )
INCLUDE([Id],[SourceColor],[SourceInkType],[SourceNotes],[Unit],[Anilox],[SourceColorItemType],[ColorSide]);
END