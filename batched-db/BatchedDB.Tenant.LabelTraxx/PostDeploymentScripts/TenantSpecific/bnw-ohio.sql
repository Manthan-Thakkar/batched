IF '$(DatabaseName)' NOT IN ('brook-and-whittle-bnw-oh', 'brook-and-whittle-bnw-oh-pb')
BEGIN
    PRINT 'Setting NOEXEC ON for $(DatabaseName)';
    SET NOEXEC ON;
END
GO
--:r ../Schema/BnW-TnMO-ImportPurchaseOrderItem.sql
--GO
:r ../Schema/spCreateUnassignedJobsData_BnW-Ohio.sql
GO
SET NOEXEC OFF;
GO
PRINT 'Setting NOEXEC OFF';
GO