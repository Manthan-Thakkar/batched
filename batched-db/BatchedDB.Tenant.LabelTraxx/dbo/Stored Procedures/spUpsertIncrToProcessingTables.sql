CREATE PROCEDURE dbo.spUpsertIncrToProcessingTables
    @TableName VARCHAR(4000)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRANSACTION;

	DECLARE
	@Columns VARCHAR(MAX) = (
	SELECT COLUMN_NAME + ',' 
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = @TableName
	FOR XML PATH('')
	)

	DECLARE
	@TableNameIncr VARCHAR(4000) = @TableName + '_Incr'

	DECLARE  @MergeQuery NVARCHAR(MAX)
	DECLARE  @UpdateQuery VARCHAR(MAX)
	DECLARE  @InsertQuery VARCHAR(MAX)
	DECLARE  @InsertQueryValues VARCHAR(MAX)
	DECLARE  @Col VARCHAR(200)

	SET @UpdateQuery='Update Set '
	SET @InsertQuery='Insert ('
	SET @InsertQueryValues=' Values('


	WHILE LEN(@Columns) > 0
	BEGIN
	   SET @Col=left(@Columns, charindex(',', @Columns+',')-1);

	   IF @Col<> 'PK_UUID'
	   BEGIN
		  SET @UpdateQuery= @UpdateQuery+ 'a.'+ @Col + ' = aIncr.'+ @Col+ ','
	   END
		  SET @InsertQuery= @InsertQuery+@Col + ','
		  SET @InsertQueryValues=@InsertQueryValues+'aIncr.'+ @Col+ ','
	  SET @Columns = stuff(@Columns, 1, charindex(',', @Columns+','), '')
	END

	SET @UpdateQuery=LEFT(@UpdateQuery, LEN(@UpdateQuery) - 1)
	SET @InsertQuery=LEFT(@InsertQuery, LEN(@InsertQuery) - 1)
	SET @InsertQueryValues=LEFT(@InsertQueryValues, LEN(@InsertQueryValues) - 1)

	SET @InsertQuery=@InsertQuery+ ')'+  @InsertQueryValues +')'

	SET @MergeQuery=
	N'MERGE ' + @TableName + ' as a
	USING ' + @TableNameIncr + ' as aIncr
	ON a.[PK_UUID] = aIncr.[PK_UUID]' +

	'WHEN MATCHED THEN ' + @UpdateQuery +
	' WHEN NOT MATCHED THEN '+@InsertQuery +';'

	Execute sp_executesql @MergeQuery

  COMMIT TRANSACTION;
END