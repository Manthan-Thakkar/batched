IF '$(DatabaseName)' NOT IN ('brook-and-whittle-bnw-tn-mo', 'brook-and-whittle-bnw-tn-mo-pb')
BEGIN
    PRINT 'Setting NOEXEC ON for $(DatabaseName)';
    SET NOEXEC ON;
END
GO
--:r ../Schema/BnW-TnMO-ImportPurchaseOrderItem.sql
--GO
:r ../Schema/BnW-TnMO-ImportStockInventoryData.sql
GO
SET NOEXEC OFF;
GO
PRINT 'Setting NOEXEC OFF';
GO