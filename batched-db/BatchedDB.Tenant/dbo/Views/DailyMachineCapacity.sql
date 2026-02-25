CREATE VIEW [dbo].[DailyMachineCapacity]

AS

WITH SysTimeOffSet_CTE AS (SELECT  SYSDATETIMEOFFSET() AT TIME ZONE (SELECT cv.Value
																FROM ConfigurationValue cv
																INNER JOIN ConfigurationMaster cm on cm.Id = cv.ConfigId
																Where cm.Name = 'Timezone') as CurrentTime)
,

DailyMachineCapacity_CTE as (SELECT SourceEquipmentId AS Press, CAST(TheDateTime AS date) AS DATE,  COUNT(*) / 60.0 AS AvailableHours
FROM EquipmentCalendar
WHERE Available=1 and TheDateTime >= (Select Top 1 CurrentTime From SysTimeOffSet_CTE) and TheDateTime < cast(dateadd(day, 1, (Select Top 1 CurrentTime From SysTimeOffSet_CTE)) as date)
GROUP BY SourceEquipmentId, CAST(TheDateTime AS DATE))

SELECT * FROM DailyMachineCapacity_CTE

UNION

Select SourceEquipmentID as Press, Date as DATE, PlannedHours as AvailableHours
From DailyEquipmentCapacity
Where Date >= cast(dateadd(day, 1, (Select Top 1 CurrentTime From SysTimeOffSet_CTE)) as date)