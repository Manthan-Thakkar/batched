CREATE  PROCEDURE [dbo].[spUpdateCVTicketAttributeCachValues]
	@CorelationId			AS VARCHAR(40) = NULL,
	@TenantId				AS VARCHAR(40) = NULL,
    @TicketAttributes UDT_SingleField READONLY
AS
BEGIN
    DECLARE 
		@spName								VARCHAR(100) = 'spUpdateCVTicketAttributeCachValues',
		@__ErrorInfoLog						__ErrorInfoLog,
		@maxCustomMessageSize				INT = 4000,
		@blockName							VARCHAR(100),
		@warningStr							NVARCHAR(4000),
		@infoStr							NVARCHAR(4000),
		@errorStr							NVARCHAR(4000),
		@IsError							BIT = 0,
		@startTime							DATETIME,
		@AttrName							NVARCHAR(255),
		@sql								NVARCHAR(MAX);

    -- Cursor to iterate over new attributes
    DECLARE attr_cursor CURSOR FOR 
        SELECT Field FROM @TicketAttributes;

	SET @blockName = 'Update CVTicketAttribute table'; SET @startTime = GETDATE();
		OPEN attr_cursor;
		FETCH NEXT FROM attr_cursor INTO @AttrName;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Check if column exists in CVTicketAttributesCache

			IF NOT EXISTS (SELECT 1 
						   FROM INFORMATION_SCHEMA.COLUMNS 
						   WHERE TABLE_NAME = 'CVTicketAttributesCache'
						   AND COLUMN_NAME = @AttrName)
			BEGIN
				-- Dynamically add the column to CVTicketAttributesCache
				SET @sql = 'ALTER TABLE CVTicketAttributesCache ADD [' + @AttrName + '] NVARCHAR(MAX)';
				EXEC sp_executesql @sql;

				-- Populate the newly added column with values from TicketAttributeValues
				SET @sql = 'UPDATE CVTicketAttributesCache
							SET '+@AttrName+' = TAV.Value
							FROM CVTicketAttributesCache CV
							INNER JOIN TicketAttributeValues TAV
							ON CV.TicketId = TAV.TicketId
							WHERE TAV.Name = '''+@AttrName+''';'

				EXEC sp_executesql @sql;
			END

			FETCH NEXT FROM attr_cursor INTO @AttrName;
		END;

		CLOSE attr_cursor;
		DEALLOCATE attr_cursor;
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
END
