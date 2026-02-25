-- Shift start date and End date is dynamically picked from "table OpenTicketTasks"


--IN dbo.OpenTicketTasks table: ASSUME CURRENT DATE = 3 MAR ->

    -- for determining shift calender start date, check oldest ticket due time 
		--IF min(TaskDueTime) = '10 MAR' > CURRENT DATE = 3 MAR --> shift calender start date = '1 MAR' (current minus 2 days)
		--IF min(TaskDueTime) = '5 JAN'  < CURRENT DATE = 3 MAR --> shift calender start date = '3 JAN' (min taskDueTime minus 2 days)

	-- for determining shift calender start date, check newest ticket due time 
		--IF max(TaskDueTime) = '10 APR' > CURRENT DATE = 3 MAR --> shift calender end date = '12 APR' (max taskDueTime plus 2 days)
		--IF max(TaskDueTime) = '10 FEB' < CURRENT DATE = 3 MAR --> shift calender end date = '4 MAR' (current plus 2 days)

	-- Overall	shift calender start date will always be < current date and 
	--			shift calender end date will always be > current date
	

CREATE   PROCEDURE [dbo].[CreateShiftCalender_Daily]
AS
BEGIN
	if OBJECT_ID('ShiftCalender') is not null
	DROP table ShiftCalender

;WITH 
	min_max_dueTime as  (
		select 
			case when min(PressDueTime) > GETDATE()-10 then GETDATE() -10
				When min(PressDueTime) < GETDATE() - 60 Then GETDATE() - 60 else min(PressDueTime) - 2 end as minDueTime,
			case when max(FinishDueTime) < GETDATE()+60 then GETDATE() + 60 else max(FinishDueTime) + 10 end as maxDueTime
		from dbo.TicketCharacteristics
		Where TicketStatus='Open' and Ship_by_Date<>'1970-01-01'
	),
	minStart_maxEnd as (
	    -- use EquipmentShiftByDay table with records for ALL days (Mon-Fri) here
		select  
			convert(datetime, minShiftStart) minShiftStart,
			convert(datetime, maxShiftEnd) maxShiftEnd,
			DateAdd(Day, DateDiff(Day, 0, (select case when minDueTime is NULL then GETDATE() -10 else minDueTime end from min_max_dueTime)), convert(datetime, minShiftStart)) as StartDate,
			DateAdd(Day, DateDiff(Day, 0, (select case when maxDueTime is NULL then GETDATE() +60 else maxDueTime end from min_max_dueTime)), convert(datetime, maxShiftEnd)) as EndDate
		from view_Shift_MinStart_MaxEnd m
	),
	src as (

		Select 
				TheDate         = CONVERT(date, RetVal),
				TheDateTime         = CONVERT(datetime, RetVal),
				TheHHMM =			FORMAT(RetVal,'HH:mm')
		from [dbo].[udf-Create-Range-Date]( (select StartDate from minStart_maxEnd) ,(select EndDate from minStart_maxEnd),'MI',1)
	),
	cbc_short as (
		select * 
		from view_ClientBizCalendar cbc
		where cbc.TheDate >= (select CONVERT(date, StartDate) from minStart_maxEnd)
		and cbc.TheDate <= (select CONVERT(date, EndDate) from minStart_maxEnd)
	)
	
	SELECT 
		src.*,
		cbc.isBizDay,
		cbc.TheDayName,
		convert(date, GETDATE()) generated_date
	INTO ShiftCalender
	FROM src
	left join 
		cbc_short cbc
		on cbc.TheDate = src.TheDate
	where 
	src.TheHHMM >= FORMAT((select minShiftStart from minStart_maxEnd),'HH:mm') 
	and src.TheHHMM <= FORMAT((select maxShiftEnd from minStart_maxEnd),'HH:mm') 
	--and cbc.isBizDay = 'Y'
	  ORDER BY TheDate
END

-- Exec CreateShiftCalender_Daily

