CREATE PROCEDURE [dbo].[spCalculateTicketTaskDslValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN
		SELECT  
			TM.[Id]						AS __ticketId,
			TM.[Id]						AS __contextId,

			TM.Press					AS Equipment1Number_dsl,
			TM.EquipID					AS Equipment2Number_dsl,
			TM.Equip3ID					AS Equipment3Number_dsl, 
			TM.Equip4ID					AS Equipment4Number_dsl, 
			TM.Equip5Id					AS Equipment5Number_dsl,
			TM.Equip6Id					AS Equipment6Number_dsl,
			TM.Equip7Id					AS Equipment7Number_dsl,

			EMPress.WorkCenterName		AS Equipment1Workcenter_dsl,
			EMEquip.WorkCenterName		AS Equipment2Workcenter_dsl,
			EMEquip3.WorkCenterName		AS Equipment3Workcenter_dsl,
			EMEquip4.WorkCenterName		AS Equipment4Workcenter_dsl,
			EMEquip5.WorkCenterName		AS Equipment5Workcenter_dsl,
			EMEquip6.WorkCenterName		AS Equipment6Workcenter_dsl,
			EMEquip7.WorkCenterName		AS Equipment7Workcenter_dsl,

			TM.PressDone				AS Equipment1Done_dsl,
			TM.EquipDone				AS Equipment2Done_dsl,
			TM.Equip3Done				AS Equipment3Done_dsl,
			TM.Equip4Done				AS Equipment4Done_dsl,
			TM.Equip5Done				AS Equipment5Done_dsl,
			TM.Equip6Done				AS Equipment6Done_dsl,
			TM.Equip7Done				AS Equipment7Done_dsl,

			TPP.ArtWorkComplete			AS ArtDone_dsl,
			TPP.PlateComplete			AS PlateDone_dsl,
			TPP.InkReceived				AS InkRecieved_dsl,
			TPP.InkReceived				AS InkReceived_dsl,
			TPP.StockReceived			AS StockIn_dsl,
			TPP.ToolsReceived			AS ToolsIn_dsl,
			TPP.ProofComplete			AS ProofDone_dsl,

			TM.EstTime					AS Equipment1EstTime_dsl,
			TM.EquipEstTime				AS Equipment2EstTime_dsl,
			TM.Equip3EstTime			AS Equipment3EstTime_dsl,
			TM.Equip4EstTime			AS Equipment4EstTime_dsl,
			TM.Equip5EstTime			AS Equipment5EstTime_dsl,
			TM.Equip6EstTime			AS Equipment6EstTime_dsl,
			TM.Equip7EstTime			AS Equipment7EstTime_dsl,

			TS.ShipByDateTime			AS ShipTime_dsl,
			TS.ShippingStatus			AS ShippingStatus_dsl,

			TM.EstRunHrs				AS Equipment1RunHours_dsl,
			TM.EquipEstRunHrs			AS Equipment2RunHours_dsl,
			TM.Equip3EstRunHrs			AS Equipment3RunHours_dsl,
			TM.Equip4EstRunHrs			AS Equipment4RunHours_dsl,
			TM.Equip5EstRunHrs			AS Equipment5RunHours_dsl,
			TM.Equip6EstRunHrs			AS Equipment6RunHours_dsl,
			TM.Equip7EstRunHrs			AS Equipment7RunHours_dsl,

			TD.EsitmatedLength			AS EstimatedFootage_dsl,
			TM.SourceStatus				AS TicketStatus_dsl,

			TD.Quantity					AS TicketQuantity_dsl,
			TD.ActualQuantity			AS ActualQuantity_dsl,
			TM.SourceFinishType			AS FinishType_dsl,
			TM.SourcePriority			AS TicketPriority_dsl,
			TM.SourceTicketType			AS TicketType_dsl,

			TM.EstWuHrs					AS Equipment1WUHours_dsl,
			TM.EquipWashUpHours			AS Equipment2WUHours_dsl,
			TM.Equip3WashUpHours		AS Equipment3WUHours_dsl,
			TM.Equip4WashUpHours		AS Equipment4WUHours_dsl,
			TM.Equip5WashUpHours		AS Equipment5WUHours_dsl,
			TM.Equip6WashUpHours		AS Equipment6WUHours_dsl,
			TM.Equip7WashUpHours		AS Equipment7WUHours_dsl,

			TM.EstMRHrs					AS Equipment1MRHours_dsl,
			TM.EquipMakeReadyHours		AS Equipment2MRHours_dsl,
			TM.Equip3MakeReadyHours		AS Equipment3MRHours_dsl,
			TM.Equip4MakeReadyHours		AS Equipment4MRHours_dsl,
			TM.Equip5MakeReadyHours		AS Equipment5MRHours_dsl,
			TM.Equip6MakeReadyHours		AS Equipment6MRHours_dsl,
			TM.Equip7MakeReadyHours		AS Equipment7MRHours_dsl,

			TM.InkStatus				AS InkStatus_dsl,
			TM.EstPostPressHours		AS EstPostPressHours_dsl,
			TM.DependentSourceTicketId	AS DependentTicket_dsl,
			TM.OrderDate				AS OrderDate_dsl

		FROM 
			TicketMaster TM							WITH(NOLOCK)
			INNER JOIN	@tickets T									ON	TM.ID = T.TicketId
			INNER JOIN	TicketDimensions TD			WITH(NOLOCK)	ON	TM.ID = TD.TicketId
			INNER JOIN	TicketPreProcess TPP		WITH(NOLOCK)	ON	TM.ID = TPP.TicketId
			INNER JOIN	TicketShipping TS			WITH(NOLOCK)	ON	TM.ID = TS.TicketId
			LEFT JOIN	EquipmentMaster EMPress		WITH(NOLOCK)	ON	TM.Press = EMPress.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip		WITH(NOLOCK)	ON	TM.EquipID = EMEquip.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip3	WITH(NOLOCK)	ON	TM.Equip3ID = EMEquip3.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip4	WITH(NOLOCK)	ON	TM.Equip4ID = EMEquip4.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip5	WITH(NOLOCK)	ON	TM.Equip5Id = EMEquip5.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip6	WITH(NOLOCK)	ON	TM.Equip6Id = EMEquip6.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip7	WITH(NOLOCK)	ON	TM.Equip7Id = EMEquip7.SourceEquipmentId;


		IF (select top 1 source from TicketMaster) != 'Radius' 
			BEGIN
			;With SheeterTimeEstimates as
				(
						SELECT  
							Tm.ID as TicketId
							,SUM(Round((cast(b.[OrderQuantity] as float)/nullif(c.PiecesOperation,0)/nullif(c.Operations_Hour,0)),4)) as [EstSheeterRunTime]
							,sum(c.Option_Hours1*c.Option_Qty1 + c.Option_Hours2*c.Option_Qty2 + c.Option_Hours3*c.Option_Qty3 + c.Option_Hours4*c.Option_Qty4 + c.Option_Hours5*c.Option_Qty5 + c.Option_Hours6*c.Option_Qty6)/nullif(COUNT(b.UniqueProdID),0) as [EstSheeterMRTime]
						FROM 
							[dbo].[ticket] a
						Inner join TicketMaster TM on a.Number = TM.SourceTicketId
						Left Join 
							[dbo].[ticketItem] b 
							on a.Number = b.TicketNumber
						Left Join 
							[dbo].[product_postpress] c 
							on b.UniqueProdID=c.UniqueProdID
						Where 
							a.FinishType='Sheeted' 
							AND a.RewindEquipNum is not null 
							AND a.RewindEquipNum <> ''
							AND Tm.ID in (SELECT TicketId from @tickets)
						Group by 
							Tm.ID
				)


				select 
					TicketId               AS __ticketId,
					TicketId               AS __contextId,
					EstSheeterRunTime     as SheeterRunHours_dsl,
					EstSheeterMRTime      AS SheeterMakeReadyHours_dsl
				from SheeterTimeEstimates;

			END

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC1TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Press = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC2TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.EquipID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC3TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip3ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC4TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip4ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC5TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip5Id = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC6TimecardQuantity_dsl
			from TicketMaster TM WITH(NOLOCK)
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip6ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC7TimecardQuantity_dsl
			from TicketMaster TM
			inner join EquipmentMaster EM_Source on TM.Equip7ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id in (SELECT TicketId from @tickets)
			group by TM.Id
			option(recompile)

END

