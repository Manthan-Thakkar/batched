CREATE PROCEDURE [dbo].[proc_AllOpenTicketTasks_Table]
AS 
BEGIN -- begin procedure

	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	
	-- clear out the All Open Ticket Tasks Table, and load the new data
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'AllOpenTicketTasks_Table')
			BEGIN

				
					print 'DROP table AllOpenTicketTasks_Table...';
					DROP table AllOpenTicketTasks_Table;
					--dbo.AllOpenTicketTasks_Table

			END -- end the clause to truncate old data
	


		Drop table if exists #openTicketTasks
		Drop table if exists #taskExpansionDueTimes
		Drop table if exists #purchaseorderDateReq

;
			select t.[Number]
			  ,tm.[ID] as ID
			  ,t.[CustomerNum]
			  ,t.[CustomerName]
			  ,t.[ShipVia]
			  ,t.[OrderDate]
			  ,t.[ArtStat]
			  ,t.[ProofStat]
			  ,t.[PlateStat]
			  ,t.[ToolStat]
			  ,t.[PressStat]
			  ,t.[ArtDone]
			  ,t.[ProofDone]
			  ,t.[PlateDone]
			  ,t.[ToolsIn]
			  ,t.[StockIn]
			  ,t.[EstPackHrs]
			  ,t.[ActQuantity]
			  ,t.FinishType
			  ,t.MainTool
			  ,t.[Is_Ink_In]
			  ,t.[Ink_Status]
			  ,t.[ActualBillings_NetOfSalesTax]
			  ,t.[ActualRewindingHours]
			  ,t.[ActualTotalHours]
			  ,t.[ActualTotalLaborCosts]
			  ,t.[ActStockCost]
			  ,t.[ActualTotalPOCosts]
			  ,t.[ActualTotalMatAndFreightCost]
			  ,t.[ActTotalCost]
			  ,t.[EstStockCost]
			  ,t.[DateShipped]
			  ,t.[OTSName]
			  ,t.[ITSName]
			  ,t.[EntryDate]
			  ,t.[GeneralDescr]
			  ,t.[Notes]
			  ,t.[FinishStat]
			  ,t.[MiscCharge]
			  ,t.[NoAcross]
			  ,t.[POTotal]
			  ,t.[NoLabAcrossFin]
			  ,t.[Press]
			  ,t.[RowSpace]
			  ,t.[Ship_by_Date]
			  ,t.[LabelsPer_]
			  ,t.[CoreSize]
			  ,t.[SizeAround]
			  ,t.[StockNum1]
			  ,t.[StockWidth1]
			  ,t.[StockNum2]
			  ,t.[Stockwidth2]
			  ,t.[Priority]
			  ,t.[StockNum3]
			  ,t.[StockWidth3]
			  ,t.[TicketType]
			  ,t.[TicQuantity]
			  ,t.[StockDesc2]
			  ,t.[StockDesc3]
			  ,t.[TicketStatus]
			  ,t.[EstFootage] 
			  ,t.[ActFootage]
			  ,t.[EstMRHrs]
			  ,t.[EstWuHrs]
			  ,t.[EstRunHrs]
			  ,t.[EstPressTime]
			  ,t.[EstFinHrs]      
			  ,t.[EstPostPressHours]
			  ,t.[EstTotal]
			  ,t.[RewindEquipNum]
			  ,t.[CSA]
			  ,t.[UL]
			  ,t.[ConsecNo]
			  ,t.[Shape]
			  ,t.[NoArounPlate]
			  ,t.[ColSpace]
			  ,t.[Est_SetupFootage]
			  ,t.[Est_SpoilFootage]
			  ,t.[OverRun]
			  ,t.[LabelRepeat]
			  ,t.[OutsideDiameter]
			  ,t.[Equip_ID]
			  ,t.[Equip_MakeReadyHours]
			  ,t.[Equip_WashUpHours]
			  ,t.[Equip_EstRunHrs]
			  ,t.[Equip_EstTime]
			  ,t.[Equip3_ID]
			  ,t.[Equip3_MakeReadyHours]
			  ,t.[Equip3_WashUpHours]
			  ,t.[Equip3_EstRunHrs]
			  ,t.[Equip3_EstTime]
			  ,t.[Equip4_ID]
			  ,t.[Equip4_MakeReadyHours]
			  ,t.[Equip4_WashUpHours]
			  ,t.[Equip4_EstRunHrs]
			  ,t.[Equip4_EstTime]
			  ,t.[Tool2Descr]
			  ,t.[Tool3Descr]
			  ,t.[Tool4Descr]
			  ,t.[Tool5Descr]
			  ,t.[Tab]
			  ,t.[Backstage_ColorStrategy]
			  ,t.[StockDesc1]
			  ,t.[Roto_Quote_Number]
			  ,t.[ShrinkSleeve_LayFlat]
			  ,t.[ShrinkSleeve_CutHeight]
			  ,t.[ShrinkSleeve_OverLap]
			  ,t.[PressDone]
			  ,t.[Equip_Status]
			  ,t.[Equip_Done]
			  ,t.[Due_on_Site_Date]
			  ,t.[Equip3_Status]
			  ,t.[Equip3_Done]
			  ,t.[Equip4_Status]
			  ,t.[Equip4_Done]
			  ,t.[FinishDone]
			  ,t.[Backstage_SmartMarkSet]
			  ,t.[SizeAcross]
			  ,t.[FinalUnwind]
			  ,t.[Use_TurretRewinder]
			  ,t.[StockTicketType]
			  ,t.[PriceMode]
			  ,t.[CustPONum]
			  ,t.[ShipAttn]
			  ,t.[ShipLocation]
			  ,t.[ShipAddr1]
			  ,t.[ShipAddr2]
			  ,t.[ShipCity]
			  ,t.[ShipSt]
			  ,t.[ShipZip]
			  ,t.[ShipCountry]
			  ,t.[Ship_Address_ID]
			  ,t.[ShippingInstruc]
			  ,t.[ShippingStatus]
			  ,t.[ToolNo2]
			  ,t.[ToolNo3]
			  ,t.[ToolNo4]
			  ,t.[ToolNo5]
			  ,t.[Turnbar]
			  ,t.[Pinfeed]
			  ,t.[EntryTime]
			  ,t.[ModifyDate]
			  ,t.[ModifyTime]
			  ,em.WorkcenterName as pressWorkCenter
			  ,t.NoPlateChanges
			  ,em2.SourceEquipmentId as TicketPressNumber
			  ,tt.TaskName as Task
			  ,em2.WorkCenterName as TaskWorkCenter
			  ,tt.EstMaxDueDateTime as TasKDueTime
			  ,tt.Sequence
			  ,tt.IsComplete as TaskDone
			  ,tt.EstTotalHours as TaskEstimatedHours
			  ,tt.EstMeters as TaskEstimatedMeters
			  ,tt.DoublePassJob
			into #openTicketTasks
			from TicketTask tt
				Left Join TicketMaster tm on tm.ID=tt.TicketId
				Left Join Ticket t on tm.SourceTicketId=t.Number
				left join EquipmentMaster em on em.SourceEquipmentID = t.Press
				Left Join EquipmentMaster em2 on tt.OriginalEquipmentId = em2.ID

