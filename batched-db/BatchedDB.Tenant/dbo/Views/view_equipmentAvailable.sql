CREATE VIEW [dbo].[view_equipmentAvailable]
AS
with masterequipmentreference as (
                Select em.SourceEquipmentId, em.ID, em.AvailableForPlanning, em.Description, em.AvailableForScheduling, WorkCenterName as Workcenter,facilityid
                From EquipmentMaster em
                Where AvailableForScheduling=1 and isEnabled = 1) 

,equip as (
        select distinct
		mer.Id as EquipmentId,
        mer.SourceEquipmentId as PressNumber,
        mer.*,
        ljr.Ticket_No,
        case when ljr.minutesElapsed is null then 0 else ljr.minutesElapsed end as minutesElapsed,
        case when ljr.MaxStartDateTime is null then 0 else ljr.MaxStartDateTime end as MaxStartDateTime,
        case when DateAdd(MI, ceiling(0), dateadd(MI, datediff(MI, 0, dateadd(s, 30, ljr.MaxStartDateTime)), 0) ) is null then 0 else DateAdd(MI, ceiling(0), dateadd(MI, datediff(MI, 0, dateadd(s, 30, ljr.MaxStartDateTime)), 0)) end as estimatedFreeTime
    from masterequipmentreference mer
    left join LastJobsRun ljr
        on mer.SourceEquipmentId = ljr.PressNo
)
,equip_task_clf as (
    select *
    FROM equip e
)
,facilitytimezones_preparse as (

select cv.Value as timezone,
    cm.name
    from ConfigurationValue cv 
    left join ConfigurationMaster cm on cv.ConfigId = cm.Id 
    where cv.ConfigId in 
      (select id from ConfigurationMaster where Name like '%TZ%' and Name not like '%LTZ%')
)

,facilitytimezones as (

select ftz.timezone, value from facilitytimezones_preparse ftz cross apply string_split(ftz.Name, '_')
where value not like '%facility%' and value not like '%TZ%'

)
,isMultifacilitySchedulingEnabled as (
	SELECT cv.Value FROM ConfigurationValue cv 
	INNER JOIN ConfigurationMaster cm on cm.Id = cv.ConfigId
	Where cm.Name = 'EnableMultiFacilityScheduling'
)
,tenantTimeZone as (
SELECT cv.Value FROM ConfigurationValue cv INNER JOIN ConfigurationMaster cm on cm.Id = cv.ConfigId Where cm.Name = 'Timezone')

,equipmenttimezone as (

select 
em.ID, 
em.sourceequipmentid, 
    Case When 
        ftz.timezone is not null and (
		SELECT Value FROM isMultifacilitySchedulingEnabled) = 'True'
		then ftz.timezone 
    else
        (select value from tenantTimeZone)
    end as timezone,
	SYSDATETIMEOFFSET() AT TIME ZONE (timezone) as offset
from masterequipmentreference em
left join facilitytimezones ftz on em.facilityid = ftz.value
)
,first_avail as(
    select distinct
            e.ID as EquipmentId,
            e.SourceEquipmentId as PressNumber,
            e.Workcenter,
            max(e.estimatedFreeTime) OVER (partition by e.SourceEquipmentId) maxFirstAvailable,
            (select thedatetime from MinutewiseCalendar where thedatetime =(Select dateadd(mi, datediff(mi, 0, offset),0) as currtime)) as timeZero
    from equip_task_clf e
    left join equipmenttimezone etz on etz.id = e.id
)

,first_avail_ref as (
    select *,
        (select max(avail) FROM (VALUES (fa.maxfirstAvailable),(fa.timeZero)) AS ti(avail)) equipmentFirstAvailable,
        upper(fa.Workcenter) as TaskWorkCenter
    from first_avail fa
)


,f2 AS (

    SELECT
        EquipmentId,
        CASE WHEN equipmentFirstAvailable > CAST(SYSDATETIMEOFFSET() AT TIME ZONE (etz.timezone) AS smalldatetime) THEN equipmentFirstAvailable 
            ELSE CAST(SYSDATETIMEOFFSET() AT TIME ZONE (etz.timezone) AS smalldatetime) END AS MaxFirstAvailableTime
    FROM first_avail_ref far
    left join equipmenttimezone etz on far.EquipmentId = etz.ID
)

,iec as (
select EquipmentId, TheDateTime,TimeIndex, AdjustedTimeIndex from 
dbo.EquipmentCalendar
where TheDateTime <= DATEADD(dd, 100, GETDATE()) and TheDateTime >= DATEADD(dd, -10, GETDATE())
and equipmentId in (select distinct EquipmentId from EquipmentMaster em
                Where IsEnabled = 1 and AvailableForScheduling=1)
)
,time_zero AS (
    -- Earliest time on calendar after equipment first available date
    SELECT
        iec.EquipmentId,
        MIN(iec.TheDateTime) AS TheDateTime,
        MIN(iec.TimeIndex) AS TimeIndex,
        MIN(iec.AdjustedTimeIndex) AS AdjustedTimeIndex
 FROM iec
 JOIN f2 ON f2.EquipmentId = iec.EquipmentId
    WHERE f2.MaxFirstAvailableTime <= iec.TheDateTime
    GROUP BY iec.EquipmentId
)


select distinct
        time_zero.AdjustedTimeIndex AS equipmentFirstAvailableReference,
        time_zero.TheDateTime AS equipmentFirstAvailable,
        far.TaskWorkCenter,
        e.PressNumber,
        e.SourceEquipmentId as Name,
        e.AvailableForPlanning,
        e.Description,
        e.AvailableForScheduling,
        e.Workcenter,
        e.Ticket_No,
        e.minutesElapsed,
        e.MaxStartDateTime,
        e.estimatedFreeTime
from first_avail_ref far
left join MinutewiseCalendar AS tv1
    on far.equipmentFirstAvailable = tv1.TheDateTime
left join time_zero
    on time_zero.EquipmentId = far.EquipmentId
left join equip_task_clf AS e
    on far.PressNumber = e.SourceEquipmentId and far.TaskWorkCenter = e.Workcenter
    and far.maxFirstAvailable = e.estimatedFreeTime
left join [EquipmentCalendar] AS ec 
    on tv1.TheDateTime = ec.[TheDateTime]
    and e.PressNumber = ec.[SourceEquipmentId]
Where time_zero.AdjustedTimeIndex is not null and  time_zero.TheDateTime is not null