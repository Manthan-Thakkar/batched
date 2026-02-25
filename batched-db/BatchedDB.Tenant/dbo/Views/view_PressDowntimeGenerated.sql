
CREATE   VIEW [dbo].[view_PressDowntimeGenerated]

AS

select * from PressDowntimeGenerated where StartTimeReference is not NULL

