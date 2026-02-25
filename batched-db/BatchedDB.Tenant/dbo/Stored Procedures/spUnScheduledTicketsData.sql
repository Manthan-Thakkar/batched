CREATE PROCEDURE [dbo].[spUnScheduledTicketsData]
	@PageNumber AS INT = 1,
	@RowsOfPage AS INT = 10,
	@SortingColumn AS VARCHAR(100) = '+number',
	@startDate AS DATETIME = NULL,
	@endDate AS DATETIME = NULL,
    @sourceTicketNumbers AS UDT_SINGLEFIELDFILTER readonly,
    @customers AS UDT_SINGLEFIELDFILTER readonly,
    @csr AS UDT_SINGLEFIELDFILTER readonly,
    @salesPerson AS UDT_SINGLEFIELDFILTER readonly,
    @facilities AS UDT_SINGLEFIELDFILTER readonly,
	@workcenters AS UDT_SINGLEFIELDFILTER readonly
AS
BEGIN  
		;With TicketTaskRaw as (
		
		  select 
			 TT.TicketId,
		  CASE WHEN  MAX(FR.ID) is null THEN 0 ELSE 1 END as FeasibleRoutesString,
		  CASE 
		  WHEN ( MAX(SR.Id) is null and Max(SO.id) is null and Max(cast( TT.IsProductionReady as int)) = 1 )
		   OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 0)
		   OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 1)
		  THEN 1 ELSE 0 ENd as ProductionReady
		  from TicketTask TT with (nolock)
		     inner join TicketMaster TM with (nolock) on TT.TicketId = TM.ID
			 inner join EquipmentMaster EmPress with (nolock) on TM.Press = EmPress.SourceEquipmentId
			 left join FeasibleRoutes FR with (nolock) on TT.Id = FR.TaskId and FR.RouteFeasible = 1
			 left join ScheduleOverride SO with (nolock) on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
			 left join ScheduleReport SR with (nolock) on SR.SourceTicketId = TM.SourceTicketId and SR.TaskName = TT.TaskName
		  where 
			( (IsProductionReady = 0 and  Sr.Id is null)
		  OR (IsProductionReady = 1 and(  SO.IsScheduled = 0 or Sr.Id is null)))
		  and TT.IsComplete = 0
			 and ((SELECT Count(1) FROM @customers) = 0  OR TM.CustomerName IN (SELECT field FROM @customers))
			 and ((SELECT Count(1) FROM @sourceTicketNumbers) = 0  OR TM.SourceTicketId IN (SELECT field FROM @sourceTicketNumbers))
			 and ((SELECT Count(1) FROM @csr) = 0  OR TM.ITSName IN (SELECT field FROM @csr))
			 and ((SELECT Count(1) FROM @salesPerson) = 0  OR TM.OTSName IN (SELECT field FROM @salesPerson))
			 and ((SELECT Count(1) FROM @facilities) = 0  OR EmPress.FacilityId IN (SELECT field FROM @facilities))
			 and ((SELECT Count(1) FROM @workcenters) = 0  OR EmPress.WorkcenterTypeId IN (SELECT field FROM @workcenters))
		  group by TT.TicketId , TT.TaskName
		),
		TicketTaskFeasiblility as (
		
		select TicketId ,  CASE WHEN MIN(FeasibleRoutesString) = 0 THEN 0 ELSE 1 END As TaskFeasible , Max(ProductionReady) as ProductionReadyTicket from TicketTaskRaw  group by TicketId
		)

		select * into #TicketTaskRaw from TicketTaskFeasiblility

		-- substrate calculation
		select TS.TicketId,SM.SourceStockId ,TS.Width as SubstrateWidth
		into #Substrate
		from TicketStock TS with (nolock) inner join #TicketTaskRaw TR with (nolock) on TS.TicketId = TR.TicketId and TS.Sequence =2
		inner join StockMaterial SM  with (nolock)on TS.StockMaterialId =  SM.Id

		--- Stocknum1 calculation
		select TS.TicketId,SM.SourceStockId 
		into #StockNum1
		from TicketStock TS with (nolock) inner join #TicketTaskRaw TR with (nolock)on TS.TicketId = TR.TicketId and TS.Sequence =1
		inner join StockMaterial SM with (nolock) on TS.StockMaterialId =  SM.Id

		--- TicketTool calculation
		select TT.TicketId,TI.SourceToolingId
		into #TicketTool
		from TicketTool TT with (nolock) inner join #TicketTaskRaw TR with (nolock)on TT.TicketId = TR.TicketId and TT.Sequence =1
		inner join ToolingInventory TI with (nolock) on TT.ToolingId = TI.ID

		--- Colors calculation Temp
		select TTR.TicketId,TAV.Value as Colors
		into #Colors
		from 
		#TicketTaskRaw TTR with (nolock) inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = 'Colors'

		--- Varnish calculation Temp
		select TTR.TicketId,TAV.Value as Varnish
		into #Varnish
		from 
		#TicketTaskRaw TTR with (nolock) inner join TicketAttributeValues TAV with (nolock) on TTr.TicketId = TAV.TicketId and TAV.Name = 'Varnish'
	
		select 
			TM.ID as TicketId,
			TM.SourceStatus as TicketStatus,--
			TM.SourceTicketId as Number,--
			EM.WorkCenterName as WorkcenterName,
			EM.WorkcenterTypeId as WorkcenterId, 
			EM.FacilityId as FacilityId,
			TM.CustomerName as CustomerName,--
			SM.SourceStockId as Substrate,
			SM1.SourceStockId as StockNum1,
			TPP.ArtWorkComplete as ArtDone,--
			TPP.InkReceived  as InkIn,--
			TPP.ProofComplete as ProofDone,--
			TPP.PlateComplete as PlateDone,--
			TPP.ToolsReceived as ToolsIn,--
		    Case when Tpp.StockReceived like '%In%' THEN 1 ELSE 0 END as StockIn ,--
			TM.GeneralDescription as GeneralDescription,--
			TD.Quantity as TicketQuantity,--
			TS.ShipByDateTime as ShipByDate,--
			TTF.TaskFeasible as TaskFeasible,--
			TM.ITSName as CSR,--
			TM.OTSName as SalesPerson,--
			TTO.SourceToolingId as MainTool,--
			TM.OrderDate as OrderDate,--
			SM.SubstrateWidth as SubstrateWidth,--
			TD.CoreSize as CoreSize,--
			TD.CalcNumLeftoverRolls as NumberOfCores,--
			TD.EsitmatedLength as EstLength,
			ISNULL(TSC.CustomerRankScore,0) * ISNULL(TSC.DueDateScore,0) * ISNULL(TSC.PriorityScore,0) * ISNULL(TSC.RevenueScore,0) as TicketScore,--,
			TVColor.Colors as Colors,
			TVarnish.Varnish as Varnish,
			TM.SourceTicketNotes as TicketNotes,--
			TTf.ProductionReadyTicket as ProductionReadyTicket
		INTO #unscheduledTickets
		From #TicketTaskRaw TTF with (nolock)
			inner join  TicketMaster TM with (nolock) on TTF.TicketId = TM.ID
			inner join TicketPreProcess TPP with (nolock) on TTF.TicketId = TPP.TicketId
			inner join EquipmentMaster EM with (nolock) on TM.Press= EM.SourceEquipmentId
			inner join TicketDimensions TD with (nolock) on TTF.TicketId = TD.TicketId
			inner join TicketShipping TS with (nolock) on TS.TicketId = TM.ID
			inner join TicketScore TSC with (nolock) on TSC.TicketId = TM.ID
			left join #Colors TVColor on TVColor.TicketId = TM.ID 
			left join #Varnish TVarnish on TVarnish.TicketId = TM.ID 
			left join #Substrate SM with (nolock) on TM.ID = SM.TicketId 
			left join #StockNum1 SM1 with (nolock)  on TM.ID = SM1.TicketId 
			left join #TicketTool TTO with (nolock) on TM.ID = TTO.TicketId
			

			SELECT * into #FinalList FROM #unscheduledTickets 
			Order by 

			CASE WHEN @SortingColumn = '+number'  THEN Number  END ,
			CASE WHEN @SortingColumn = '-number'  THEN  Number END DESC,
			CASE WHEN @SortingColumn = '+customer'  THEN CustomerName END ,
			CASE WHEN @SortingColumn = '-customer'  THEN CustomerName END DESC,
			CASE WHEN @SortingColumn = '+taskFeasible'  THEN TaskFeasible END ,
			CASE WHEN @SortingColumn = '-taskFeasible'  THEN TaskFeasible END DESC,
			CASE WHEN @SortingColumn = '+csr'  THEN CSR END ,
			CASE WHEN @SortingColumn = '-csr'  THEN CSR END DESC,
			CASE WHEN @SortingColumn = '+shipByDate'  THEN ShipByDate END ,
			CASE WHEN @SortingColumn = '-shipByDate'  THEN ShipByDate END DESC,
			CASE WHEN @SortingColumn = '+quantity'  THEN cast( TicketQuantity  as decimal)END ,
			CASE WHEN @SortingColumn = '-quantity'  THEN cast( TicketQuantity as decimal) END DESC,
			CASE WHEN @SortingColumn = '+salesPerson'  THEN SalesPerson END ,
			CASE WHEN @SortingColumn = '-salesPerson'  THEN SalesPerson END DESC,
			CASE WHEN @SortingColumn = '+status'  THEN TicketStatus END ,
			CASE WHEN @SortingColumn = '-status'  THEN TicketStatus END DESC,
			CASE WHEN @SortingColumn = '+art'  THEN ArtDone END ,
			CASE WHEN @SortingColumn = '-art'  THEN ArtDone END DESC,
			CASE WHEN @SortingColumn = '+proof'  THEN ProofDone END ,
			CASE WHEN @SortingColumn = '-proof'  THEN ProofDone END DESC,
			CASE WHEN @SortingColumn = '+plate'  THEN PlateDone END ,
			CASE WHEN @SortingColumn = '-plate'  THEN PlateDone END DESC,
			CASE WHEN @SortingColumn = '+ink'  THEN InkIn  END ,
			CASE WHEN @SortingColumn = '-ink'  THEN InkIn  END DESC,
			CASE WHEN @SortingColumn = '+tools'  THEN ToolsIn END ,
			CASE WHEN @SortingColumn = '-tools'  THEN ToolsIn END DESC,
			CASE WHEN @SortingColumn = '+stock'  THEN StockIn END ,
			CASE WHEN @SortingColumn = '-stock'  THEN StockIn END DESC,
			CASE WHEN @SortingColumn = '+generalDesc'  THEN GeneralDescription END ,
			CASE WHEN @SortingColumn = '-generalDesc'  THEN GeneralDescription END DESC,
			CASE WHEN @SortingColumn = 'default'  THEN ShipByDate END

		OFFSET (@PageNumber-1)*@RowsOfPage ROWS
			FETCH NEXT @RowsOfPage ROWS ONLY


		    -- tbl_ScheduleReport
	SELECT *, 'tbl_unscheduledTickets' AS __dataset_tableName FROM #FinalList 

	----- csr
	Select distinct CSR as CSR , 'tbl_csr' AS __dataset_tableName 
	from #unscheduledTickets

		----- sales person
	Select distinct SalesPerson as SalesPerson , 'tbl_salesPerson' AS __dataset_tableName 
	from #unscheduledTickets 

	---- Ticket numbers
	Select distinct(Number) As TicketNumber , 'tbl_ticketNumbers' AS __dataset_tableName 
	from #unscheduledTickets 

	---- CustomerNames
	
	Select distinct(CustomerName) As CustomerName , 'tbl_customerNames' AS __dataset_tableName 
	from #unscheduledTickets 

		---- Facilities
	
	Select distinct(FacilityId) As FacilityId , 'tbl_facilities' AS __dataset_tableName 
	from #unscheduledTickets 

		---- workcenter
	Select WorkcenterId as WorkcenterId, Max(WorkcenterName) As WorkcenterName, 'tbl_workcenters' AS __dataset_tableName 
	from #unscheduledTickets group by WorkcenterId

	select
	FR.TicketId as TicketId,
	TaskId as TaskId,
	TT.TaskName as TaskName,
	EM.ID as EquipmentId,
	EM.Name as EquipmentName ,
	FR.RouteFeasible as RouteFeasible ,
	FR.ConstraintDescription as ConstraintDescription,
	TT.Sequence as Sequence,
	'tbl_openRoutes' AS __dataset_tableName 
	from FeasibleRoutes FR   with (nolock)
	inner join #FinalList UT  with (nolock) on UT.TicketId = FR.TicketId 
	inner JOIN TicketTask TT  with (nolock) on FR.TaskId = TT.Id
	LEFT JOIN EquipmentMaster EM  with (nolock) on EM.ID = FR.EquipmentId order by TT.Sequence

	select
		Tt.TicketId as TicketId , 
		TT.TaskName as TaskName ,
		Tt.[Sequence] as Sequence,
		TT.Id as TaskId,
		CASE WHEN TT.EstTotalHours = 0 THEN 1 ELSE ceiling(TT.EstTotalHours  * 60) END as EstTotalHours,
		CASE WHEN (TTO.EstimatedMinutes IS NOT NULL) THEN 1 ELSE 0 END AS IsEstMinsEdited,
		CASE WHEN (TTO.IsCompleted IS NOT NULL) THEN 1 ELSE 0 END AS IsStatusEdited,
		'tbl_ticketTasks' AS __dataset_tableName 
	from TicketTask TT  with (nolock) inner join #FinalList UT  with (nolock) on TT.TicketId = UT.TicketId
	left join TicketTaskOverride TTO with (nolock) on TT.TicketId = TTO.TicketId and TT.TaskName = TTO.TaskName
	where TT.IsComplete = 0 order by Sequence

	select SO.TicketId as TicketId,
	MAX(SO.Notes) as Notes ,
	Max(cast(SO.IsScheduled as int)) as IsScheduled,
	'tbl_ScheduleOverride' AS __dataset_tableName 
	from ScheduleOverride SO  with (nolock) inner join #FinalList UT  with (nolock) on SO.TicketId = UT.TicketId group by SO.TicketId

		DROP TABLE IF EXISTS #unscheduledTickets;
		DROP TABLE IF EXISTS #FinalList;
		DROP TABLE IF EXISTS #Substrate;
		DROP TABLE IF EXISTS #StockNum1;
		DROP TABLE IF EXISTS #TicketTaskRaw 
		DROP TABLE IF EXISTS #TicketTool
		DROP TABLE IF EXISTS #Colors 
		DROP TABLE IF EXISTS #Varnish
		
END