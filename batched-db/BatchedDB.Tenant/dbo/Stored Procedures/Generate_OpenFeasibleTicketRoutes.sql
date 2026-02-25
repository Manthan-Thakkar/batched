

CREATE   PROCEDURE [dbo].[Generate_OpenFeasibleTicketRoutes]

AS

BEGIN

	if OBJECT_ID('openFeasibleTicketRoutes') is not null
		DROP table openFeasibleTicketRoutes


			;with timeZero as (
				select timeValue as time_zero
				from ShiftCalendarCurrent s
				where s.timeIndex = 0
			),
			mrl as 
			(
			-- Mutate MasterRollNumber and Groupby to find minimum MasterRollNumber for each Ticket Number
			select distinct 
			otr.Number,
			case when (m.masterRollNumber like '%PRINTED%') 
					then masterRollNumber
					else 'PRINTED_' + m.masterRollNumber + '_' + (select cast(time_zero as nvarchar(255)) from timeZero)
					end as masterRollNumber
			from OpenTicketRoutesRaw otr
			INNER JOIN masterSchedule m 
			ON otr.Number = m.Number
			where (otr.TaskWorkCenter Like '%Digital HP%' OR otr.TaskWorkCenter Like '%Digicon Finishing%')
				and (otr.TaskDone=1 or otr.TaskStarted = 1)
				and otr.DoublePass_ReinsertionFlag != 1
				and m.masterRollNumber is not null
			)
			,
			masterRollLock as (
				select 
				mrl.Number,
				min(mrl.masterRollNumber) masterRollNumber
				from mrl
				group by mrl.Number
			),
			tc as 
			(
			SELECT * FROM timecard where Ticket_No IN (SELECT DISTINCT Number from OpenTicketsScored)
			),
			rs as (
				select tc.*,
				mer.[Press], mer.[DESCRIPTION], mer.[Location], mer.[Value stream], mer.[Workcenter],
				mer.[Active], mer.[Available for Planning], mer.[Available for Scheduling?], 
				mer.[Default Shift Start], mer.[Default Shift End], mer.[Daily Total Hours], mer.[Sort Order]
				from tc
				INNER JOIN MasterEquipmentReference mer 
				on tc.PressNo = mer.Press
				where
					mer.Workcenter = 'Rewinder'
			),
			rewinderScans as (
				select
					rs.Ticket_No as Number,
					max(rs.Sdate) as max_Sdate, 
					max(rs.Stime) as max_Stime,
					rs.PressNo as ScannedRewinder
				from rs
				group by rs.Ticket_No, rs.PressNo
			),
			rl as (
					select 
					ms.Number,
					ms.PressNumber,
					ms.Task
					from masterSchedule ms
					where ms.Number in (select distinct otr.Number from OpenTicketRoutesRaw  otr
										where 
											(otr.TaskWorkcenter Like '%Digital HP%' OR otr.TaskWorkcenter Like '%Digicon Finishing%')
											and (otr.TaskDone = 1 or otr.TaskStarted = 1)
										)
						  and upper(ms.Task) = 'REWINDER'
			),
			rewinderLock as (

				select 
					case when rl.Number is null then rs.Number else rl.Number end as Number,
					case when rl.Task is null then 'REWINDER' else rl.Task end as Task,
					case when rs.ScannedRewinder is null then rl.PressNumber else rs.ScannedRewinder end as ScheduledRewinder
				from
					rl
				full JOIN
					rewinderScans rs
					on rs.Number = rl.Number

			),
			otr_TI as (
				select *,
	
				case 
					when otr.Task = 'PRESS' then 1
					when otr.Task = 'EQUIP' then 2
					when otr.Task = 'EQUIP3' then 3
					when otr.Task = 'EQUIP4' then 4
					when otr.Task = 'REWINDER' then 5
					when otr.Task = 'SHEETER' then 6
					else 7
				end as taskIndex1
				from  OpenTicketRoutesRaw  otr

			),

			otr_si as (
				select *,
				DENSE_RANK() OVER(PARTITION BY Number ORDER BY Number,taskIndex1) sequenceIndex
				from otr_TI
			)
			,

			openTicketRoutes as (

				select otr.CustomerNum, otr.routeFeasible,otr.TaskDueTime,otr.TaskDone,otr.TaskStarted,otr.
						Task,otr.Number,otr.Equip3_ID,otr.PressDone,otr.Equip_Done,otr.Equip3_Done,otr.DoublePass_ReinsertionFlag,otr.TaskEstimatedHours,otr.Press,otr.
						Pass,otr.Priority,otr.TaskWorkCenter,otr.StockNum2,otr.StockNum1,otr.Stock2PressGrouping,otr.Stockwidth2,otr.Varnish,otr.MainTool,otr.HotFoil,otr.
						Embossing,otr.CoreSize,otr.Use_TurretRewinder,otr.
						InlineSheeter,otr.Turnbar, otr.NoAcross, otr.lastScan,otr.ShipTime,otr.ticketPoints,otr.LinearLength_Calc,otr.DoublePassJob, otr.DueDateBucket, otr.SandpaperVarnish, otr.ColdFoil,
						otr.PeelandReveal, convert(varchar(255), mrl.masterRollNumber) as masterRollNumber,
						(Select Top(1) timeIndex
							From shiftCalendarCurrent
							Where timeValue <= otr.TaskDueTime
							Order by timeValue DESC) as taskDueTimeReference,
				case when otr.TaskEstimatedHours is not null then ceiling(otr.TaskEstimatedHours*60) else 0 end as taskEstimatedMinutes,
				--taskIndex1,
				--sequenceIndex,
				case
					when otr.Task = 'EQUIP3' and otr.PressDone = 1 and Equip_Done = 1 and otr.Press = Equip3_ID then 1
					when otr.Task = 'EQUIP3' and otr.PressDone = 1 and Equip_Done = 1 then 2
					when otr.Task = 'EQUIP4' and otr.PressDone = 1 and Equip_Done = 1 and otr.Press = Equip3_ID then 2
					when otr.Task = 'EQUIP4' and otr.PressDone = 1 and Equip_Done = 1 and Equip3_Done = 1 then 2
					when otr.Task = 'REWINDER' and sequenceIndex = 1 then 2
					when otr.Task = 'EQUIP' and otr.PressDone = 1 and Pass is not null and Pass = 2 then 1
					when otr.Task = 'EQUIP3' and otr.PressDone = 1 and Equip_Done = 1 and Pass is not null  and Pass = 3 then 1
					when otr.Task = 'EQUIP3' and otr.PressDone = 1 and Equip_Done = 1 and Pass is not null  and Pass = 2 then 2
					when otr.Task = 'EQUIP4' and otr.PressDone = 1 and Equip_Done = 1 and Equip3_Done = 1 and Pass is not null  and Pass >=  2 then 2
					when otr.PressWorkcenter like '%Digicon Finishing%' then (SELECT MAX(taskInd) FROM (VALUES (taskIndex1),(sequenceIndex+1)) AS ti(taskInd)) 
					else taskIndex1
				end as taskIndex,
				case
					when otr.PressNumber <>	mer.[Press] then mer.[Press] else otr.PressNumber end as PressNumber,
				case 
					when otr.Priority Like '%Urgent%' then 1 else 0 end as HighPriority

				from 
					otr_si  otr
				left join MasterEquipmentReference mer
					on otr.PressNumber = mer.Press
				left join masterRollLock mrl
					on otr.Number = mrl.Number
				left join rewinderLock rl
					on otr.Number = rl.Number
				--left join 
				--	ShiftCalendarCurrent tv1
				--	on otr.TaskDueTime = tv1.timeValue
				where otr.TaskDone = 0
					and otr.routeFeasible = 1
					and not (otr.Task = 'REWINDER' and rl.ScheduledRewinder is not null and otr.PressNumber <> rl.ScheduledRewinder)
			),
			infeasibleMRRoutesGroup as
			(
				select 
				ot.Number,
				ot.masterRollNumber,
				ot.PressNumber,
				Count(ot.Number) OVER(PARTITION BY ot.Number, ot.masterRollNumber, ot.PressNumber) numTicketsFeasibleOnPress,
				Count(ot.Number) OVER(PARTITION BY ot.Number, ot.masterRollNumber) numTicketsInMasterRoll
				from openTicketRoutes ot
				where ot.masterRollNumber is not null and
				 ot.TaskWorkCenter Like '%DIGICON Finishing%'
			),
			infeasibleMRRoutes as (
				select * from infeasibleMRRoutesGroup irg
				where irg.numTicketsFeasibleOnPress <> irg.numTicketsInMasterRoll
			)

			select * 
			into openFeasibleTicketRoutes
			from openTicketRoutes otr
			where not exists (select * 
								from infeasibleMRRoutes ir 
								where otr.masterRollNumber = ir.masterRollNumber 
								and otr.PressNumber = ir.PressNumber
							 )
END

-- Exec Generate_OpenFeasibleTicketRoutes
