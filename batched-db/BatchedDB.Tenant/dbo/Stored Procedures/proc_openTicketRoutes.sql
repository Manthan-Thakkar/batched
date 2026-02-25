CREATE   PROCEDURE [dbo].[proc_openTicketRoutes]
AS 
BEGIN -- begin procedure

	SET NOCOUNT ON;

	/** declare variables **/ 
	declare @rollLength int = 5000;


	/** remove ticket batches that are not longer an open ticket **/
	print 'Removing old batches';
	delete from dbo.MasterRollBatching
		WHERE TicketNumber NOT IN (SELECT DISTINCT Number FROM dbo.OpenTicketsScored)
	;

	-- create temporary table to store open tasks, before cycle times are updated
	If OBJECT_ID('tempdb..#tempOutput') Is Not Null
	Begin
	    Drop Table #tempOutput
	End;

	print 'Updating Master Roll Batches';
	with OpenTicketTasks as (

		select 
			ott.*
			, mrb.MasterRollNumber as PriorMasterRollNumber
		from
			dbo.OpenTicketTasks ott 
		LEFT JOIN 
			dbo.MasterRollBatching mrb 
			ON ott.Number = mrb.MasterRollNumber 


	), masterRollStarted as (

		/** check if any of the tickets on a master roll have been started **/

		select
			ott.PriorMasterRollNumber
			, SUM(CONVERT(int,ott.PressDone)) as masterRollDone 
			, SUM(CASE WHEN ott.Task = 'PRESS' THEN TaskStarted ELSE 0 END) as masterRollStarted
		from 
			OpenTicketTasks ott
		WHERE 
			ott.PriorMasterRollNumber is not null
		GROUP BY 
			ott.PriorMasterRollNumber
		HAVING 
			SUM(CONVERT(int,ott.PressDone)) > 0 
			OR SUM(CASE WHEN ott.Task = 'PRESS' THEN TaskStarted ELSE 0 END) > 0


	), potentialBatches as (

		/** Use batching criteria to identify if there are opportunities to put multiple tickets on same roll 
		Only Indigo jobs that have not been started on press can be batched together **/

		select 
			ott.Press
			, ott.Stock2PressGrouping
			, ott.MainTool
			, ott.CoreSize 
			, ott.Varnish
			, COUNT(DISTINCT ott.Number) as NumTickets
			, SUM(LinearLength_Calc) as LinearLength_Calc
		from
			OpenTicketTasks ott 
		INNER JOIN
			masterRollStarted
			ON ott.PriorMasterRollNumber = ott.PriorMasterRollNumber
		WHERE 
			masterRollStarted.masterRollStarted is null
			AND ott.PressDone = 0
			AND ott.Press in ('1','1B')
		GROUP BY 
			ott.Press
			, ott.Stock2PressGrouping
			, ott.MainTool
			, ott.CoreSize 
			, ott.Varnish
		HAVING 
			COUNT(DISTINCT ott.Number) > 1

	), masterRollIDCreation as (

		/** Generate Master Roll Number based on batching criteria, will be adjusted later by roll length **/

		select 
			ott.Number as TicketNumber
			, ott.LinearLength_Calc
			, CONVERT(VARCHAR,ott.Stock2PressGrouping) + '_' + 
				CONVERT(VARCHAR,ott.MainTool) + '_' + 
				CONVERT(VARCHAR,ott.CoreSize) + '_' + 
				CONVERT(VARCHAR,ott.Varnish) + '_' + 
				REPLACE(CONVERT(VARCHAR,CONVERT(DATE,GETDATE())),'-','') as masterRollNumber
			, ROW_NUMBER() OVER(ORDER BY ott.LinearLength_Calc) as rowNum 
		from 
			potentialBatches pb 
		INNER JOIN 
			OpenTicketTasks ott 
			ON ott.Press = pb.Press
			AND ott.Stock2PressGrouping = pb.Stock2PressGrouping
			AND ott.MainTool = pb.Stock2PressGrouping
			AND ott.CoreSize = pb.CoreSize
			AND ott.Varnish = pb.Varnish


	), rollLengthCalc as (

		select 
			mr.*
			, (SELECT SUM(LinearLength_Calc) FROM masterRollIDCreation 
				WHERE masterRollNumber = mr.MasterRollNumber AND rowNum <= mr.rowNum
				) as cumLength
		from 
			masterRollIDCreation mr 


	), masterRollIDAdjustment as (

		/** Adjust the master roll ID based on length required, must be able to fit on same roll **/
		select 
			rollLengthCalc.*
			, masterRollNumber + '_' + CONVERT(VARCHAR,ceiling(cumLength / @rollLength)) as masterRollNumber_Adjusted
		from 
			rollLengthCalc


	)

		/** Create masterRollNumber identifier to load back to master roll batching table **/
		MERGE INTO dbo.MasterRollBatching as target 
		USING (

			select
				TicketNumber
				, masterRollNumber_Adjusted as masterRollNumber
			from 
				masterRollIDAdjustment

		) AS source
		ON source.TicketNumber = target.TicketNumber
		WHEN MATCHED THEN UPDATE SET
			target.MasterRollNumber = source.masterRollNumber
		WHEN NOT MATCHED THEN INSERT (

			TicketNumber 
			, masterRollNumber

		) VALUES (

			source.TicketNumber
			, source.masterRollNumber

		)
	;
	print 'Merged master roll updates, generating routes...';


	/*** generate routes for each ticket **/ 
	with openTicketTasks as (

		/** Load master roll batch from master roll table **/

		select  
			ott.*
			, mrb.MasterRollNumber
		from
			dbo.openTicketTasks ott 
		LEFT JOIN 
			dbo.masterRollBatching mrb 
			ON ott.Number = mrb.TicketNumber

	), timecardScans as (


		/** check if that ticket has started in a specific machine based on the timecard data**/

		select
            timecard.Ticket_No
            , timecard.PressNo
            -- #REPLACED
            --, MIN(dateadd(ss, timecard.STime, CAST(timecard.SDate as Datetime))) as firstScan
            --, MAX(dateadd(ss, timecard.eTime, CAST(timecard.EDate as Datetime))) as lastScan
            --, SUM(DATEPART(MINUTE,timecard.Elapsed)) as totalElapsed
            , MIN(dateadd(ss, DATEDIFF(SECOND, DATEADD(DAY, DATEDIFF(DAY, 0,timecard.STime), 0), timecard.STime), CAST(timecard.SDate as Datetime))) as firstScan
            , MAX(dateadd(ss,  DATEDIFF(SECOND, DATEADD(DAY, DATEDIFF(DAY, 0,timecard.ETime), 0), timecard.ETime), CAST(timecard.EDate as Datetime))) as lastScan
            , SUM(DATEPART(MINUTE,timecard.Elapsed)) as totalElapsed
        from
            dbo.timecard
        WHERE
			Ticket_No IN (SELECT DISTINCT Number from dbo.openTicketsScored)
		GROUP BY 
			timecard.Ticket_No 
			, timecard.PressNO


	), allRoutes as (

		/** Expand data to all possible routes based on the work center for each task **/

		select 
			mer.Press as PressNumber 
			, mer.DESCRIPTION as PressDescription 
			, mer.[Available For Scheduling?] as AvailableForScheduling
			, tcs.lastScan
			, tcs.totalElapsed
			, ott.*
		from 
			openTicketTasks ott 
		CROSS JOIN 
			dbo.masterEquipmentReference mer 
		LEFT JOIN 
			timecardScans tcs 
			ON ott.Number = tcs.Ticket_No
			AND mer.Press = tcs.PressNo
		WHERE 
			ott.TaskWorkCenter = UPPER(mer.WorkCenter)
			OR (ott.TaskWorkCenter = 'REWINDER' AND mer.Press IN ('5','7','10'))

	), feasibleRoutes as (

		select 

			/** Define if the specific route is feasible or not **/
			CASE
				WHEN ar.AvailableForScheduling <> 'Yes' THEN 0

				/** Digicon **/
				WHEN ar.TaskWorkCenter LIKE 'DIGICON%' THEN 
					CASE 

						-- SPECIAL CASE: Hot Foil / Laminate combination tickets:
						-- As long as the job is laminated before hot foil, the routing is feasible
						WHEN ar.PressNumber IN ('10') and ar.HotFoil > 0 AND 
							ar.Equip_ID = '7' AND ar.Equip3_ID = '10' AND ar.Task = 'EQUIP3' THEN 1

						WHEN ar.PressNumber IN ('10') and ar.HotFoil > 0  AND 
							ar.Equip_ID = '7' AND ar.Equip4_ID = '10' AND ar.Task = 'EQUIP4' THEN 1

						WHEN ar.PressNumber IN ('10') and ar.HotFoil > 0  AND 
							ar.Equip3_ID = '7' AND ar.Equip4_ID = '10' AND ar.Task = 'EQUIP4' THEN 1

						WHEN ar.PressNumber IN ('7') and ar.HotFoil > 0  AND 
							ar.Equip_ID = '7' AND ar.Equip4_ID = '10' AND ar.Task = 'EQUIP' THEN 1

						WHEN ar.PressNumber IN ('7') and ar.HotFoil > 0  AND 
							ar.Equip3_ID = '7' AND ar.Equip4_ID = '10' AND ar.Task = 'EQUIP3' THEN 1
						
						-- Digicon Series 3 Deluxe cannot run Laminate
						--WHEN ar.PressNumber IN ('10') and ar.Laminate = 1 THEN 0

						-- Hot Foil, PMS Flexo, Emboss, Screen must all run on Series 3 Deluxe (# 10)
						WHEN ar.PressNumber IN ('7') and (ar.HotFoil + ar.Embossing) > 0 THEN 0

						--Jobs being rewound at digicons with more than 20 rolls should go to #7 Digicon
						When ar.PressNumber IN ('10') AND (ar.use_turretrewinder=1 or ar.RewindEquipNum In ('19', '24', '26')) AND ar.ConsecNo=0 AND (ar.HotFoil + ar.Embossing) = 0 AND (ar.NumberOfFinishedRolls>20 or ar.CoreSize=25) Then 0
						
						ELSE 1
					END

				/** Rewinding **/
				WHEN ar.TaskWorkCenter ='REWINDER' THEN 
					CASE 

						WHEN ar.PressNumber IN ('26', '19', '24','16') THEN 0 -- these are not real machines
						--- ### TEMPORARY FIX !!!! - if use_TurretRewinder = 0 THEN cannot run on Digicon or Omega
						--WHEN ar.PressNumber IN ('26', '19', '24','16') AND ar.use_TurretRewinder = 0 THEN 0

						--Remove EFI jobs from being rewound at Digicons
						When ar.Press='6' and ar.PressNumber in ('7','10', '26','19','24') Then 0

						--Remove OMEGA jobs from being rewound at Digicons
						When ar.Press='5' and ar.PressNumber in ('7','10', '26','19','24') Then 0

						--Remove HP Jobs from being rewound at OMEGA
						When ar.Press in ('1', '1B') and ar.PressNumber in ('5') Then 0

						--Digicon #10 Cannot run tickets with > 20 rolls or coresize of 25mm
						When ar.PressNumber in ('10') and (ar.numberOfFinishedRolls>20 OR ar.CoreSize=25) Then 0
						
						-- variable data cannot run on DigiCon, or Daco
						WHEN ar.PressNumber IN ('26', '19', '24','11','7','10') AND ar.ConsecNo = 1 THEN 0

						-- hot foil jobs cannot be rewound on Digicon
						WHEN ar.PressNumber IN ('7','10', '26','19','24') and (ar.HotFoil + ar.Embossing) > 0 THEN 0

						-- Small Roll Numbers with Extra Rolls Shouldn't Go to Digicon
						WHEN ar.PressNumber IN ('7','10', '26','19','24') and ar.numberOfFinishedRolls<=20 and ar.numberOfLeftoverRolls>0 and ar.Stock2_LinerCaliper>=35 Then 0

						-- Flexo jobs will only run on Digicon if >= 1000 meters
						WHEN ar.PressNumber IN ('7','10', '26','19','24') AND ar.Press IN ('2')  AND ar.EstFootage <= 1000 and ar.Stock2_LinerCaliper>=35  then 0

						-- Tabletop and Daco cannot run Liners < 35 microns
						WHEN ar.PressNumber IN ('11', '12') AND ar.Press IN ('2')  AND ar.Stock2_LinerCaliper<35  then 0

						-- Daco cannot run rolls >= 250 OD, tickets < 20 rolls
						WHEN ar.PressNumber IN ('11') AND (ar.OutsideDiameter >= 250) Then 0 
						
						-- Daco cannot run low number of rolls unless >= 2000m
						When ar.PressNumber IN ('11') AND ar.EstFootage < 2000 AND ar.numberOfFinishedRolls<20 THEN 0
						
						-- Spoleboard cannot run tickets > 100 rolls
						WHEN ar.PressNumber IN ('12') AND ar.numberOfFinishedRolls>100 THEN 0
						
						-- Spolebord cannot run tickets > 2000 meters
						When (ar.PressNumber IN ('12') AND ar.EstFootage > 2000 AND ar.ConsecNo <> 1 AND ar.OutsideDiameter<250 and ar.numberOfFinishedRolls>=20) Then 0

						-- omega cannot run 25 MM core, no tickets <= 10 rolls, no perforation, no tickets >= 350mm OD, no tickets with inward final unwind
						WHEN ar.PressNumber IN ('5','16') AND ar.Stock2_LinerCaliper < 35 THEN 0
						WHEN ar.PressNumber IN ('5','16') AND ar.Shape LIKE '%perf%' THEN 0
						WHEN ar.PressNumber IN ('5','16') AND ar.OutsideDiameter >= 350 THEN 0
						When ar.PressNumber IN ('5','16') AND ar.FinalUnwind Like '%In%' Then 0
						When ar.PressNumber IN ('5','16') AND numberOfFinishedRolls < 10 Then 0
						
						ELSE 1
					END

				/** SHEETER Tasks **/
				WHEN ar.TaskWorkCenter = 'SHEETER' THEN
					CASE
						-- For Flexo jobs that can sheet inline, do not consider the Sheeter as an option
						WHEN ar.PressNumber IN ('14') and ar.Press IN ('2') AND ar.InlineSheeter > 0 THEN 0
						ELSE 1
					END



				/** If ticket has been started on a different machine in the work center, 
				then the other routes in the work center are infeasible **/
				WHEN (SELECT SUM(totalElapsed) FROM allRoutes 
						WHERE Number = ar.Number AND TaskWorkCenter = ar.TaskWorkCenter) > 0
						AND ar.totalElapsed IS NULL 
						THEN 0


				ELSE 1
				END as routeFeasible

			/** Identify preferred routes: 
			1 is preferred, 0 is neutral, -1 is not preferred
			**/
			, CASE
				
				/** Preferred Routes: Digicon **/
				WHEN ar.TaskWorkCenter LIKE 'DIGICON%' THEN
					CASE 
						-- prefer to run jobs >50 rolls on #7 rather than #10
						WHEN ar.PressNumber IN ('7') and ar.numberOfFinishedRolls >= 50 THEN 1
						WHEN ar.PressNumber IN ('10') and ar.numberOfFinishedRolls >= 50 THEN -1
						ELSE 0
					END

				/** Preferred Routes: Rewinder **/
				WHEN ar.TaskWorkCenter LIKE 'REWINDER%' THEN
					CASE 
						-- prefer to not run jobs with less than 20 rolls on DACO
						WHEN ar.PressNumber IN ('11') AND ar.numberOfFinishedRolls <= 20 THEN -1

						-- prefer not to run jobs with > 100 rolls on table top
						WHEN ar.PressNumber IN ('12') AND ar.numberOfFinishedRolls >= 100 THEN -1

						-- prefer not to run tickets < 10 rolls on OMEGA
						WHEN ar.PressNumber IN ('16') AND ar.numberOfFinishedRolls <= 10 THEN -1

						-- jobs smaller than 10 rolls with leftover rolls to be manually rewound should be rewound at table top
						WHEN ar.PressNumber NOT IN ('12') and ar.numberOfFinishedRolls <= 10 and ar.numberOfLeftoverRolls <> 0 THEN -1


						ELSE 0

					END
				ELSE 0 
			END as routePreferred

			,ar.*

		from 
			allRoutes ar 


	)


		select 
			feasibleRoutes.*
		into 
			#tempOutput
		from 
			feasibleRoutes

	;


	-- clear out the open Batch Routes table, and load the new data
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'openTicketRoutes')
			BEGIN

				
					print 'truncate and insert new records...';
					truncate table dbo.openTicketRoutes;
					insert into
						dbo.openTicketRoutes
					select 
						*
						, GETDATE() as lastRefreshed
					from 
						#tempOutput
					;


			END -- end the clause to truncate old date
		ELSE -- if the table does not exist, create a new table
			BEGIN

				print 'creating new table';
				select 
					*
					, GETDATE() as lastRefreshed
				into 
					dbo.openTicketRoutes
				from 
					#tempOutput
			END 
		

		drop table #tempOutput;

		print 'COMPLETE!';

END -- end procedure