Declare @currenttime datetime;

Select @currenttime = SYSDATETIMEOFFSET() AT TIME ZONE (select top 1 TimeZone From [batched].[dbo].[Tenant] where ID = (select top 1 tenantID from EquipmentMaster))

;WITH masterEquipmentReference as (

Select em.Name, em.AvailableForPlanning, em.Description, em.AvailableForScheduling, WorkCenterName as Workcenter
	From EquipmentMaster em)
	
, timecardScans as(

	/** check if that ticket has started in a specific work center based on equipment reference **/

	select 
		timecard.Ticket_No 
		, mer.WorkCenter
		, MIN(dateadd(ss, DATEPART(hour, STime)*60*60 + DATEPART(Minute, STime) * 60 + DATEPART(second, STime), CAST(timecard.SDate as Datetime))) as firstWorkCenterScan
		, MAX(dateadd(ss, DATEPART(hour, STime)*60*60 + DATEPART(Minute, STime) * 60 + DATEPART(second, STime), CAST(timecard.EDate as Datetime))) as lastWorkCenterScan
		, SUM((DATEPART(hour, Elapsed)*60*60 + DATEPART(Minute, Elapsed) * 60 + DATEPART(second, Elapsed))/60.0) as totalElapsed 
		, SUM(Labels_Act_Net) as Labels_Act_Net
	from 
		timecard
	LEFT JOIN
		masterEquipmentReference mer 
		ON mer.Name = timecard.PressNo
	WHERE 
		Ticket_No IN (SELECT DISTINCT Number from #openTicketTasks)
	GROUP BY 
		timecard.Ticket_No 
		, mer.WorkCenter

), taskTime as (

	select tcs.firstWorkCenterScan
		, CASE WHEN tcs.firstWorkCenterScan IS NULL THEN 0 ELSE 1 END as TaskStarted
		, tcs.Labels_Act_Net as Labels_Act_Net_Timecard
		, tex.*
	from 
		#openTicketTasks tex 
	LEFT JOIN 
		timecardScans tcs 
		ON tex.Number = tcs.Ticket_No
		AND tex.TaskWorkCenter = tcs.WorkCenter
)
			select 
				 tt.*
			into #taskExpansionDueTimes 
			from 
				taskTime tt	

		Select 
				[purchaseorder].[ORDERSTOCKNUM], MIN(ISNull(DateReq, '1/1/2100')) as DateReq
			into #purchaseorderDateReq
			From [dbo].[purchaseorder]
			Where CLOSED=0 
				AND POTYPE='Stock'
				AND (DateReq IS NULL OR DateReq >= DATEADD(DAY, -60, getdate()))
			Group by [purchaseorder].[ORDERSTOCKNUM]

		;with masterEquipmentReference as (

			Select em.Name, em.AvailableForPlanning, em.Description, em.AvailableForScheduling, wct.Name as Workcenter
						From EquipmentMaster em
						INNER JOIN batched.dbo.WorkCenterType wct on em.WorkCenterTypeId=wct.ID

		), stockinsubs as (
			Select 
				tt.number,
				MIN(DateReq) as DateReq
				from #taskExpansionDueTimes tt
				left join StockSubstitutes ss on ss.StockNum = tt.StockNum2
				left join #purchaseorderDateReq PO on [ORDERSTOCKNUM]=tt.StockNum2 OR ss.StockSubstitute =[ORDERSTOCKNUM]
				group by tt.Number
		)
		, stock1insubs as (
			Select 
				tt.number,
				MIN(DateReq) as DateReq
				from #taskExpansionDueTimes tt
				left join StockSubstitutes ss on ss.StockNum = tt.StockNum1
				left join #purchaseorderDateReq PO on [ORDERSTOCKNUM]=tt.StockNum1 OR ss.StockSubstitute =[ORDERSTOCKNUM]
				group by tt.Number)
		, stock3insubs as (
			Select 
				tt.number,
				MIN(DateReq) as DateReq
				from #taskExpansionDueTimes tt
				left join StockSubstitutes ss on ss.StockNum = tt.StockNum3
				left join #purchaseorderDateReq PO on [ORDERSTOCKNUM]=tt.StockNum3 OR ss.StockSubstitute =[ORDERSTOCKNUM]
				group by tt.Number)
		, StockInText as (
			Select 
				tt.number,
				MIN(Case When tt.StockIn='Ord' 
						Then ISNULL(Case When sis.DateReq = '1/1/2100' Then 'Ord No Date' Else format(sis.DateReq, 'MM/dd/yyyy') End , 'Ord No PO')
					Else tt.StockIn
				End) As [StockInText]
				from #taskExpansionDueTimes tt
				left join stockinsubs sis on tt.Number=sis.Number
				group by tt.Number
			)
			,
			Stock1InText as (
				Select 
					tt.number,
					MIN(Case When tt.StockIn='Ord' and tt.StockNum1 <> '' Then ISNULL(Case When sis.DateReq = '1/1/2100'  Then 'Ord No Date' Else format(sis.DateReq,'MM/dd/yyyy') End , 'Ord No PO')
							Else ''	 End) As [Stock1InText]
				FROM #taskExpansionDueTimes tt
				left join stock1insubs sis on tt.Number=sis.Number
				GROUP BY tt.Number
			)
			,
			Stock3InText as (
			Select 
				tt.number,
				MIN(Case When tt.StockIn='Ord' and tt.StockNum3 <> '' Then ISNULL(Case When sis.DateReq = '1/1/2100'  Then 'Ord No Date' Else format(sis.DateReq,'MM/dd/yyyy') End , 'Ord No PO')
					Else ''	End) As [Stock3InText]
			from #taskExpansionDueTimes tt
			left join stock3insubs sis on tt.Number=sis.Number
			GROUP BY tt.Number
			)
			,
			ToolPurchaseOrder as (
				Select 
					[purchaseorder].[TOOLNUM], MIN(DateReq) as DateReq
				From [dbo].[purchaseorder]
				Where CLOSED=0 
					AND POTYPE='Tool' 
					AND DateReq IS NOT NULL
				Group by [purchaseorder].[TOOLNUM]
			),
			ToolStat as (
				Select  tt.Number,
					MIN(Case When ToolsIn=1 Then 'Yes'
					Else  ISNULL(format(TPO.DateReq, 'MM/dd/yyyy'), 'No') End) as [ToolStatText]
				from #taskExpansionDueTimes tt
				left join ToolPurchaseOrder TPO on TPO.ToolNum = tt.MainTool
				group by tt.Number
			)

			select  tt.*
				,em.SourceEquipmentId as [ScheduledPress]
				,ms.StartsAt StartTime
				,ms.EndsAt EndTime
				,ms.IsPinned Locked
				--Below are fields added in PBI as calculated columns that I'm pushing back to SQL --
				,DATEDIFF(d, tt.OrderDate, GETDATE()) as [DaysSinceOrdered]
				,sit.StockInText
				,s1it.Stock1InText
				,s3it.Stock3InText
				,Case When tt.StockIn='In' Then 1
				When tt.StockIn='Ord' Then -1
				Else 0
				End As [StockInStatus]
				,Case When em.SourceEquipmentId IS NULL and TaskDone=0 Then 'Unscheduled'
				Else 'Scheduled'
				End as [TicketScheduleStatus]
				, Case When em.SourceEquipmentId IS NULL Then 1
				Else 0
				End as [TicketStatusValue]
				, Case When TicketStatus = 'Hold' OR TicketStatus = 'Credit Hold' Then 1
				Else 0
				End as [HoldStatusValue]
				, Case When ArtDone=1 Then 'Yes' Else 'No' End as [ArtStatText]
				, Case When ProofDone=1 Then 'Yes' Else 'No' End as [ProofStatText]
				, Case When PlateDone=1 Then 'Yes' Else 'No' End as [PlateStatText]
				,toolStat.ToolStatText
				, Case When Is_Ink_In=1 Then 'Yes' Else 'No' End as [InkStatText]
				, Case When TaskDone=1 Then -2
						When ljr.Ticket_No IS NOT NULL Then 4
						When [ship_by_date] IS NULL Then -1
						When @currenttime> tt.TaskDueTime
									OR
									ms.EndsAt> tt.TaskDueTime Then -1
						When   datediff(hh, @currenttime, tt.TaskDueTime) < 4 
							
									OR
									datediff(hh, ms.EndsAt, tt.TaskDueTime) < 4
									Then 0
						When ms.EndsAt IS NULL Then 3
						When @currenttime>ms.EndsAt Then 1
						Else 2 
						End as [TaskStatusValue]
				, Case When TaskDone=1 Then 'Complete'
						When ljr.Ticket_No IS NOT NULL Then 'On Press'
						When [ship_by_date] IS NULL Then 'Late'
						When ms.EndsAt IS NULL Then 'Unscheduled'
						When @currenttime > tt.TaskDueTime
									OR
									ms.EndsAt> tt.TaskDueTime Then 'Late'
						When   datediff(hh, @currenttime, tt.TaskDueTime) < 4 
							
									OR
									datediff(hh, ms.EndsAt, tt.TaskDueTime) < 4
									Then 'At Risk'
						When @currenttime>ms.EndsAt Then 'Behind'
						Else 'On Track' 
						End as [TaskStatusText]
				, ms.TaskMinutes
				, ms.changeoverMinutes
				, Case When FinishType Like 'Fan%' Then 'Fanfold'
					Else (Select Top (1) em.Description
						From dbo.ScheduleReport s
						Left Join  EquipmentMaster em on s.EquipmentId=em.ID
						Where s.SourceTicketId=tt.Number and s.TaskName in ('Rewinder', 'Sheeter')
						Order by StartsAt Desc)
					End as [ScheduledRewinder]
				,Case When (Select Top (1) s.EquipmentId
						From dbo.ScheduleReport s
						Where s.SourceTicketId=tt.Number --and s.Task in ('Rewinder')
						Order by StartsAt Desc) = ms.EquipmentId Then 1 Else 0 End as [LastScheduledMachine]
				, (Select Top(1) em.SourceEquipmentId
						From dbo.ScheduleReport s
						Left Join  EquipmentMaster em on s.EquipmentId=em.ID
						Where s.SourceTicketId=tt.Number and em.WorkCenterName like '%finish%' Order by s.EndsAt ASC) as [ScheduledDigicon]
				, CAST(ms.StartsAt as Date) as [ScheduledDate]
				, CAST(ms.EndsAt as Date) as [ScheduledEndDate]
				, Case When TicketStatus = 'Done' Then Ship_by_Date
					When Ship_by_Date < GETDATE() OR Ship_by_Date IS NULL OR Ship_by_Date='1970-01-01' Then CAST(GETDATE() as Date)
					Else Ship_by_Date
					End as [Updated Due Date]
				, Case When em.SourceEquipmentId IS NULL Then Case When tt.TicketPressNumber='OMEGA 1' Then 'SRI 2019'
													Else tt.TicketPressNumber
													End
					Else em.SourceEquipmentId
					End
				as [Planning Press]
				, Case When tt.Press in ('Series 3', 'AB Graphic')
							Then 'Digicon First'
						Else 'Normal'
					End as [Digicon Job Type]
				, Case When (SELECT COUNT(t .TaskDone)
											FROM    #taskExpansionDueTimes t
											WHERE t .Sequence < tt.Sequence AND t .TaskDone = 0 AND t .Number = tt.Number) > 0 THEN 2 ELSE ISNULL(mrr.EvenOdd, 0) END AS [Unfinished Prior Steps Flag]
				, (Select Top (1) s.PressNumber
					From dbo.masterSchedule s
					Where s.Number=tt.Number and s.StartTime < ms.StartsAt
					Order by Starttime Desc) as [PriorScheduledPress]
				, CAST(ms.CreatedOn as DATETIME) as [runDate] -- Added based on Dan's fix for Algo Failure Notification on 10/12 - Kevin M (10/12)
				, Case When tt.Priority like '%Urgent%' Then 1
				Else 0
				End as [PriorityFlag]
				, ms.masterRollNumber
				, Case when ms.masterRollNumber IS NOT NULL Then 1
				Else 0
				End as [MasterRollFlag]
				,mrr.[MasterRollRank]
				,mrr.[EvenOdd]
				,Case When ir.Number IS NULL Then 'Tasks Feasible'
				Else 'Infeasible Tasks'
				End as FeasibilityCheck
				,Case When ir.Number IS NULL Then 1
				Else 0
				End as FeasibilityCheckValue
				, Case When ms.SourceTicketId IS NULL Then 
						tt.TaskEstimatedHours
						Else (ms.TaskMinutes + ms.changeoverMinutes)/60.0
						End as TaskScheduledHours
						,Case When tt.ArtDone = 1
						AND tt.ProofDone = 1
						AND tt.PlateDone = 1
						AND (tt.ToolsIn = 1 OR (tt.ToolsIn = 0 and mer.Workcenter Like '%finishing%'))
						AND tt.StockIn = 'In'
			Then 'Production Ready'
			Else 'Open Prepress Action'
			End 
			As ProductionReadiness
			, tav1.Value as Colors
			, cast(tav2.Value as decimal(10,2)) as NumberofPlateChanges
			, ts.CustomerRankScore*ts.DueDateScore*ts.PriorityScore*ts.RevenueScore as ticketPoints
			,csl.Locations as SubstrateLocation
			,Case when tt.ActQuantity > tt.TicQuantity Then 0 Else tt.TicQuantity - tt.ActQuantity End as [Remaining Quantity]
			, Case When tt.NoLabAcrossFin = 0 THEN 1.0 ELSE tt.NoLabAcrossFin END * (tt.SizeAcross + tt.ColSpace) as [CoreWidth]
			, convert(decimal(15,2 ), ceiling(Case when tt.ActQuantity > tt.TicQuantity Then 0
				WHEN tt.[LabelsPer_] = 0 THEN NULL
				WHEN tt.PriceMode = 'Rolls' Then tt.TicQuantity - tt.ActQuantity
				ELSE (tt.TicQuantity - tt.ActQuantity)*1.0 / (tt.[LabelsPer_])-- * CASE WHEN ots.NoLabAcrossFin = 0 THEN 1.0 ELSE ots.NoLabAcrossFin END)
				End)) as NumberofRemainingCores
			, try_convert(decimal(10,5), CASE 
			When tt.PriceMode = 'Rolls' Then TicQuantity
			WHEN tt.[LabelsPer_] = 0 THEN NULL
			ELSE tt.TicQuantity*1.0 / nullif(tt.[LabelsPer_], 0) --* CASE WHEN ots.NoLabAcrossFin = 0 THEN 1.0 ELSE ots.NoLabAcrossFin END)
			END) as numberOfFinishedRolls
				,@currenttime as [Last Refresh Time]
			into AllOpenTicketTasks_Table
			from 
				#taskExpansionDueTimes tt
				Left Join dbo.ScheduleReport ms on ms.SourceTicketID=tt.Number and ms.TaskName=tt.Task
				Left Join EquipmentMaster em on ms.EquipmentId=em.ID
				Left Join dbo.view_masterrollrank mrr on em.SourceEquipmentId=mrr.PressNumber and ISNULL(ms.Masterrollnumber, ms.SourceTicketId)=mrr.masterRollNumber and ms.TaskName=mrr.Task
				Left Join dbo.InfeasibleRoutes ir on ir.Number=tt.Number
				Left Join dbo.LastJobsRun ljr on tt.Number=ljr.Ticket_No and ljr.PressNo=em.SourceEquipmentId
				Left Join StockInText sit on sit.Number = tt.Number
				Left Join Stock1InText s1it on s1it.Number = tt.Number
				Left Join Stock3InText s3it on s3it.Number = tt.Number
				Left Join ToolStat toolStat on toolStat.Number = tt.Number
				Left Join CurrentStockLocations csl on tt.StockNum2 = csl.StockNum and tt.StockWidth2 = csl.Width
				Left Join TicketMaster tm on tt.Number=tm.SourceTicketID
				Left Join TicketAttributeValues tav1 on tav1.TicketID = tm.ID and tav1.Name = 'Colors'
				Left Join TicketAttributeValues tav2 on tav2.TicketID = tm.ID and tav2.Name = 'NumPlateChanges'
				Left Join masterEquipmentReference mer on tt.Equip_ID=mer.Name
				Left Join TicketScore ts on ts.TicketID = tm.ID


		print 'COMPLETE!';

		IF XACT_STATE() > 0 COMMIT TRANSACTION
	
	END TRY

	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
	END CATCH
END -- end procedure

--exec proc_AllOpenTicketTasks_Table