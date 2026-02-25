/****** Object:  StoredProcedure [dbo].[GetAPIConfigNumericBatchWise]    Script Date: 4/14/2021 11:12:54 AM ******/


-- =============================================
CREATE   PROCEDURE [dbo].[GetAPIConfigNumericBatchWise]
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

	drop table if exists #ranges

	;WITH GreaterThan(ID, Number1) AS
	(
		SELECT 1, 0 AS Number
		UNION ALL
		SELECT ID+1, Number1 + @batch FROM GreaterThan where Number1 + @batch + @batch <= @batch_limit
	)
	select @api_config_id api_config_id,*, LEAD(Number1,1,@batch_limit) over (order by ID) Number2 into #ranges from GreaterThan option(maxrecursion 0)
		
	set @result = 
	(
		select 
			r.Number1 startSelection, 
			r.Number2 endSelection, 
			rac.api_name tableName,
			queryValues = (
				select queryConditional, fieldName, queryOperator, queryParameter 
				from ApiConfigParamFresh
				where api_config_id = @api_config_id
				order by apiConfigParamID asc
				FOR JSON AUTO
			)
		from #ranges r
		inner join ref_api_config rac on r.api_config_id = rac.api_config_id
		ORDER BY r.Number1
		FOR JSON PATH
	)

	select @result

END
