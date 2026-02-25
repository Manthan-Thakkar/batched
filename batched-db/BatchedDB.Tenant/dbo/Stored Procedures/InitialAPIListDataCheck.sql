/****** Object:  StoredProcedure [dbo].[InitialAPIListDataCheck]    Script Date: 4/14/2021 11:12:54 AM ******/


CREATE   PROCEDURE [dbo].[InitialAPIListDataCheck]
	-- Add the parameters for the stored procedure here
	@timezone_ts DateTime,
	@task_ts DateTime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	update ref_api_config set requires_truncate = 1 where truncate_eligible = 1;
    
	-- Insert statements for procedure here
	IF (
		(cast(@timezone_ts as time) > cast('02:00:00 AM' as time)) 
		AND 
		((Select COUNT(*) from DailyBatch where cast(DailyBatchTS as date) = cast(@timezone_ts as date) and cast(DailyBatchTS as time) > cast('02:00:00' as time)) = 0)
	)
		BEGIN
		   update ref_api_config set is_fresh_api = 1, is_active = 1 where midnight_fresh_eligible = 1;
		   insert into DailyBatch values(@timezone_ts);
		END
	ELSE
		BEGIN
			update ref_api_config set is_active = 0 where midnight_fresh_eligible = 1;
		END



	select 'success' response
END
