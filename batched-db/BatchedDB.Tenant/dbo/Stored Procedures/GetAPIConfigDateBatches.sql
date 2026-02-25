/****** Object:  StoredProcedure [dbo].[GetAPIConfigDateBatches]    Script Date: 4/14/2021 11:12:54 AM ******/

-- =============================================
CREATE   PROCEDURE [dbo].[GetAPIConfigDateBatches] 
	-- Add the parameters for the stored procedure here
	@api_config_id int,
	@start_date date,
	@days int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result NVARCHAR(max) = ''

	drop table if exists #batch_fetch_temp

		;WITH GreaterThan(ID, StartDate) AS
		(
			SELECT 1, @start_date AS Number
			UNION ALL
			SELECT ID+2, DATEADD(DAY,@days,StartDate) FROM GreaterThan where DATEADD(DAY,@days+@days,StartDate) <= GETDATE()
		),
		SmallerThan(ID, EndDate) AS
		(
			SELECT 2, DATEADD(DAY,@days,@start_date) AS Number
			UNION ALL
			SELECT ID+2, DATEADD(DAY,@days,EndDate) FROM SmallerThan where DATEADD(DAY,@days,EndDate) <= GETDATE()
		),
		BatchedRec(api_config_id, api_name, ID, RowNum, Number, queryConditional, queryOperator, fieldName, apiConfigParamID) AS
		(
			SELECT  api_config_id, api_name, ID, ROW_NUMBER() OVER (ORDER BY apiConfigParamID) AS RowNum, StartDate, queryConditional, queryOperator AS Number, fieldName, apiConfigParamID 
			FROM GreaterThan 
			cross join (
				SELECT top 1 ACPF.api_config_id, api_name, apiConfigParamID, queryConditional, queryOperator,fieldName
				FROM ApiConfigParamFresh ACPF
				inner join ref_api_config rac on ACPF.api_config_id = rac.api_config_id
				where ACPF.api_config_id = @api_config_id
				order by apiConfigParamID
			) T 
			UNION ALL
			SELECT api_config_id, api_name, ID, ROW_NUMBER() OVER (ORDER BY apiConfigParamID) AS RowNum, EndDate, queryConditional, queryOperator AS Number, fieldName, apiConfigParamID 
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
