CREATE   VIEW [dbo].[view_ClientBizCalendar]
AS

select 
    c.*,
	h.Holiday,
	--cdo.Type,
	case when h.Holiday is NULL 
	--AND cdo.Type is NULL 
	then 'Y' ELSE 'N' end as isBizDay

from
    Calendar c 
LEFT JOIN
	(select * from Holidays) as h
	ON c.TheDate = h.Date

--LEFT JOIN 
--	(select * from ClientDaysOff) as cdo
--	on c.TheDayName = cdo.TheDayName
