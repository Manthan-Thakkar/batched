-- ShiftCalendarCurrent Table is created to avoid running the view_ShiftCalendarTimeValue multiple times
-- which may cause timezero to fluctuate. TimzeZero should remain constant for the Algo run.

CREATE   PROCEDURE [dbo].[Generate_ShiftCalendarCurrent] 
AS
BEGIN
	if OBJECT_ID('ShiftCalendarCurrent') is not null
		DROP table ShiftCalendarCurrent

		;with minStart_maxEnd as (
				select 
					minShiftStart,
					maxShiftEnd
				from view_Shift_MinStart_MaxEnd m
		), 
		tz as (
			select *, 
			ROW_NUMBER() OVER(ORDER BY TheDateTime) as RowNumber
			from ShiftCalender s
			where isBiZDay = 'Y'
		),
		curr_time as (
			Select SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time' as currtime
		),
		next_biz_day as (
			select top 1 cbc.TheDate as nextBizDay from view_ClientBizCalendar cbc
			where cbc.TheDate > (select cast(currtime as date) from curr_time as currtime)
			and cbc.isBizDay = 'Y'
			order by cbc.TheDate
		),
		tzero as (
			select 
				case when 
						cast(c.currtime as date) not in (select distinct TheDate from view_ClientBizCalendar where isBizDay = 'Y') OR
						 (cast(c.currtime as date) in (select distinct TheDate from view_ClientBizCalendar where isBizDay = 'Y')
							AND FORMAT((select currtime from curr_time),'HH:mm') > (select maxShiftEnd from minStart_maxEnd))
					 then
						DateAdd(Day, DateDiff(Day, 0, (select cast(nextBizDay as smalldatetime) from next_biz_day)), (select minShiftStart from minStart_maxEnd))
					 else 
						case when (cast(c.currtime as date) in (select distinct TheDate from view_ClientBizCalendar where isBizDay = 'Y')
							AND FORMAT((select currtime from curr_time),'HH:mm') < (select minShiftStart from minStart_maxEnd))
							then DateAdd(Day, DateDiff(Day, 0, (select cast(currtime as smalldatetime) from curr_time)), (select minShiftStart from minStart_maxEnd))
							else (select cast(currtime as smalldatetime) from curr_time)
						end 
				end as tzero_time 
			from curr_time c
		),
		tzero_rownum as (
			select RowNumber from tz where cast(TheDateTime as smalldatetime) = (select cast(tzero_time as smalldatetime) from tzero)
		)

		select 
			TheDateTime as timeValue,
			RowNumber - (select RowNumber from tzero_rownum)  as timeIndex
		into ShiftCalendarCurrent
		from tz

END

-- exec Generate_ShiftCalendarCurrent
