﻿IF '$(DatabaseName)' != 'brook-and-whittle-bnw-oh'
BEGIN
    PRINT 'Setting NOEXEC ON for $(DatabaseName)';
    SET NOEXEC ON;
END
GO
:r ../Schema/spCreateUnassignedJobsData_BnW-Ohio.sql
GO
SET NOEXEC OFF;
GO
PRINT 'Setting NOEXEC OFF';
GO