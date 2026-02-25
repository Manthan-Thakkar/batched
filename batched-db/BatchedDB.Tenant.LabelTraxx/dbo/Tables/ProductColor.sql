CREATE TABLE [dbo].[ProductColor] (
    [PK_UUID]      NVARCHAR (450) NOT NULL,
    [UNIQUEPRODID] NVARCHAR (4000) NULL,
    [UNIT]         INT             NULL,
    [COLOR]        NVARCHAR (4000) NULL,
    [ANILOX]       NVARCHAR (4000) NULL,
    [INK_TYPE]     NVARCHAR (4000) NULL,
    [NOTES]        NVARCHAR (4000) NULL,
    [UpdateTimeDateStamp]     DATETIME        NULL
);


GO
CREATE NONCLUSTERED INDEX [_dta_index_ProductColor_8_1427692334__K2_4]
    ON [dbo].[ProductColor]([UniqueProdID] ASC)
    INCLUDE([Color]);

