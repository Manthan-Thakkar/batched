CREATE VIEW [dbo].[view_TicketTaskRaw]
AS		
		WITH TicketTaskRaw as (
		  SELECT TT.TicketId,
		  CASE WHEN  MAX(FR.ID) is null THEN 0 ELSE 1 END as FeasibleRoutesString,
		  CASE 
			WHEN ( MAX(SR.Id) is null and Max(SO.id) is null and Max(cast( TT.IsProductionReady as int)) = 1 )
				OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 0)
				OR (MAX(SR.Id) is null and Max(cast( SO.IsScheduled as int ))= 1 and MAX (cast( TT.IsProductionReady as int)) = 1)
			THEN 1 ELSE 0 END as ProductionReady,
		 Case When (Max(cast( SR.IsPinned as int))= 1) Then  'Locked' Else 'Unlocked' END as LockStatus,
         Case When (Max(cast( SR.IsPinned as int))= 1) Then  MAX(SR.PinType) Else NULL END as LockType
			FROM TicketTask TT WITH (nolock)
				INNER JOIN TicketMaster TM with (nolock) on TT.TicketId = TM.ID
				INNER JOIN EquipmentMaster EmPress with (nolock) on EmPress.SourceEquipmentId = COALESCE(TM.Press, TM.EquipId, TM.Equip2Id, TM.Equip3Id, TM.Equip4Id, TM.RewindEquipNum, TM.Equip6Id, Equip7Id)				LEFT JOIN FeasibleRoutes FR with (nolock) on TT.Id = FR.TaskId and FR.RouteFeasible = 1
				LEFT JOIN ScheduleOverride SO with (nolock) on TT.TicketId = SO.TicketId and TT.TaskName = SO.TaskName 
				LEFT JOIN ScheduleReport SR with (nolock) on SR.SourceTicketId = TM.SourceTicketId and SR.TaskName = TT.TaskName
		  WHERE 
				((IsProductionReady = 0 and  Sr.Id is null)
				OR (IsProductionReady = 1 and(  SO.IsScheduled = 0 or Sr.Id is null)))
				AND TT.IsComplete = 0
				GROUP BY TT.TicketId , TT.TaskName
		),
		TicketTaskFeasiblility as (
			SELECT TicketId ,  CASE WHEN MIN(FeasibleRoutesString) = 0 THEN 0 ELSE 1 END As TaskFeasible , Max(ProductionReady) as ProductionReadyTicket , Max(LockStatus) as LockStatus,Max(LockType) as LockType
			FROM TicketTaskRaw  GROUP BY TicketId
		)
		SELECT * FROM TicketTaskFeasiblility
GO