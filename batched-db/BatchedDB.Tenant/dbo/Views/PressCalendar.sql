CREATE   View [dbo].[PressCalendar]

AS

with calendarcross as (Select scc.*, cast(scc.timeValue as Date) as ConvertedDate, mer.Press
						From ShiftCalendarCurrent scc
						Cross Join MasterEquipmentReference mer
						Where scc.timeIndex >= 0 and mer.[Available for Scheduling?]='Yes'
					)
,

calendarjoin as (
Select cc.*, esbd.Press as [ShiftPress], pd.Press as DowntimePress, pu.Press as UptimePress, Case When timeValue < GetDate() Then 0 Else 1 End as Minute, Case When (esbd.Press IS NULL AND pu.Press IS NULL) OR pd.Press IS NOT NULL Then 1 Else 0 End As Downtime
From calendarcross cc
Left Join Calendar c on cc.ConvertedDate=c.TheDate
Left Join EquipmentShiftByDay esbd on cc.Press=esbd.Press 
									and c.TheDayName=esbd.TheDayName 
									and cc.ConvertedDate >= cast(Case When esbd.[Start Date]='1753-01-01 00:00:00.000'
																	Then GETDATE()-10
															Else esbd.[Start Date]
															End as Date)
									and cc.ConvertedDate <= cast(Case When esbd.[End Date] ='1753-01-01 00:00:00.000'
																	Then GETDATE()+90
															Else esbd.[End Date]
															End as Date)
									and CONVERT(time, cc.timeValue) >= CONVERT(time, esbd.[Shift Start])
									and CONVERT(time, cc.timeValue) < CONVERT(time, esbd.[Shift End])
Left Join PressDowntime pd on cc.Press=pd.Press and cc.timeValue>=pd.[Start Time] and cc.timeValue<=pd.[End Time]
Left Join PressUpTime pu on cc.Press=pu.Press and cc.timeValue>=pu.[Start Time] and cc.timeValue<=pu.[End Time]
Where cc.ConvertedDate <= DATEADD(d, 90, getdate()))
--Where (esbd.Press IS NOT NULL OR pu.Press IS NOT NULL) and pd.Press IS NULL)-- and cc.ConvertedDate <= DATEADD(d, 180, getdate()))

, cumulativedowntime as (

Select Press as PressNumber, timeValue, timeIndex, timeIndex - sum(Downtime) OVER (PARTITION BY Press Order by timeIndex ASC) as adjustedTimeIndex, Downtime as downtime
From calendarjoin)

Select PressNumber, timeValue, timeIndex, adjustedTimeIndex
From cumulativedowntime
Where downtime = 0
