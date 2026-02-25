CREATE TABLE PurchaseOrderAudit
(
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    StockMaterialId VARCHAR(36) NOT NULL,
    PurchaseOrderNumber VARCHAR(10),
    OrderQuantity REAL NOT NULL,
    Width REAL NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedOn DATETIME,
    ModifiedOn DATETIME
)