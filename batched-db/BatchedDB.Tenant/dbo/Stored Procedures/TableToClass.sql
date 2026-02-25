/****** Object:  StoredProcedure [dbo].[TableToClass]    Script Date: 4/14/2021 11:12:54 AM ******/


CREATE   PROCEDURE [dbo].[TableToClass] --'Users'

@table_name SYSNAME

AS

SET NOCOUNT ON

DECLARE @temp TABLE
(
sort INT,
code TEXT
)

INSERT INTO @temp
SELECT 1, 'public class ' + @table_name + CHAR(13) + CHAR(10) + '{'
+ CHAR(13) + CHAR(10) + CHAR(9)  + '[Key]'
INSERT INTO @temp
SELECT 9, CHAR(9) + 'public ' +
CASE
WHEN DATA_TYPE LIKE '%CHAR%' THEN 'string '
WHEN DATA_TYPE LIKE '%INT%' THEN 'int '
WHEN DATA_TYPE LIKE '%FLOAT%' THEN 'double '
WHEN DATA_TYPE LIKE '%DATETIME%' THEN 'DateTime '
WHEN DATA_TYPE LIKE '%DATE%' THEN 'DateTime '
WHEN DATA_TYPE LIKE '%TIME%' THEN 'DateTime '
WHEN DATA_TYPE LIKE '%BINARY%' THEN 'byte[] '
WHEN DATA_TYPE = 'BIT' THEN 'bool '
WHEN DATA_TYPE LIKE '%TEXT%' THEN 'string '
ELSE 'object '
END + COLUMN_NAME +
'{ get; set; }'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @table_name
ORDER BY ORDINAL_POSITION

INSERT INTO @temp
SELECT 10,
CHAR(13) + CHAR(10) + '}'

SELECT code FROM @temp
ORDER BY sort
