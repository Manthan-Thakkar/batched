
CREATE PROCEDURE [dbo].[GetAPIForSpecialEndpointsIncr]
	-- Add the parameters for the stored procedure here
	@api_config_id int = 3,
	@api_config_param_seq int = 2
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	DECLARE 
		@result nvarchar(max) = '',
		@startSelection int, 
		@endSelection int, 
		@batch int, 
		@batch_limit int


	-- PIVOT Table to convert api_config_param to columns 
	
	drop table if exists #tempApiParameters;

	SELECT api_config_id, dateType, endSelection,	entryModDate,	entryModTime,	startSelection
	into #tempApiParameters
	from 
		(
		select api_param_name, api_param_value, api_config_id
		from ref_api_config_param
		where api_config_id = @api_config_id
		and api_config_param_seq = @api_config_param_seq
	) x
	pivot 
	(
		max(api_param_value)
		for api_param_name in (dateType, endSelection,	entryModDate,	entryModTime,	startSelection)
	) p
	

	--Fetch batch values 
	select 
		@batch = batch_per_request,
		@batch_limit = total_rows
	from ref_api_config_param racp 
	inner join ref_api_config rac on racp.api_config_id = rac.api_config_id
	where 1 = 1
	and rac.api_config_id = @api_config_id 
	and racp.api_config_param_seq = @api_config_param_seq


	--Divide the range into batches

	drop table if exists #ranges

	;WITH GreaterThan(ID, Number1) AS
	(
		SELECT 1, 0 AS Number
		UNION ALL
		SELECT ID+1, Number1 + @batch FROM GreaterThan where Number1 + @batch + @batch <= @batch_limit
	)
	select 
		@api_config_id api_config_id,
		@api_config_param_seq api_config_param_seq,
		*, 
		LEAD(Number1,1,@batch_limit) over (order by ID) Number2 
	into #ranges 
	from GreaterThan 
	option(maxrecursion 0)
		
	-- Final select in JSON format
	set @result = 
	(
		select 
			entryModDate,	
			entryModTime,	
			(r.Number1 + 1) startSelection, 
			r.Number2 endSelection,
			dateType
		from #ranges r
		inner join ref_api_config rac on r.api_config_id = rac.api_config_id
		inner join #tempApiParameters t1 on rac.api_config_id = t1.api_config_id
		where 1=1
		and rac.api_config_id = @api_config_id 
		ORDER BY startSelection
		FOR JSON PATH
	)
	
	drop table if exists #tempApiParameters;

	-- return result
	select @result

END
