CREATE PROCEDURE [dbo].[spGenerateCVTicketAttributeCacheValues]
	@CorelationId						AS VARCHAR(40) = NULL,
	@TenantId							AS VARCHAR(40) = NULL,
	@BatchedLevelTicketAttributes       AS udt_singleFieldFilter readonly
AS
BEGIN
	DECLARE 
		@spName								VARCHAR(100) = 'spGenerateCVTicketAttributeCacheValues',
		@__ErrorInfoLog						__ErrorInfoLog,
		@maxCustomMessageSize				INT = 4000,
		@blockName							VARCHAR(100),
		@warningStr							NVARCHAR(4000),
		@infoStr							NVARCHAR(4000),
		@errorStr							NVARCHAR(4000),
		@IsError							BIT = 0,
		@startTime							DATETIME,
		@IsStockAvailabilityEnabled			BIT = 0,
		@create_table_query					NVARCHAR(MAX) = '',
		@create_CVTicketAttributes			NVARCHAR(MAX) = '',
		@tableName							NVARCHAR(128) = 'CVTicketAttributesCache',
		@insert_query						NVARCHAR(MAX) = '';
	
	DROP TABLE IF EXISTS #TicketAttributesInUse;

BEGIN TRANSACTION;
BEGIN TRY
    
	SET @blockName = 'Create CVTicketAttribute table'; SET @startTime = GETDATE();

		SELECT DISTINCT
		FieldName 
		INTO #TicketAttributesInUse
		FROM  ReportViewField RV
		LEFT JOIN Ticketattribute ta ON rv.FieldName = ta.Name
		WHERE RV.Category = 'TicketAttribute'
		UNION 
		SELECT Field as FieldName FROM @BatchedLevelTicketAttributes 

		IF EXISTS (SELECT * FROM #TicketAttributesInUse)
		BEGIN

			-- Loop through each row in #TicketAttributesInUse and add columns to the SQL
			SELECT @create_table_query = @create_table_query + FieldName + ' NVARCHAR(MAX), '
			FROM #TicketAttributesInUse
			-- Remove the last comma and space, and close the CREATE TABLE statement
			SET @create_table_query = LEFT(@create_table_query, LEN(@create_table_query) - 1) + ');'

			SET @create_CVTicketAttributes = 'CREATE TABLE CVTicketAttributesCache (TicketId Varchar(36),' + @create_table_query

		END
		ELSE BEGIN
			SET @create_CVTicketAttributes = 'CREATE TABLE CVTicketAttributesCache (TicketId Varchar(36));';
		END

		DROP TABLE IF EXISTS CVTicketAttributesCache
		-- Optionally, execute the generated SQL to create the table
		EXEC sp_executesql @create_CVTicketAttributes
		
		DROP TABLE IF EXISTS #TicketAttributesInUse
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	SET @blockName = 'Insert records into CVTicketAttributeCache_temp table'; SET @startTime = GETDATE();
		
		SET @insert_query = 'WITH TicketAttribute_CTE AS ( SELECT TicketId,';

		SELECT @insert_query = @insert_query + 'MAX(CASE WHEN Name=''' + COLUMN_NAME + ''' THEN Value END) as '+ COLUMN_NAME+','
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tableName AND COLUMN_NAME <> 'TicketId' 
		
		SET @insert_query = LEFT(@insert_query, LEN(@insert_query) - 1) + ' FROM 
		    TicketAttributeValues_temp
		GROUP BY 
		    TicketId)';
		
		SET @insert_query = @insert_query + 'INSERT INTO CVTicketAttributesCache 
		SELECT * FROM TicketAttribute_CTE;'
		
		---- Optionally, execute the generated SQL to create the table
		EXEC sp_executesql @insert_query
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

    IF XACT_STATE() > 0 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;

END