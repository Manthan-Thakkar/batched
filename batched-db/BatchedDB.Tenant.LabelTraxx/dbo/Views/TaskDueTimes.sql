CREATE   VIEW [dbo].[TaskDueTimes]
AS 

with tickets as(
	Select Number, CONVERT(DATETIME,CONVERT(VARCHAR,[Ship_by_Date]) + ' ' +
			CASE 
				WHEN ShipVia LIKE '%Same Day%' Then '10:00:00'
				WHEN ShipVia LIKE '%ROI - Overnight%' Then '16:00:00'
				ELSE '12:30:00'
			END) as ShipTime
		, EstFinHrs
		, Equip4_EstTime
		, Equip3_EstTime
		, Equip_EstTime
		, EstPressTime
	From Ticket
	Where TicketStatus='Open'
	)

, finishduetime as (

	Select *
			, Case When datepart(WEEKDAY, dateadd(MINUTE, (EstFinHrs*60.0+60)*-1, ShipTime)) = 1 Then DATEADD(HOUR, -48, dateadd(MINUTE, EstFinHrs*60.0+60, ShipTime))
				When datepart(WEEKDAY, dateadd(MINUTE, (EstFinHrs*60.0+60)*-1, ShipTime)) = 7 Then DATEADD(HOUR, -24, dateadd(MINUTE, EstFinHrs*60.0+60, ShipTime))
				Else dateadd(MINUTE, (EstFinHrs*60.0+60)*-1, ShipTime)
				End as FinishDueTime
	From tickets)

, Equip4DueTime as 
			
			(Select *
			, Case 
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip4_EstTime*60.0+60)*-1, FinishDueTime)) = 1 Then DATEADD(HOUR, -48, dateadd(MINUTE, Equip4_EstTime*60.0+60, FinishDueTime))
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip4_EstTime*60.0+60)*-1, FinishDueTime)) = 7 Then DATEADD(HOUR, -24, dateadd(MINUTE, Equip4_EstTime*60.0+60, FinishDueTime))
				Else dateadd(MINUTE, (Equip4_EstTime*60.0+60)*-1, FinishDueTime)
				End as Equip4DueTime
			From finishduetime)

, Equip3DueTime as 
			
			(Select *
			, Case 
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip3_EstTime*60.0+60)*-1, Equip4DueTime)) = 1 Then DATEADD(HOUR, -48, dateadd(MINUTE, Equip3_EstTime*60.0+60, Equip4DueTime))
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip3_EstTime*60.0+60)*-1, Equip4DueTime)) = 7 Then DATEADD(HOUR, -24, dateadd(MINUTE, Equip3_EstTime*60.0+60, Equip4DueTime))
				Else dateadd(MINUTE, (Equip3_EstTime*60.0+60)*-1, Equip4DueTime)
				End as Equip3DueTime
			From Equip4DueTime)

, EquipDueTime as 
			
			(Select *
			, Case 
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip_EstTime*60.0+60)*-1, Equip3DueTime)) = 1 Then DATEADD(HOUR, -48, dateadd(MINUTE, Equip_EstTime*60.0+60, Equip3DueTime))
				When datepart(WEEKDAY, dateadd(MINUTE, (Equip_EstTime*60.0+60)*-1, Equip3DueTime)) = 7 Then DATEADD(HOUR, -24, dateadd(MINUTE, Equip_EstTime*60.0+60, Equip3DueTime))
				Else dateadd(MINUTE, (Equip_EstTime*60.0+60)*-1, Equip3DueTime)
				End as EquipDueTime
			From Equip3DueTime)
			
			Select *
			, Case 
				When datepart(WEEKDAY, dateadd(MINUTE, (EstPressTime*60.0+60)*-1, EquipDueTime)) = 1 Then DATEADD(HOUR, -48, dateadd(MINUTE, EstPressTime*60.0+60, EquipDueTime))
				When datepart(WEEKDAY, dateadd(MINUTE, (EstPressTime*60.0+60)*-1, EquipDueTime)) = 7 Then DATEADD(HOUR, -24, dateadd(MINUTE, EstPressTime*60.0+60, EquipDueTime))
				Else dateadd(MINUTE, (EstPressTime*60.0+60)*-1, Equip3DueTime)
				End as PressDueTime
			From EquipDueTime
