/****** Object:  StoredProcedure [dbo].[GetAPIConfigNumericBatches]    Script Date: 4/14/2021 11:12:54 AM ******/


-- =============================================
CREATE   PROCEDURE [dbo].[GetAPIConfigNumericBatches] 
	-- Add the parameters for the stored procedure here
	@api_config_id int,
	@batch int,
	@batch_limit int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @result nvarchar(max) = ''
	drop table #batch_fetch_temp

		;WITH GreaterThan(ID, Number1) AS
		(
			SELECT 1, 0 AS Number
			UNION ALL
			SELECT ID+2, Number1 + @batch FROM GreaterThan where Number1 + @batch + @batch <= @batch_limit
		),
		SmallerThan(ID, Number2) AS
		(
			SELECT 2, @batch AS Number
			UNION ALL
			SELECT ID+2, Number2 + @batch FROM SmallerThan where Number2 + @batch <= @batch_limit
		),
		BatchedRec(api_config_id, api_name, ID, RowNum, Number, queryConditional, queryOperator, fieldName, apiConfigParamID) AS
		(
			SELECT  api_config_id, api_name, ID, ROW_NUMBER() OVER (ORDER BY apiConfigParamID) AS RowNum, Number1, queryConditional, queryOperator AS Number, fieldName, apiConfigParamID 
			FROM GreaterThan 
			cross join (
				SELECT top 1 ACPF.api_config_id, api_name, apiConfigParamID, queryConditional, queryOperator,fieldName
				FROM ApiConfigParamFresh ACPF
				inner join ref_api_config rac on ACPF.api_config_id = rac.api_config_id
				where ACPF.api_config_id = @api_config_id
				order by apiConfigParamID
			) T 
			UNION ALL
			SELECT api_config_id, api_name, ID, ROW_NUMBER() OVER (ORDER BY apiConfigParamID) AS RowNum, Number2, queryConditional, queryOperator AS Number, fieldName, apiConfigParamID 
			FROM SmallerThan 
			cross join (
				SELECT ACPF.api_config_id, api_name, ROW_NUMBER() OVER (ORDER BY apiConfigParamID) AS RowNum, apiConfigParamID, fieldName,
				queryConditional, queryOperator
				FROM ApiConfigParamFresh ACPF
				inner join ref_api_config rac on ACPF.api_config_id = rac.api_config_id
				where ACPF.api_config_id = @api_config_id
			) T WHERE RowNum IN (2)

		)

		select api_endpoint_fresh, api_method, s3_bucket_location, api_sequence, ID, RowNum,fieldName, queryConditional, queryOperator, Number queryParameter, BR.api_config_id, BR.api_name
		into #batch_fetch_temp
		from BatchedRec BR
		inner join ref_api_config rac on BR.api_config_id = rac.api_config_id
		order by ID
		option (maxrecursion 0)
		--for JSON AUTO

		--select api_name, api_endpoint_fresh, api_method, s3_bucket_location, api_sequence, api_config_id, 
		--(
		set @result = (SELECT api_name 'tableName',
		(
			SELECT queryConditional 'queryConditional', fieldName 'fieldName',
			queryOperator 'queryOperator', queryParameter 'queryParameter'
			FROM #batch_fetch_temp SD
			WHERE SH.RowNum = SD.RowNum
			FOR JSON AUTO
		) queryValues
		FROM #batch_fetch_temp SH
		where ID % 2 <> 0
		FOR JSON AUTO)
		--) params
		--from ref_api_config
		--where api_config_id = @api_config_id
		select @result
		
END
