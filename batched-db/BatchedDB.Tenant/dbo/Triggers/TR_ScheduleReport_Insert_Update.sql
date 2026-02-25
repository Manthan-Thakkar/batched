CREATE TRIGGER TR_ScheduleReport_Insert_Update
ON ScheduleReport
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @autoUpdateRouteTimeEnabled bit = 0; 
	SET @autoUpdateRouteTimeEnabled = CASE WHEN EXISTS(SELECT CV.Value 
																	 FROM ConfigurationMaster CM 
																	 INNER JOIN ConfigurationValue CV 
																	 ON CM.Id = CV.ConfigId 
																	 WHERE CM.Name = 'EnableAutoUpdateRouteTime' 
																	 AND CV.Value = 'True')
													   THEN 1 ELSE 0
													END
	IF (@autoUpdateRouteTimeEnabled = 1)
	BEGIN
		SET NOCOUNT ON;  
		UPDATE tt
		SET 
			tt.EstTotalHours = CASE 
									WHEN i.TaskMinutes IS NOT NULL 
									THEN CAST(i.TaskMinutes AS FLOAT) / 60.0 
									ELSE tt.EstTotalHours 
							   END
		FROM TicketTask tt 
		INNER JOIN TicketMaster  tm ON tm.id = tt.TicketId 
		INNER JOIN inserted i ON i.SourceTicketId = tm.SourceTicketId  AND i.Taskname  = tt.TaskName 
		
	END
END