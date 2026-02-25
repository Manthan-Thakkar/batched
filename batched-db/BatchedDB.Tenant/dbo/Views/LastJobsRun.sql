CREATE VIEW LastJobsRun
AS 

with tc as (

	/** Calculate a DateTime value for latest scan **/

	select
		tci.*
		, StartedOn as StartDateTime -- to adjust time stored as integer in DB
		, (DATEPART(hour, ElapsedTime)*60*60 + DATEPART(Minute, ElapsedTime) * 60 + DATEPART(second, ElapsedTime))/60.0 as minutesElapsed
	from 
		TimecardInfo tci 
	WHERE 
		-- only focus on scans in last 15 days
		--tc.WorkOperation = 'Run'
		 StartedOn > DATEADD(day,-15,GETDATE())

		--AND DATEPART(minute, Elapsed) < (16*60) 
)

 
, ticketsToConsider as (

	select 
		tm.SourceTicketId
		, tm.Press
		, tm.EquipId
		, tm.Equip3Id
		, tm.Equip4Id
		, tm.RewindEquipNum
		, tm.EstTime
		, tm.EquipEstTime
		, tm.Equip3EstTime
		, tm.Equip4EstTime
		, tm.EstFinHrs
	from 
		TicketMaster tm
	WHERE 
	OrderDate >= DATEADD(year,-1,GETDATE())
	--AND TicketType NOT IN (0, 5)

 

)

 
, latestRunTime as (
	
	/** Find latest scan for each press **/

	select
		SourceEquipmentId as PressNo 
		, MAX(StartDateTime) as MaxStartDateTime
	from
		tc
	group by 
		SourceEquipmentId

)

	/** Find latest ticket run on each machine, load key attributes to identify possible changeovers **/
, finalcheck as (select 
		Cast(lrt.PressNo as nvarchar(255)) as PressNo
		, cast(tc.SourceTicketId as nvarchar(255)) as Ticket_No
		,CASE 
			WHEN CAST(lrt.PressNo as varchar(10)) = CAST(tkc.Press as varchar(10)) THEN tkc.EstTime
			WHEN CAST(lrt.PressNo as varchar(10)) = CAST(tkc.EquipId as varchar(10)) THEN tkc.EquipEstTime
			WHEN CAST(lrt.PressNo as varchar(10)) = CAST(tkc.Equip3ID as varchar(10)) THEN tkc.Equip3EstTime
			WHEN CAST(lrt.PressNo as varchar(10)) = CAST(tkc.Equip4ID as varchar(10)) THEN tkc.Equip4EstTime
			WHEN CAST(lrt.PressNo as varchar(10)) = CAST(tkc.RewindEquipNum as varchar(10)) THEN tkc.EstFinHrs
			ELSE 0 
			END as TaskEstimatedHours
		, lrt.MaxStartDateTime
		, tc.minutesElapsed
		, row_number() OVER (Partition by lrt.PressNo ORder by lrt.MaxStartDateTime DESC) as RowNumber
	from 
		latestRunTime lrt 
	INNER JOIN 
		tc
		ON lrt.PressNo = tc.SourceEquipmentId
		AND lrt.MaxStartDateTime = tc.StartDateTime
	INNER JOIN 
		ticketsToConsider tkc 
		ON tc.SourceTicketId = tkc.SourceTicketId)
		
Select fc.PressNo
		, fc.Ticket_No
		, fc.TaskEstimatedHours
		, fc.MaxStartDateTime
		, fc.minutesElapsed
From finalcheck fc
Where RowNumber = 1