CREATE NONCLUSTERED INDEX [IX_JobRun_JobId_Timestamp_WorkflowStep]
	ON [dbo].[JobRun]
	(JobId) 
	INCLUDE ([WorkflowStep], [TimeStamp], [Status])
