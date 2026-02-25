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



--Note: Schema changes should occur prior to data insertions and updates

--Schema changes

--GO
--:r ./Schema/ TODO




--Data changes
--GO
--:r ./Data/ TODO   (e.g. :r ./Data/2025-01-06_WIP_value.sql)
GO
:r ./Data/2026-01-23_ColorByUnit_dsl.sql
GO