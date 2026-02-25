CREATE PROCEDURE [dbo].[spImportTicketData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId	VARCHAR(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do NOT change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportTicketData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000, --keep this exactly same AS 4000
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME,
--	======================================================================================================
		@totalSecondsPerMinute	FLOAT = 3600.00;
	END
	
	BEGIN TRANSACTION;
	
		-- #PV_Jobs temp table WITH concatenated ticket number
		SELECT 
			J.*,JC.JobCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
		INTO #PV_Jobs
		FROM PV_job J
			INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
		where (J.JobStatus in (10, 20) OR (J.JobStatus Not In (10, 20) AND J.CompletedDate >= DATEADD(day, -30, getdate()))) AND JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

		-- #PV_Job_SO_Value
		SELECT CONCAT(J.CompNum,'_',J.PlantCode,'_',J.JobCode) AS TicketNumber
				, j.CompNum
				, j.PlantCode
				, j.JobCode
				, min(JSOL.SOrderNum) as SOrderNum
				, min(SO.SOrderDate) as SOrderDate
				, sum(SOL.OrderedValue) as OrderedValue
				, sum(SOL.OutStandingValue) as OutstandingValue
				, sum(SOL.ShippedValue) as ShippedValue
				, sum(SOL.BillValue) as BillValue
				, min(SO.CustOrderDate) as CustOrderDate
            Into #PV_Job_SO_Value
			FROM PV_Job j
            INNER JOIN PV_JobLine JL ON J.CompNum = JL.CompNum AND J.JobCode = JL.JobCode
            INNER JOIN PV_JobSOLink JSOL on j.CompNum = JSOL.CompNum  and j.JobCode = JSOL.JobCode and JL .JobLineNum = JSOL.JobLineNum
			INNER JOIN PV_SOrderLine SOL on j.CompNum = SOL.CompNum and JSOL.SOrderNum = SOL.SOrderNum and JSOL.SOrderLineNum = SOL.SOrderLineNum
            INNER JOIN PV_SOrder SO ON JSOL.CompNum =so.CompNum and JSOL.SOrderNum =so.SOrderNum
            Group by CONCAT(J.CompNum,'_',J.PlantCode,'_',J.JobCode), j.CompNum, j.PlantCode, j.JobCode

			
	-- #PV_JobSteps temp table WITH concatenated ticket number
        SELECT 
            js.*
            , CONCAT( js.CompNum,'_',js.PlantCode,'_',js.JobCode,'_',JS.JobCmpNum) AS TicketNumber
			, CASE WHEN sfec.CompletedSteps IS NOT NULL THEN 'C' ELSE  sfp.kstatus END AS kstatus
            , ROW_NUMBER() OVER (Partition by js.CompNum, js.PlantCode, js.JobCode, js.JobCmpNum, js.VRType Order by js.JobCmpNum ASC, js.[est-route-seq] ASC) as SortOrder
        INTO #PV_JobSteps
        FROM PV_JobStep js
		LEFT JOIN sfplan sfp on js.CompNum = sfp.kco and js.PlantCode = sfp.PlantCode and js.JobCode = sfp.kjobcode and js.JobCmpNum = sfp.kcompno and js.StepNum = sfp.kprocno
        LEFT JOIN (SELECT sfec.kco, sfec.PlantCode, sfec.kjobcode, sfec.kcompno, sfec.kprocno, count(*) AS CompletedSteps
					FROM sfeventcds sfec
					INNER JOIN PV_Job j ON j.CompNum = sfec.kco and j.PlantCode = sfec.PlantCode and j.JobCode = sfec.kjobcode
					WHERE j.JobStatus in (10, 20) and sfec.[event-type] = 'C'
					GROUP BY sfec.kco, sfec.PlantCode, sfec.kjobcode, sfec.kcompno, sfec.kprocno) sfec ON js.CompNum = sfec.kco and js.PlantCode = sfec.PlantCode and js.JobCode = sfec.kjobcode and js.StepNum = sfec.kprocno
		WHERE js.StepType in (3,5) and js.CmpType in (7, 9, 10)
			
		--Indexes for faster execution of queries
		CREATE NONCLUSTERED INDEX [IX_PV_Job_TicketNumber] ON #PV_Jobs
		(
			TicketNumber ASC
		)
		CREATE NONCLUSTERED INDEX [IX_PV_JobStep_TicketNumber] ON #PV_JobSteps
		(
			TicketNumber ASC
		)

		--Identifying existing matching tickets AND storing them IN temp table
		SELECT 
			TM.ID AS TicketId, J.TicketNumber
		INTO #MatchingTickets
		FROM TicketMaster TM
			INNER JOIN #PV_Jobs J ON J.TicketNumber = TM.SourceTicketId
			AND J.JobCode IS NOT NULL
		WHERE TM.Source = 'Radius' AND TM.TenantId = @TenantId

		-- Ticket Priority Calculations
		;WITH SourcePriotrityCalc AS (
			SELECT 
				TicketNumber , SOIT.SOItemType AS SourcePriority ,
				ROW_NUMBER() OVER(PARTITION BY J.CompNum, J.jobcode, J.plantcode, J.JobCmpNum ORDER BY J.JobCmpNum DESC) AS row_number
			FROM #PV_Jobs J
			INNER JOIN PV_JobLine JL ON J.CompNum = JL.CompNum AND J.JobCode = JL.JobCode --AND J.PlantCode = JL.PlantCode  --Avoided joining by kprofile
			INNER JOIN PV_JobSOLink JSOL ON J.CompNum = JSOL.CompNum  AND J.JobCode = JSOL.JobCode AND JL .JobLineNum = JSOL.JobLineNum
			INNER JOIN PV_SOrder SO ON JSOL.CompNum = SO.CompNum AND JSOL.SOrderNum = SO.SOrderNum 
			INNER JOIN PV_SOrderLine SOL ON SO.CompNum = SOL.CompNum AND SO.SOrderNum = SOL.SOrderNum AND JSOL.SOrderLineNum = SOL.SOrderLineNum 
			INNER JOIN PV_SOrderItemType SOIT ON SOIT.CompNum = SOL.CompNum AND SOIT.SOItemTypeCode = SOL.SOItemTypeCode)

		SELECT * INTO #TicketPriority FROM SourcePriotrityCalc WHERE row_number = 1

		--Final Unwind Calculations
		;WITH FinalUnwindCalc AS (
			SELECT 
				J.TicketNumber, UDED.UDGroup, UDED.UDElement, UDED.UDValue,
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum, J.JobCmpNum ORDER BY UDED.UDElement DESC) AS row_number
			FROM #PV_Jobs J
			INNER JOIN PV_JobLine JL ON J.CompNum = JL.CompNum AND J.JobCode = JL.JobCode 
			INNER JOIN PM_Item I ON JL.ItemCode = I.ItemCode 
			INNER JOIN PV_UDElementData UDED ON I.TableRecId = UDED.UDLinkRecId AND UDED.LinkPoint = 3
			WHERE UDED.UDElement = 'Direction Off'
		)

		SELECT * INTO #FinalUnwind FROM FinalUnwindCalc WHERE row_number = 1

		--General Description Calcs
		;WITH GeneralDescriptinCalc AS (
			SELECT 
				J.TicketNumber, h.[wih-code2],
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum, J.JobCmpNum  ORDER BY J.JobCmpNum DESC) AS row_number
			FROM #PV_Jobs J
			INNER JOIN [wi-head] h on j.CompNum = h.kco and j.EstCode = h.[k-est-code] and j.JobCode = h.korder
		)

		SELECT * INTO #GeneralDescription FROM GeneralDescriptinCalc WHERE row_number = 1

		--ToolSpec Calculations
		;WITH ToolSpecCalc AS (
			 SELECT  
				TS.SizeDown AS SizeAround,
				TS.Shape,
				J.TicketNumber,
				TS.GapDown,
				ROW_NUMBER() OVER(PARTITION BY J.compnum,J.jobcode,J.plantcode, J.JobCmpNum ORDER BY JTS.SeqNum DESC) AS row_number
			FROM #PV_Jobs J
			INNER JOIN PV_JobToolSpec  JTS ON JTS.JobCode=J.JobCode AND JTS.CompNum=J.CompNum AND JTS.PlantCode = J.PlantCode-- AND JTS.JobCmpNum = J.JobCmpNum
			INNER JOIN PV_ToolSpec TS ON JTS.CompNum = TS.CompNum AND JTS.SpecCode = TS.SpecCode
			)

		SELECT * INTO #ToolSpec  FROM ToolSpecCalc WHERE row_number = 1

		--Representative Names Calculations
		;WITH RepresNamesCalc AS ( 
			SELECT 
				DISTINCT J.TicketNumber,
				UREP.UserName  AS OTSName,
				UCSR.UserName  AS ITSName ,
				SO.RepUserCode  AS OTSAssocNum , SO.CSRUserCode AS ITSAssocNum,
				SO.YourContact ,
				SO.CustRef,
				ROW_NUMBER() OVER(PARTITION BY J.compnum,J.plantcode,J.jobcode,J.JobCmpNum ORDER BY J.JobCmpNum ) AS row_number --- need to revisit this
			FROM #PV_Jobs J
			INNER JOIN PV_JobLine JL ON J.CompNum = JL.CompNum AND J.JobCode = JL.JobCode -- AND J.PlantCode = JL.PlantCode 
			INNER JOIN PV_JobSOLink JSOL on j.CompNum = JSOL.CompNum  and j.JobCode = JSOL.JobCode and JL .JobLineNum = JSOL.JobLineNum
			INNER JOIN PV_SOrder SO ON JSOL.CompNum =so.CompNum and JSOL.SOrderNum =so.SOrderNum 
			INNER JOIN PM_User UREP ON UREP.UserCode = SO.RepUserCode 
			INNER JOIN PM_User UCSR ON UCSR.UserCode = SO.CSRUserCode
		)

		SELECT * INTO #RepresentativeNames FROM RepresNamesCalc WHERE row_number = 1 --- needs revision

		--Finish Type Calculations
		;WITH FinishTypeCalc AS (
			SELECT
				CASE 
					WHEN  WP.SALFinishAS = 0 then J.ProdGroupCode
					WHEN  WP.SALFinishAS = 2 then 'Rolls'
					WHEN  WP.SALFinishAS = 3 then 'Cut Sheets'
					WHEN  WP.SALFinishAS = 4 then 'Fanfold Labels'
					WHEN  WP.SALFinishAS = 5 then 'Fanfold Sheets'
					ELSE ''
				END AS SourceFinishType,
				J.TicketNumber,
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum,J.JobCmpNum  ORDER BY J.JobCmpNum) AS row_number
			FROM #PV_Jobs J
			INNER JOIN [wi-profile]  WP ON J.CompNum = WP.kco AND J.JobCode = WP.korder -- AND J.JobCmpNum = WP.[k-cmp-no]
		)

		SELECT * INTO #SourceFinishType FROM FinishTypeCalc WHERE row_number = 1 	

	--PRESS DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS PRESS,
		CASE
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS PressDone,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #pressCalc
	FROM #PV_JobSteps js 
    WHERE SortOrder = 1 

	SELECT * INTO #Press FROM #pressCalc WHERE row_number = 1

	;WITH Equip1Status AS (
		SELECT 
			TicketNumber,
			TaskName,
			PressDone AS TaskStatus,
			ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #pressCalc
		WHERE VRType = 2 
	)


	SELECT * INTO #PressStatus FROM Equip1Status WHERE row_number = 1

	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime1 FROM #pressCalc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime1 FROM #pressCalc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime1 FROM #pressCalc WHERE VRType =1 group by TicketNumber

	----EQUIP/EQUIP2 DETAILS
	SELECT
		TicketNumber,
		WorkcCode AS Equip2Id,
		CASE 
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0 
		END AS Equip2Done,
		StepNum AS TaskName,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number,
		VrType AS VRType
	INTO #Equip2Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 2
	
	SELECT * INTO #Equip2 FROM #Equip2Calc WHERE row_number = 1

	;WITH Equip2Status AS (
		SELECT 
		TicketNumber,
		TaskName,
		Equip2Done AS TaskStatus,
		ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #Equip2Calc
		WHERE VRType = 2 
	)

	SELECT * INTO #Equip2Status FROM Equip2Status WHERE row_number = 1

	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime2 FROM #Equip2Calc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime2 FROM #Equip2Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime2 FROM #Equip2Calc WHERE VRType =1 group by TicketNumber

	----EQUIP3 DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS Equip3Id,
		CASE
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS Equip3Done,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #Equip3Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 3

	SELECT * INTO #Equip3 FROM #Equip3Calc WHERE row_number = 1

	;WITH Equip3Status AS (
		SELECT
			TicketNumber,
			TaskName,
			Equip3Done AS TaskStatus,
			ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #Equip3Calc
		WHERE VRType = 2 
	)

	SELECT * INTO #Equip3Status FROM Equip3Status WHERE row_number = 1
	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime3 FROM #Equip3Calc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime3 FROM #Equip3Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime3 FROM #Equip3Calc WHERE VRType =1 group by TicketNumber

	----EQUIP4 DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS Equip4Id,
		CASE
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS Equip4Done,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #Equip4Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 4

	SELECT * INTO #Equip4 FROM #Equip4Calc WHERE row_number = 1

	;WITH Equip4Status AS (
		SELECT
			TicketNumber,
			TaskName,
			Equip4Done AS TaskStatus,
			ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #Equip4Calc
		WHERE VRType = 2 
	)

	SELECT * INTO #Equip4Status FROM Equip4Status WHERE row_number = 1
	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime4 FROM #Equip4Calc group  by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime4 FROM #Equip4Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime4 FROM #Equip4Calc WHERE VRType =1 group by TicketNumber

	----EQUIP5 DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS Equip5Id,
		CASE
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS Equip5Done,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #Equip5Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 5

	SELECT * INTO #Equip5 FROM #Equip5Calc WHERE row_number = 1

	;WITH Equip5Status AS (
		SELECT 
			TicketNumber,
			TaskName,
			Equip5Done AS TaskStatus,
			ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
			FROM #Equip5Calc
			WHERE VRType = 2 
	)

	SELECT * INTO #Equip5Status FROM Equip5Status WHERE row_number = 1
	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime5 FROM #Equip5Calc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime5 FROM #Equip5Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime5 FROM #Equip5Calc WHERE VRType =1 group by TicketNumber

	----EQUIP6 DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS Equip6Id,
		CASE
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS Equip6Done,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #Equip6Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 6 

	SELECT * INTO #Equip6 FROM #Equip6Calc WHERE row_number = 1

	;WITH Equip6Status AS (
		SELECT 
			TicketNumber,
			TaskName,
			Equip6Done AS TaskStatus,
			ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #Equip6Calc
		WHERE VRType = 2 
	)

	SELECT * INTO #Equip6Status FROM Equip6Status WHERE row_number = 1
	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime6 FROM #Equip6Calc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime6 FROM #Equip6Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime6 FROM #Equip6Calc WHERE VRType =1 group by TicketNumber

	----EQUIP7 DETAILS
	SELECT 
		TicketNumber,
		WorkcCode AS Equip7Id,
		CASE 
			WHEN StepStatus IN (1,2) OR kstatus = 'C' THEN 1
			ELSE 0
		END AS Equip7Done,
		StepNum AS TaskName,
		VrType AS VRType,
		LabourSecs /@totalSecondsPerMinute AS LabTime,
		ROW_NUMBER() OVER(PARTITION BY CompNum,PlantCode,JobCode,JobCmpNum ORDER BY CompNum,plantcode,jobcode,JobCmpNum DESC) AS row_number
	INTO #Equip7Calc
    FROM #PV_JobSteps 
    WHERE SortOrder = 7

	SELECT * INTO #Equip7 FROM #Equip7Calc WHERE row_number = 1

	;WITH Equip7Status AS (
		SELECT 
		TicketNumber,
		TaskName,
		Equip7Done AS TaskStatus,
		ROW_NUMBER() OVER(PARTITION BY TicketNumber ORDER BY TicketNumber DESC) AS row_number
		FROM #Equip7Calc WHERE VRType = 2 
	)

	SELECT * INTO #Equip7Status FROM Equip7Status WHERE row_number = 1
	SELECT TicketNumber, SUM(LabTime) AS EstTime INTO #EstTime7 FROM #Equip7Calc group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstRunTime INTO #EstRunTime7 FROM #Equip7Calc WHERE VRType =2 group by TicketNumber
	SELECT TicketNumber, SUM(LabTime) AS EstMRTime INTO #EstMRTime7 FROM #Equip7Calc WHERE VRType =1 group by TicketNumber
	
	--Ticket Shipping Details
		;with TicketShippingPreDataCalc as(
		SELECT distinct
			j.TicketNumber, 
			SR.ShipReqStat,
			ROW_NUMBER() OVER(PARTITION BY j.compnum ,j.plantcode,j.jobcode, j.JobCmpNum ORDER BY j.JobCmpNum ) AS row_number
			FROM #PV_Jobs J
			inner join PV_SOrder so on j.JobCode = so.JobCode and j.CompNum = so.CompNum and j.PlantCode = so.PlantCode 
			inner join PV_ShipReqLine srl on srl.SOrderNum = so.SOrderNum and srl.CompNum = so.CompNum and srl.PlantCode = so.PlantCode 
			inner join PV_ShipReq sr on sr.ShipReqNum = srl.ShipReqNum and sr.CompNum = srl.CompNum and sr.PlantCode = srl.PlantCode 
			left join PV_Address shipad on shipad.AddressNum = sr.ShipAddrNum  
			left join PV_Address billad on billad.AddressNum = sr.BillAddrNum  )

			select TicketNumber, ShippingStatus = (CASE WHEN  TSPreData.ShipReqStat = 0 THEN 'Not started '
									WHEN TSPreData.ShipReqStat = 1 THEN 'Generated'
									WHEN TSPreData.ShipReqStat = 2 THEN 'Printed'
									WHEN TSPreData.ShipReqStat = 3 THEN 'Picked'
									WHEN TSPreData.ShipReqStat = 4 THEN 'Confirmed'
									WHEN TSPreData.ShipReqStat = 5 THEN 'Shipped'
									ELSE null END)
									into #TicketShippingPreData from TicketShippingPreDataCalc TSPreData  where row_number =1

	-- UPDATE BLOCK FOR MATHCHING TICKETS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTickets'; SET @startTime = GETDATE();

		Begin TRY		
			-- Update the records
			UPDATE TicketMaster 
			SET
				OrderDate = j.JobCreateDate,
				SourceCustomerId = cust.CustCode,
				CustomerName = cust.CustName,
				CustomerPO = rn.CustRef,
				SourcePriority =p.SourcePriority, 
				SourceFinishType =sf.SourceFinishType,
				isBackSidePrinted = null,
				isSlitOnRewind = null,
				UseTurretRewinder = null,
				EstTotalRevenue = ISNULL(jso.OrderedValue, 0),
				SourceTicketType = CASE WHEN j.JobType IN( 0,1,2) THEN 1 WHEN j.JobType = 10 THEN 5  ELSE 0 END ,
				SourceStockTicketType = 0,
				PriceMode =null, -- Ask question
				FinalUnwind =f.UDValue,
				IsOpen = CASE WHEN j.JobStatus IN( 10,20) THEN 1 ELSE 0 END ,
				SourceStatus = j.StatusCode,
				IsOnHold = CASE WHEN j.StatusCode like '%hold%'  THEN 1 ELSE 0 END,
				BackStageColorStrategy = null,
				Pinfeed =wiProf.[wi-p-pinfeed], 
				GeneralDescription = g.[wih-code2],
				IsPrintReversed = wiProf.[wi-p-reverse-print],
				SourceTicketNotes = j.JobText, 
				EndUserNum = cust.CustCode,
				EndUserName = cust.CustName, 
				Tab = null, -- Mapping NOT found
				SizeAround = TS.SizeAround,
				ShrinkSleeveLayFlat = null, -- Mapping NOT found
				Shape = TS.Shape, 
				InkStatus = null, -- AS per mapping
				SourceCreatedOn =j.JobCreateDate,
				SourceModifiedOn = Cast(j.LastUpdatedDateTime AS datetime2),
				ModifiedOn = GETUTCDATE(),
				ITSName = rn.ITSName,
				OTSName = rn.OTSName,
				Press = t1.PRESS,
				EquipId = t2.Equip2Id,
				Equip3Id = t3.Equip3Id,
				Equip4Id = t4.Equip4Id,
				RewindEquipNum =t5.Equip5Id,
				ITSAssocNum = rn.ITSAssocNum,
				OTSAssocNum = rn.OTSAssocNum,
				DateDone = j.completeddate,
				EndUserPO = null,
				IsStockAllocated=null,
				EstPackHrs =null,
				ActPackHrs =null,
				CustContact = rn.YourContact,-- Marking null AS of now to eliminate duplicates because of join
				FinishNotes = null,
				StockNotes = null,
				CreditHoldOverride = null,
				ShrinkSleeveOverLap = null,
				ShrinkSleeveCutHeight = null,
				PressDone = st1.TaskStatus,
				EquipDone = st2.TaskStatus,
				Equip3Done = st3.TaskStatus,
				Equip4Done= st4.TaskStatus,
				FinishDone = st5.TaskStatus,
				EstRunHrs = er1.EstRunTime,
				EstMRHrs = mr1.EstMRTime,
				Terms = null,
				EstTime = ISNULL(et1.EstTime,0),
				EquipEstTime = ISNULL(et2.EstTime,0),
				Equip3EstTime = ISNULL(et3.EstTime,0),
				Equip4EstTime = ISNULL(et4.EstTime,0),
				EstFinHrs =ISNULL(et5.EstTime,0),
				EquipEstRunHrs = er2.EstRunTime,
				Equip3EstRunHrs = er3.EstRunTime,
				Equip4EstRunHrs = er4.EstRunTime,
				EstWuHrs =null,
				EquipWashUpHours = null,
				Equip3WashUpHours = null,
				Equip4WashUpHours = null,
				Equip5WashUpHours = null,
				Equip6WashUpHours = null,
				Equip7WashUpHours = null,
				EquipMakeReadyHours = mr2.EstMRTime,
				Equip3MakeReadyHours = mr3.EstMRTime,
				Equip4MakeReadyHours= mr4.EstMRTime,
				Equip2Id = t2.Equip2Id,
				Equip5Id = t5.Equip5Id,
				Equip6Id = t6.Equip6Id,
				Equip7Id = t7.Equip7Id,
				Equip2Done  = st2.TaskStatus,
				Equip5Done  = st5.TaskStatus,
				Equip6Done  = st6.TaskStatus,
				Equip7Done  = st7.TaskStatus,
				Equip1TaskName  = st1.TaskName,
				Equip2TaskName  = st2.TaskName,
				Equip3TaskName  = st3.TaskName,
				Equip4TaskName = st4.TaskName,
				Equip5TaskName = st5.TaskName,
				Equip6TaskName = st6.TaskName,
				Equip7TaskName = st7.TaskName,
				Equip5EstTime = ISNULL(et5.EstTime,0),
				Equip6EstTime = ISNULL(et6.EstTime,0),
				Equip7EstTime = ISNULL(et7.EstTime,0),
				Equip5EstRunHrs = er5.EstRunTime,
				Equip6EstRunHrs = er6.EstRunTime,
				Equip7EstRunHrs = er7.EstRunTime,
				Equip2MakeReadyHours =mr2.EstMRTime,
				Equip5MakeReadyHours = mr5.EstMRTime,
				Equip6MakeReadyHours = mr6.EstMRTime,
				Equip7MakeReadyHours = mr7.EstMRTime,
				ShipStatus = tship.ShippingStatus,
				InternetSubmission = NULL,
				SourceCompanyId = j.CompNum,
				SourceFacilityId = j.PlantCode,
				TicketRowspace = TS.GapDown,
				FinishStatus = NULL,
				EnteredBy = j.LastUserCode,
				PreviousTicketNumber = NULL
			FROM 
			TicketMaster ticMaster WITH(NOLOCK) 
			INNER JOIN #MatchingTickets mtic WITH(NOLOCK)  ON ticMaster.Id = mtic.TicketId
			INNER JOIN #PV_Jobs j WITH(NOLOCK)  ON j.TicketNumber = ticMaster.SourceTicketId AND j.JobCode IS NOT NULL
			LEFT JOIN #PV_Job_SO_Value jso on j.CompNum = jso.CompNum and j.PlantCode = jso.PlantCode and j.JobCode = jso.JobCode
			LEFT JOIN PV_Customer cust WITH(NOLOCK)  ON j.CustCode = cust.CustCode
			LEFT join #TicketPriority p WITH(NOLOCK)  ON j.TicketNumber = p.TicketNumber
			LEFT JOIN #FinalUnwind f WITH(NOLOCK)  ON j.TicketNumber = f.TicketNumber
			Left Join #GeneralDescription g on j.TicketNumber = g.TicketNumber
			LEFT JOIN(SELECT DISTINCT korder,kco,[wi-p-pinfeed],[wi-p-reverse-print]
						FROM  [wi-profile] WITH(NOLOCK) )  wiProf 
						ON j.JobCode = wiProf.korder AND j.CompNum = wiProf.kco 
			Left join #ToolSpec TS WITH(NOLOCK)  ON j.TicketNumber = TS.TicketNumber
			LEFT JOIN #RepresentativeNames rn WITH(NOLOCK)  ON j.TicketNumber = rn.TicketNumber -- TODO- after clarification
			LEFT JOIN #SourceFinishType sf WITH(NOLOCK)  ON j.TicketNumber = sf.TicketNumber
			LEFT JOIN #Press t1 ON  j.TicketNumber = t1.TicketNumber
			LEFT JOIN #Equip2 t2 ON  j.TicketNumber = t2.TicketNumber
			LEFT JOIN #Equip3 t3 ON  j.TicketNumber = t3.TicketNumber
			LEFT JOIN #Equip4 t4 ON  j.TicketNumber = t4.TicketNumber
			LEFT JOIN #Equip5 t5 ON  j.TicketNumber = t5.TicketNumber
			LEFT JOIN #Equip6 t6 ON  j.TicketNumber = t6.TicketNumber
			LEFT JOIN #Equip7 t7 ON  j.TicketNumber = t7.TicketNumber
			LEFT JOIN #PressStatus st1 ON  j.TicketNumber = st1.TicketNumber
			LEFT JOIN #Equip2Status st2 ON  j.TicketNumber = st2.TicketNumber
			LEFT JOIN #Equip3Status st3 ON  j.TicketNumber = st3.TicketNumber
			LEFT JOIN #Equip4Status st4 ON  j.TicketNumber = st4.TicketNumber
			LEFT JOIN #Equip5Status st5 ON  j.TicketNumber = st5.TicketNumber
			LEFT JOIN #Equip6Status st6 ON  j.TicketNumber = st6.TicketNumber
			LEFT JOIN #Equip7Status st7 ON  j.TicketNumber = st7.TicketNumber
			LEFT JOIN #EstTime1 et1 ON  j.TicketNumber = et1.TicketNumber
			LEFT JOIN #EstTime2 et2 ON  j.TicketNumber = et2.TicketNumber
			LEFT JOIN #EstTime3 et3 ON  j.TicketNumber = et3.TicketNumber
			LEFT JOIN #EstTime4 et4 ON  j.TicketNumber = et4.TicketNumber
			LEFT JOIN #EstTime5 et5 ON  j.TicketNumber = et5.TicketNumber
			LEFT JOIN #EstTime6 et6 ON  j.TicketNumber = et6.TicketNumber
			LEFT JOIN #EstTime7 et7 ON  j.TicketNumber = et7.TicketNumber
			LEFT JOIN #EstRunTime1 er1 ON  j.TicketNumber = er1.TicketNumber
			LEFT JOIN #EstRunTime2 er2 ON  j.TicketNumber = er2.TicketNumber
			LEFT JOIN #EstRunTime3 er3 ON  j.TicketNumber = er3.TicketNumber
			LEFT JOIN #EstRunTime4 er4 ON  j.TicketNumber = er4.TicketNumber
			LEFT JOIN #EstRunTime5 er5 ON  j.TicketNumber = er5.TicketNumber
			LEFT JOIN #EstRunTime6 er6 ON  j.TicketNumber = er6.TicketNumber
			LEFT JOIN #EstRunTime7 er7 ON  j.TicketNumber = er7.TicketNumber
			LEFT JOIN #EstMRTime1 mr1 ON  j.TicketNumber = mr1.TicketNumber
			LEFT JOIN #EstMRTime2 mr2 ON  j.TicketNumber = mr2.TicketNumber
			LEFT JOIN #EstMRTime3 mr3 ON  j.TicketNumber = mr3.TicketNumber
			LEFT JOIN #EstMRTime4 mr4 ON  j.TicketNumber = mr4.TicketNumber
			LEFT JOIN #EstMRTime5 mr5 ON  j.TicketNumber = mr5.TicketNumber
			LEFT JOIN #EstMRTime6 mr6 ON  j.TicketNumber = mr6.TicketNumber
			LEFT JOIN #EstMRTime7 mr7 ON  j.TicketNumber = mr7.TicketNumber 
			LEFT JOIN #TicketShippingPreData tship ON j.TicketNumber = tship.TicketNumber


			SET @infoStr ='TotalRowsAffected|'+ CONVERT(varchar, @@ROWCOUNT)
		END TRY
		Begin CATCH
