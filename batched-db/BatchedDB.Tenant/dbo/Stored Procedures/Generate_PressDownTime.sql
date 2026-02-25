/*
Created By - Vinay Borhade
Created On - 06 Jan 2021

RUNTIMES - 
	To be configured to re run DAILY (before the min Shift Start time - 5:30 for ELCO)
	
Output - 
	TABLE PressDownTime (For each press)

External Depenancies - 
	1. Table - MasterEquipmentReference
	2. Table - ShiftCalender
	3. Table - PressDowntime
	4. Table - ShiftCalendarCurrent

STEPS - 
	1. IF PressDownTime Table Exists -> Drop PressDownTime Table
	2. CREATE TABLE PressDownTime
	3. CTE minStart_maxEnd - Get min Shifstart and max Shift End from Master Equipment Reference
	4. CTE compare - create a cross table to compare min/max Shif start/end with actual shift start/end
	5. CTE downTime_HHmm - Use 'compare' CTE to determine possible downtimes for press.
		In functional words - 
			Shop is open from 5:30 to 18:00, BUT PRESS 1 is available only between 8:00 to 15:00.
			Hence 5:30-8:00 and 15:00 to 18:00 to be conidered downtimes for all dates in the shiftCalender

	   Example -> 
			"IF Press = 1 has shift_start = 8:00" VS "Shop's min Shift Start = 5:30"
			THEN PRESS = 1 will need to be considered down from 5:30 to 8:00
			
			Similary,
			"IF Press = 1 has shift_end = 15:00" VS "Shop's max Shift End = 18:00"
			THEN PRESS = 1 will need to be considered down from 15:00 to 18:00

		For LabelTech - Additional Logic is added to refer EquipmentShiftByDay column
						to maintain shift timings by day of the week and for specific date ranges

	6. CTE shift_cal_dates - Distinct Dates from ShiftCalender 
	7. CTE press_dt - Press Downtimes for each press in HH:MM
	8. CTE orig_cpm - Existing Client Press Maintainance provided by Client in ClientPressMaintainance
	9. Insert into Table PressDownTime - 
	   a. Downtimes from orig_cpm and
	   b. Downtimes determined by CROSS JOIN of  CTE shift_cal_dates and CTE downTime_HHmm
*/ 
-----------------------------------------------------------------------

CREATE   PROCEDURE [dbo].[Generate_PressDownTime]

AS

