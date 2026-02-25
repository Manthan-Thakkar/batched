CREATE VIEW [dbo].[view_jobAssignments]
AS
with 
jobStarted_tmp_temp as (
    select 
        uj.PressNumber,
        tm.SourceFacilityId,
        uj.LastScan,
        uj.taskClassification,
        uj.Number,
        uj.TaskName as task,
        uj.masterRollNumber,
        uj.taskEstimatedMinutes,
        uj.taskIndex,
        min(uj.taskIndex) OVER (partition by uj.Number) firstTaskIndex,
        sum(taskEstimatedMinutes) OVER (partition by uj.PressNumber ORDER BY uj.lastScan) AS cumTaskEstimatedMinutes,
        1 Locked,
        0 jobFirstAvailable,
        case when taskEstimatedMinutes < 1 then 1 else taskEstimatedMinutes end TaskMinutes
    from unassignedJobs uj
    inner join TicketMaster tm on uj.Number = tm.SourceTicketId
    left join lastJobsRun ljr
    on uj.PressNumber = ljr.PressNo
    where 
        uj.lastScan is not null
        and uj.Number = ljr.Ticket_No
)
,DupTicketTasks as (
    select
    number,
    Task,
    COUNT(Number) as NumTickets,
    MAX(PressNumber) as FirstPress
    from jobStarted_tmp_temp group by number, task
    having Count(Number) > 1)
,jobStarted_tmp as (
    select jtt.*
    from jobStarted_tmp_temp jtt
    left join 
    DupTicketTasks Dtt on 
    dtt.Number = jtt.Number and dtt.task = jtt.task
    where dtt.Number is null or (dtt.FirstPress = jtt.PressNumber)
)
,jobStarted as (
    select 
        PressNumber,
        SourceFacilityId,
        taskClassification,
        Number,
        (cumTaskEstimatedMinutes - taskEstimatedMinutes) StartTime,
        TaskMinutes,
        Task,
        jobFirstAvailable,
        Locked,
        masterRollNumber
    from jobStarted_tmp
    where 
        taskIndex = firstTaskIndex
),
masterRollJobs as (
    select  
        em.SourceEquipmentId as PressNumber, 
        js.SourceFacilityId,
        js.taskClassification, 
        sr.SourceTicketId as Number, 
        js.StartTime,
        sr.TaskMinutes, 
        sr.TaskName as Task, 
        js.jobFirstAvailable, 
        sr.IsPinned as Locked, 
        sr.masterRollNumber
    from jobStarted js
	INNER JOIN EquipmentMaster em on js.PressNumber = em.SourceEquipmentId
    inner join ScheduleReport sr on sr.EquipmentID = em.ID and js.Task = sr.TaskName and isnull(cast(js.masterRollNumber as varchar(50)), '') = isnull(sr.masterRollNumber, '')
    inner join unassignedJobs uj 
    on js.Number = uj.Number and js.PressNumber = uj.PressNumber and js.Task = uj.TaskName
    where sr.masterRollNumber is not null
),
jobsToAdd as (
    select 
        PressNumber, 
        SourceFacilityId,
        taskClassification, 
        Number, 
        0 StartTime,
        TaskMinutes, 
        Task, 
        jobFirstAvailable, 
        Locked, 
        masterRollNumber 
    from masterRollJobs mr
    where not exists (select * from jobStarted j where mr.Number = j.Number and mr.PressNumber = j.PressNumber and mr.Task = j.Task)
),
jobs as (
    select * from jobStarted
    union
    select * from jobsToAdd
),
jobsAssign_tmp as (
    select 
    *,
    sum(TaskMinutes) OVER (partition by PressNumber order by TaskMinutes) AS cumTaskMinutes
    from jobs
)
SELECT 
    PressNumber, 
    SourceFacilityId,
    Number,
    cumTaskMinutes - CAST(TaskMinutes AS INT) StartTime,
    TaskMinutes, 
    NULL changeoverMinutes,
    NULL EndTime,
    NULL fixedchangeoverMinutes,
    Task, 
    jobFirstAvailable, 
    Locked, 
    masterRollNumber,
    taskClassification
FROM jobsAssign_tmp
GO