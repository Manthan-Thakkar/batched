/** This view generates a ranking and unique index for each master roll **/

CREATE VIEW dbo.view_masterrollrank
AS

With mr as (SELECT em.SourceEquipmentId PressNumber, sr.TaskName Task, ISNULL(Masterrollnumber, sr.SourceTicketId) as [masterRollNumber], min(StartsAt) as StartTime
  FROM [dbo].[ScheduleReport] sr
  INNER JOIN dbo.EquipmentMaster em on sr.EquipmentId=em.ID
  Group by em.SourceEquipmentId, TaskName, ISNULL(Masterrollnumber, sr.SourceTicketId))

SELECT PressNumber, Task, [masterRollNumber], rank() Over (Partition by PressNumber, Task Order by StartTime ASC) as [MasterRollRank], Case When rank() Over (Partition by PressNumber Order by StartTime ASC) % 2 = 0 Then 1 Else 0 End as [EvenOdd]
  FROM mr