BEGIN

	if OBJECT_ID('PressDowntimeGenerated') is not null
		DROP table PressDowntimeGenerated

	;with minStart_maxEnd as (
		select 
			convert(datetime, minShiftStart) minShiftStart,
			convert(datetime, maxShiftEnd) maxShiftEnd
		from view_Shift_MinStart_MaxEnd m
	),
	compare AS (
		select 
			mer.Press,
			FORMAT(mer.[Shift Start],'HH:mm') ShiftStart,
			FORMAT(mer.[Shift End],'HH:mm') ShiftEnd,
			FORMAT((select minShiftStart from minStart_maxEnd),'HH:mm') as minShiftStart,
			FORMAT((select maxShiftEnd from minStart_maxEnd),'HH:mm') as minShiftEnd,
			mer.TheDayName,
			case when mer.[Start Date] is null or mer.[Start Date] = '1753-01-01 00:00:00.000' then convert(date, '1900-01-01') end as [Start Date],
			case when mer.[End Date] is null or mer.[End Date] = '1753-01-01 00:00:00.000' then convert(date, '2900-12-31') end as [End Date],
			LAG([Shift End])  OVER (PARTITION BY press, [TheDayName],  [Start Date] ORDER BY [Shift Start] ) PreviousShiftEnd,
			LEAD([Shift Start])  OVER (PARTITION BY press, [TheDayName],  [Start Date] ORDER BY [Shift Start] ) NextShiftStart
		from EquipmentShiftByDay mer
		where FORMAT(mer.[Shift Start],'HH:mm') <> '00:00'
	),
	shift_cal_dates As (
		SELECT DISTINCT sc.TheDate, cbc.TheDayName
		  FROM ShiftCalender sc
		  join view_ClientBizCalendar cbc
					on sc.TheDate = cbc.TheDate
	),
	downTime_HHmm AS (
		select c.*,
			s1.TheDate,
			m1.[Default Shift Start],
			m1.[Default Shift End],
			-- check shift start from EquipmentShiftByDay for given press of matching date range
			case when c.ShiftStart > c.minShiftStart then c.minShiftStart end as StartHHmm,
			case when c.ShiftStart > c.minShiftStart then c.ShiftStart end as EndHHmm
		from compare c
		left join MasterEquipmentReference m1
		on c.Press = m1.Press
		JOIN shift_cal_dates s1 
		on c.TheDayName = s1.TheDayName
		where 
			PreviousShiftEnd is null and
			s1.TheDate between c.[Start Date] and c.[End Date] 
	
		 union

		 select c.*,
			s1.TheDate,
			m1.[Default Shift Start],
			m1.[Default Shift End],
			-- check shift start from EquipmentShiftByDay for given press of matching date range
			case when FORMAT(m1.[Default Shift Start],'HH:mm') > c.minShiftStart then c.minShiftStart end as StartHHmm,
			case when FORMAT(m1.[Default Shift Start],'HH:mm') > c.minShiftStart then FORMAT(m1.[Default Shift Start],'HH:mm') end as EndHHmm
		from compare c
		left join MasterEquipmentReference m1
		on c.Press = m1.Press
		JOIN shift_cal_dates s1 
		on c.TheDayName = s1.TheDayName
		where 
			PreviousShiftEnd is null and
			s1.TheDate not between c.[Start Date] and c.[End Date] 
	
		union

		select c.*,
				s3.TheDate,
				m3.[Default Shift Start],
				m3.[Default Shift End],
				-- check shift end from EquipmentShiftByDay for given press of matching date range
				case when c.ShiftEnd < c.minShiftEnd then c.ShiftEnd end as StartHHmm,
				case when c.ShiftEnd < c.minShiftEnd then c.minShiftEnd end as EndHHmm
			
			from compare c
			left join MasterEquipmentReference m3
			on c.Press = m3.Press
			JOIN shift_cal_dates s3 
			on c.TheDayName = s3.TheDayName
			where 
			NextShiftStart is null and
			s3.TheDate between c.[Start Date] and c.[End Date]

		union
			select c.*,
				s4.TheDate,
				m4.[Default Shift Start],
				m4.[Default Shift End],
				-- check shift end from EquipmentShiftByDay for given press of matching date range
				case when FORMAT(m4.[Default Shift End],'HH:mm') < c.minShiftEnd then FORMAT(m4.[Default Shift End],'HH:mm') end as StartHHmm,
				case when FORMAT(m4.[Default Shift End],'HH:mm') < c.minShiftEnd then c.minShiftEnd end as EndHHmm
			from compare c
			left join MasterEquipmentReference m4
			on c.Press = m4.Press
			JOIN shift_cal_dates s4 
			on c.TheDayName = s4.TheDayName
			where 
			NextShiftStart is null and
			s4.TheDate not between c.[Start Date] and c.[End Date]
	
		union

		select c.*,
				s5.TheDate,
				m5.[Default Shift Start],
				m5.[Default Shift End],
				FORMAT(PreviousShiftEnd,'HH:mm') as StartHHmm,
				c.ShiftStart as EndHHmm
			from compare c
			left join MasterEquipmentReference m5
			on c.Press = m5.Press
			JOIN shift_cal_dates s5 
			on c.TheDayName = s5.TheDayName
			where 
			PreviousShiftEnd is not null and
			s5.TheDate between c.[Start Date] and c.[End Date] 
	),
	press_dt AS (
		select Press, StartHHmm, EndHHmm, TheDayName, [Start Date], [End Date], TheDate
		from downTime_HHmm
		where StartHHmm IS NOT NULL
	),
	PressDownTimeDayName as (
		select pd.Press, pd.[Start Time], pd.[End Time],
		cbc.TheDayName
		from PressDowntime pd
		join view_ClientBizCalendar cbc
				on convert(date, pd.[Start Time]) = cbc.TheDate
		left join MasterEquipmentReference m
			on pd.Press = m.Press
	),
	dt_cross as (
		select * from PressDownTimeDayName
		UNION
		select
			Press, 
			DateAdd(Day, DateDiff(Day, 0, TheDate), StartHHmm) as [Start Time],
			DateAdd(Day, DateDiff(Day, 0, TheDate), EndHHmm) as [End Time],
			pdt.TheDayName
		from press_dt pdt

	)
	
	select 
		dt_cross.Press,
		dt_cross.[Start Time],
		dt_cross.[End Time],
		tv1.timeIndex as StartTimeReference,
		tv2.timeIndex as EndTimeReference,
		tv2.timeIndex - tv1.timeIndex as downtimeMinutes
	into PressDowntimeGenerated
	from dt_cross
	left join 
		ShiftCalendarCurrent tv1
		on dt_cross.[Start Time] = tv1.timeValue 
	left join 
		ShiftCalendarCurrent tv2
		on dt_cross.[End Time] = tv2.timeValue 
	order by dt_cross.Press, dt_cross.[Start Time], dt_cross.[End Time]

END

-- Exec Generate_PressDownTime
