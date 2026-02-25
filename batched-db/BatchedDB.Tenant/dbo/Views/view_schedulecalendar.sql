/** This view generates a minute level calendar view of the schedule **/

CREATE   VIEW [dbo].[view_schedulecalendar]
AS

Select sc.*, cast(sc.timeValue as date) as [Date], isnull(sc.Number, 'Empty') as [Ticket], TaskDone
From [dbo].[scheduleCalendar] sc
Join [dbo].[AllOpenticketTasks_Table] ott on sc.Number=ott.Number and sc.Task=ott.Task