--		==================================[Do NOT change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertTickets'; SET @startTime = GETDATE();

		Begin TRY
			-- Insert the new records
			INSERT INTO [dbo].[TicketMaster] ([ID],[Source],[SourceTicketId],[TenantId],[OrderDate],[SourceCustomerId],[CustomerName],[CustomerPO],[SourcePriority],[SourceFinishType],[isBackSidePrinted],[IsSlitOnRewind],[UseTurretRewinder],[EstTotalRevenue],[SourceTicketType],[SourceStockTicketType],[PriceMode],[FinalUnwind],[IsOpen],[SourceStatus],[IsOnHold],[BackStageColorStrategy],[Pinfeed],[GeneralDescription],[IsPrintReversed],[SourceTicketNotes],[EndUserNum],[EndUserName],[Tab],[SizeAround],[ShrinkSleeveLayFlat],[Shape],[SourceCreatedOn],[SourceModifiedOn],[CreatedOn],[ModifiedOn],[InkStatus],[ITSName],[OTSName],[Press],[EquipId],[Equip3Id],[Equip4Id],[RewindEquipNum],[ITSAssocNum],[OTSAssocNum],[DateDone],[EndUserPO],[IsStockAllocated],[EstPackHrs],[ActPackHrs],[CustContact],[FinishNotes],[StockNotes],[CreditHoldOverride],[ShrinkSleeveOverLap],[ShrinkSleeveCutHeight],[PressDone],[EquipDone],[Equip3Done],[Equip4Done],[FinishDone],[EstRunHrs],[EstMRHrs],[Terms],[EstTime],[EquipEstTime],[Equip3EstTime],[Equip4EstTime],[EstFinHrs],[EquipEstRunHrs],[Equip3EstRunHrs],[Equip4EstRunHrs],[EstWuHrs],[EquipWashUpHours],[Equip3WashUpHours],[Equip4WashUpHours],[EquipMakeReadyHours],[Equip3MakeReadyHours],[Equip4MakeReadyHours]
			,[Equip2Id],[Equip5Id],[Equip6Id],[Equip7Id],[Equip2Done],[Equip5Done],[Equip6Done],[Equip7Done],[Equip1TaskName],[Equip2TaskName],
			[Equip3TaskName],[Equip4TaskName],[Equip5TaskName],[Equip6TaskName],[Equip7TaskName],[Equip5EstTime],[Equip6EstTime],[Equip7EstTime]
			,[Equip5EstRunHrs],[Equip6EstRunHrs],[Equip7EstRunHrs],
			[Equip2MakeReadyHours],[Equip5MakeReadyHours],[Equip6MakeReadyHours],[Equip7MakeReadyHours],[Equip5WashUpHours],[Equip6WashUpHours],[Equip7WashUpHours],
			[ShipStatus], [InternetSubmission],[SourceCompanyId],[SourceFacilityId],[TicketRowspace],[FinishStatus],[EnteredBy], [PreviousTicketNumber])
			SELECT 
				NEWID(),
				'Radius',
				Concat( j.CompNum,'_',j.PlantCode,'_',j.JobCode,'_',j.JobCmpNum),
				@TenantId,
				j.JobCreateDate,
				cust.CustCode,
				cust.custname,
				rn.CustRef,
				p.SourcePriority, 
				sf.SourceFinishType, -- FinishType
				null, -- isprintreversed
				null, -- slit ON rewind
				null, --  useTurret rewinder
				ISNULL(jso.OrderedValue, 0),
				CASE WHEN j.JobType IN( 0,1,2) THEN 1 WHEN j.JobType = 10 THEN 5  ELSE 0 END ,
				0, -- source stock ticket type
				null, -- add it later price mode
				f.UDValue, -- final unwind
				CASE WHEN j.JobStatus IN( 10,20) THEN 1 ELSE 0 END,
				j.StatusCode,
				CASE WHEN j.StatusCode like '%hold%'  THEN 1 ELSE 0 END,
				null, -- backstage color strategy
				wiProf.[wi-p-pinfeed], -- pinfeed
				g.[wih-code2],  -- general description
				wiProf.[wi-p-reverse-print], -- IsPrint reversed
				j.JobText, -- source ticketnotes
				Cust.CustCode, -- end user num
				cust.CustName, -- end user name
				null, -- Tab
				TS.SizeAround, -- SizeAround -- Add it later once infromation is available
				null, -- shink sleve flat
				TS.Shape, -- Shape -- Add it later FROM wi-profile
				j.JobCreateDate,
				Cast(j.LastUpdatedDateTime AS datetime2),
				GETUTCDATE(),
				GETUTCDATE(),
				null,--tic.Ink_Status,
				rn.ITSName,--tic.ITSName,
				rn.OTSName,--tic.OTSName,
				t1.PRESS,--tic.Press,
				t2.Equip2Id,--tic.Equip_ID,
				t3.Equip3Id,--tic.Equip3_ID,
				t4.Equip4Id,--tic.Equip4_ID,
				t5.Equip5Id,--tic.RewindEquipNum,
				rn.ITSAssocNum,--tic.ITSAssocNum,
				rn.OTSAssocNum,--tic.OTSAssocNum,
				j.completeddate, -- Date Done
				null,--tic.EndUserPO,
				null,--tic.Stock_Allocated,
				null,--tic.EstPackHrs,
				null,--tic.ActPackHrs,
				rn.YourContact,--tic.CustContact, revisit later
				null,--tic.FinishNotes,
				null,--tic.StockNotes,
				null,--tic.CreditHoldOverride,
				null,--tic.ShrinkSleeve_OverLap,
				null,--tic.ShrinkSleeve_CutHeight,
				st1.TaskStatus,--tic.PressDone,
				st2.TaskStatus,--tic.Equip_Done,
				st3.TaskStatus,--tic.Equip3_Done,
				st4.TaskStatus,--tic.Equip4_Done,
				st5.TaskStatus,--tic.FinishDone,
				er1.EstRunTime,--tic.EstRunHrs,
				mr1.EstMRTime,--tic.EstMRHrs,
				null,--tic.Terms,
				ISNULL(et1.EstTime,0),--tic.EstTime,
				ISNULL(et2.EstTime,0),--tic.Equip_EstTime,
				ISNULL(et3.EstTime,0),--tic.Equip3_EstTime,
				ISNULL(et4.EstTime,0),--tic.Equip4_EstTime,
				ISNULL(et5.EstTime,0),--tic.EstFinHrs,
				er2.EstRunTime,--tic.Equip_EstRunHrs,
				er3.EstRunTime,--tic.Equip3_EstRunHrs,
				er4.EstRunTime,--tic.Equip4_EstRunHrs,
				null,--tic.EstWuHrs,
				null,--tic.Equip_WashUpHours,
				null,--tic.Equip3_WashUpHours,
				null,--tic.Equip4_WashUpHours,
				mr2.EstMRTime,--tic.Equip_MakeReadyHours,
				mr3.EstMRTime,--tic.Equip3_MakeReadyHours,
				mr4.EstMRTime,--tic.Equip4_MakeReadyHours
				t2.Equip2Id,
				t5.Equip5Id,
				t6.Equip6Id,
				t7.Equip7Id,
				st2.TaskStatus,
				st5.TaskStatus,
				st6.TaskStatus,
				st7.TaskStatus,
				st1.TaskName,
				st2.TaskName,
				st3.TaskName,
				st4.TaskName,
				st5.TaskName,
				st6.TaskName,
				st7.TaskName,
				ISNULL(et5.EstTime,0),
				ISNULL(et6.EstTime,0),
				ISNULL(et7.EstTime,0),
				er5.EstRunTime,
				er6.EstRunTime,
				er7.EstRunTime,
				mr2.EstMRTime,
				mr5.EstMRTime,
				mr6.EstMRTime,
				mr7.EstMRTime,
				null,--[Equip5WashUpHours]
				null,--[Equip6WashUpHours]
				null,--[Equip7WashUpHours]
				tship.ShippingStatus,--[ShipStatus]
				NULL, --[InternetSubmission]
				j.CompNum,
				j.PlantCode,
				TS.GapDown,
				NULL, -- FinishStatus
				j.LastUserCode,
				NULL -- PreviousTicketNumber
			FROM #PV_Jobs j
			LEFT JOIN #PV_Job_SO_Value jso on j.CompNum = jso.CompNum and j.PlantCode = jso.PlantCode and j.JobCode = jso.JobCode
			LEFT JOIN PV_Customer cust ON j.CustCode = cust.CustCode
			LEFT join #TicketPriority p ON j.TicketNumber = p.TicketNumber
			LEFT JOIN #FinalUnwind f ON j.TicketNumber = f.TicketNumber
			Left Join #GeneralDescription g on j.TicketNumber = g.TicketNumber
			LEFT JOIN(SELECT DISTINCT korder,kco,[wi-p-pinfeed],[wi-p-reverse-print]
						FROM  [wi-profile])  wiProf 
						ON j.JobCode = wiProf.korder AND j.CompNum = wiProf.kco
			Left join #ToolSpec TS ON j.TicketNumber = TS.TicketNumber
			LEFT JOIN #RepresentativeNames rn ON j.TicketNumber = rn.TicketNumber -- TODO - after clarification
			LEFT JOIN #SourceFinishType sf ON j.TicketNumber = sf.TicketNumber
			LEFT JOIN #Press t1 ON  j.TicketNumber = t1.TicketNumber
			LEFT JOIN #Equip2 t2 ON  j.TicketNumber = t2.TicketNumber
			LEFT JOIN #Equip3 t3 ON  j.TicketNumber = t3.TicketNumber
			LEFT JOIN #Equip4 t4 ON  j.TicketNumber = t4.TicketNumber
			LEFT JOIN #Equip5 t5 ON  j.TicketNumber = t5.TicketNumber
			LEFT JOIN #Equip6 t6 ON  j.TicketNumber = t6.TicketNumber
			LEFT JOIN #Equip7 t7 ON  j.TicketNumber = t7.TicketNumber
			LEFT JOIN #PressStatus st1 ON  j.TicketNumber = st1.TicketNumber
			LEFT JOIN #Equip2Status st2 ON  j.TicketNumber = st2.TicketNumber
			LEFT JOIN #Equip3Status st3 ON  j.TicketNumber = st3.TicketNumber
			LEFT JOIN #Equip4Status st4 ON  j.TicketNumber = st4.TicketNumber
			LEFT JOIN #Equip5Status st5 ON  j.TicketNumber = st5.TicketNumber
			LEFT JOIN #Equip6Status st6 ON  j.TicketNumber = st6.TicketNumber
			LEFT JOIN #Equip7Status st7 ON  j.TicketNumber = st7.TicketNumber
			LEFT JOIN #EstTime1 et1 ON  j.TicketNumber = et1.TicketNumber
			LEFT JOIN #EstTime2 et2 ON  j.TicketNumber = et2.TicketNumber
			LEFT JOIN #EstTime3 et3 ON  j.TicketNumber = et3.TicketNumber
			LEFT JOIN #EstTime4 et4 ON  j.TicketNumber = et4.TicketNumber
			LEFT JOIN #EstTime5 et5 ON  j.TicketNumber = et5.TicketNumber
			LEFT JOIN #EstTime6 et6 ON  j.TicketNumber = et6.TicketNumber
			LEFT JOIN #EstTime7 et7 ON  j.TicketNumber = et7.TicketNumber
			LEFT JOIN #EstRunTime1 er1 ON  j.TicketNumber = er1.TicketNumber
			LEFT JOIN #EstRunTime2 er2 ON  j.TicketNumber = er2.TicketNumber
			LEFT JOIN #EstRunTime3 er3 ON  j.TicketNumber = er3.TicketNumber
			LEFT JOIN #EstRunTime4 er4 ON  j.TicketNumber = er4.TicketNumber
			LEFT JOIN #EstRunTime5 er5 ON  j.TicketNumber = er5.TicketNumber
			LEFT JOIN #EstRunTime6 er6 ON  j.TicketNumber = er6.TicketNumber
			LEFT JOIN #EstRunTime7 er7 ON  j.TicketNumber = er7.TicketNumber
			LEFT JOIN #EstMRTime1 mr1 ON  j.TicketNumber = mr1.TicketNumber
			LEFT JOIN #EstMRTime1 mr2 ON  j.TicketNumber = mr2.TicketNumber
			LEFT JOIN #EstMRTime1 mr3 ON  j.TicketNumber = mr3.TicketNumber
			LEFT JOIN #EstMRTime1 mr4 ON  j.TicketNumber = mr4.TicketNumber
			LEFT JOIN #EstMRTime1 mr5 ON  j.TicketNumber = mr5.TicketNumber
			LEFT JOIN #EstMRTime1 mr6 ON  j.TicketNumber = mr6.TicketNumber
			LEFT JOIN #EstMRTime1 mr7 ON  j.TicketNumber = mr7.TicketNumber
			LEFT JOIN #TicketShippingPreData tship ON j.TicketNumber = tship.TicketNumber


			WHERE j.TicketNumber NOT IN (SELECT TicketNumber FROM #MatchingTickets) 
			AND j.JobCode IS NOT NULL

			SET @infoStr ='TotalRowsAffected|'+ CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do NOT change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END

	-- Delete temporary table
	DROP TABLE IF EXISTS #PV_Jobs
	DROP TABLE IF EXISTS #PV_Job_SO_Value
	DROP TABLE IF EXISTS #PV_JobSteps
	DROP TABLE IF EXISTS #MatchingTickets
	DROP TABLE IF EXISTS #FinalUnwind
	DROP TABLE IF EXISTS #GeneralDescription
	DROP TABLE IF EXISTS #TicketPriority
	DROP TABLE IF EXISTS #ToolSpec
	DROP TABLE IF EXISTS #RepresentativeNames
	DROP TABLE IF EXISTS #SourceFinishType
	DROP TABLE IF EXISTS #AllEquipCalc

	DROP TABLE IF EXISTS #Press
	DROP TABLE IF EXISTS #Equip2
	DROP TABLE IF EXISTS #Equip3
	DROP TABLE IF EXISTS #Equip4
	DROP TABLE IF EXISTS #Equip5
	DROP TABLE IF EXISTS #Equip6
	DROP TABLE IF EXISTS #Equip7
	
	DROP TABLE IF EXISTS #pressCalc
	DROP TABLE IF EXISTS #Equip2Calc
	DROP TABLE IF EXISTS #Equip3Calc
	DROP TABLE IF EXISTS #Equip4Calc
	DROP TABLE IF EXISTS #Equip5Calc
	DROP TABLE IF EXISTS #Equip6Calc
	DROP TABLE IF EXISTS #Equip7Calc


	 DROP TABLE IF EXISTS #PressStatus 
	 DROP TABLE IF EXISTS #Equip2Status 
	 DROP TABLE IF EXISTS #Equip3Status 
	 DROP TABLE IF EXISTS #Equip4Status 
	 DROP TABLE IF EXISTS #Equip5Status 
	 DROP TABLE IF EXISTS #Equip6Status 
	 DROP TABLE IF EXISTS #Equip7Status 


	DROP TABLE IF EXISTS #EstTime1
	DROP TABLE IF EXISTS #EstTime2
	DROP TABLE IF EXISTS #EstTime3
	DROP TABLE IF EXISTS #EstTime4
	DROP TABLE IF EXISTS #EstTime5
	DROP TABLE IF EXISTS #EstTime6
	DROP TABLE IF EXISTS #EstTime7


	DROP TABLE IF EXISTS #EstRunTime1
	DROP TABLE IF EXISTS #EstRunTime2
	DROP TABLE IF EXISTS #EstRunTime3
	DROP TABLE IF EXISTS #EstRunTime4
	DROP TABLE IF EXISTS #EstRunTime5
	DROP TABLE IF EXISTS #EstRunTime6
	DROP TABLE IF EXISTS #EstRunTime7

	
--	    ========================[final commit log (do NOT change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END