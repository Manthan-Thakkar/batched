/*
CREATE   VIEW [dbo].[masterScheduleView]
AS

select 
	otr.Number 
	, otr.CustomerNum
	, otr.CustomerName 
	, otr.ShipVia
	, otr.GeneralDescr
	, otr.Notes
	, otr.OrderDate
	, otr.EntryDate
	, otr.Ship_by_Date
	, otr.Due_on_Site_Date
	, otr.DateShipped
	, otr.OTSName
	, otr.ITSName
	, otr.StockNum1
	, otr.StockNum2
	, otr.StockWidth2
	, otr.Stock2PressGrouping
	, otr.StockNum3
	, otr.MainTool
	, otr.EstFootage
	, otr.LabelsPer_
	, otr.numberOfFinishedRolls
	, otr.numberOfLeftoverRolls
	, otr.CoreSize
	, otr.OutsideDiameter
	, otr.FinalUnwind
	, otr.HotFoil
	, otr.Screen 
	, otr.Embossing
	, otr.Laminate
	, otr.InlineSheeter
	, otr.PMSFlexo
	, otr.Stock2_LinerCaliper
	, otr.pressWorkCenter
	, otr.equipWorkCenter
	, otr.equip3WorkCenter
	, otr.equip4WorkCenter
	, otr.rewinderWorkCenter
	, otr.TaskWorkCenter
	, ms.Task
	, ms.PressNumber
	, otr.TaskDone
	, otr.TaskStarted
	, ms.StartTime as ScheduleStartTime
	, ms.TaskMinutes
	, ms.changeoverMinutes
	, ms.EndTime as ScheduleEndTime
	, ms.Locked
from 
	dbo.masterSchedule ms
LEFT JOIN
	dbo.view_openTicketRoutes otr  
	ON otr.Number = ms.Number 
	AND otr.PressNumber = ms.PressNumber
	AND otr.Task = ms.Task 
GO  */