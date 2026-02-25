/****** Object:  StoredProcedure [dbo].[GetAPIList]    Script Date: 4/14/2021 11:12:54 AM ******/


-- =============================================
CREATE   PROCEDURE [dbo].[GetAPIList]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select 
		api_config_id,
		api_name,
		api_endpoint,
		api_endpoint_fresh,
		api_sequence,
		api_method,
		s3_bucket_location,
		is_fresh_api,
		batch_per_request,
		total_rows, 
		batch_type, 
		CONVERT(nvarchar(max),initial_date) initial_date 
	FROM 
		ref_api_config 
	where 
		is_active = 1 
	order by 
		api_sequence
END
