/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r ./myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

--Schema changes
--Naming conventions
--SP  ---> date_spName
--Table  ---> date_TableName(Include all table related operations)
--Index  ---> date_IndexName
--Note:
-- If post deployment script contains multiple tables alteration
-- Add independent files for each table respectively for more readability


/***************************NOTE**********************/
/*SCHEMA CHANGES SHOULD OCCUR BEFORE DATA INSERT/UPDATE*/


--Schema changes
--GO
--:r ./Schema/ TODO
GO
:r ./Schema/2026-01-23_spCalculateDslValues.sql
GO
:r ./Schema/2026-01-30_IX_ProductColorInfo_ProductId.sql
GO
:r ./Schema/2026-02-04_view_OrderStatusLatestTaskTimes.sql
GO
--Data changes
--GO
--:r ./Data/ TODO

GO
:r ./Data/MinuteWiseCalendar.sql

GO
:r ./Data/Calendar.sql



/***************************NOTE**********************/
/*Add tenant specific scripts at the end,z comment the scripts if there are no changes*/
 --GO
 --:r ./TenantSpecific/bnw-ohio.sql
 --GO
 --:r ./TenantSpecific/bnw-tnmo.sql
 --GO
