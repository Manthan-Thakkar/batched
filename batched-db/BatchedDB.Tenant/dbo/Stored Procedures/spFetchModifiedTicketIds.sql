CREATE PROCEDURE dbo.spFetchModifiedTicketIds
    @Since DATETIME
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRANSACTION;

	SELECT DISTINCT tic.TicketId
	FROM
	(
	SELECT TM.Id AS TicketId from TicketMaster TM
		LEFT JOIN EquipmentMaster EMPress WITH(NOLOCK) on TM.Press = EMPress.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip WITH(NOLOCK) on TM.EquipID = EMEquip.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip3 WITH(NOLOCK) on TM.Equip3ID = EMEquip3.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip4 WITH(NOLOCK) on TM.Equip4ID = EMEquip4.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip5 WITH(NOLOCK) on TM.RewindEquipNum = EMEquip5.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip6 WITH(NOLOCK) on TM.Equip6Id = EMEquip6.SourceEquipmentId
		LEFT JOIN EquipmentMaster EMEquip7 WITH(NOLOCK) on TM.Equip7Id = EMEquip7.SourceEquipmentId
		where @Since IS NULL
			OR TM.ModifiedOn >= @Since
			OR EMPress.ModifiedOn >= @Since
			OR EMEquip.ModifiedOn >= @Since
			OR EMEquip3.ModifiedOn >= @Since
			OR EMEquip4.ModifiedOn >= @Since
			OR EMEquip5.ModifiedOn >= @Since
			OR EMEquip6.ModifiedOn >= @Since
			OR EMEquip7.ModifiedOn >= @Since
	UNION 
	SELECT TicketId from TicketNote where @Since IS NULL
					OR ModifiedOn >= @Since
	UNION 
	SELECT TicketId from TicketPreProcess where @Since IS NULL
					OR ModifiedOn >= @Since
	UNION 
	SELECT TicketId from TicketShipping where @Since IS NULL
					OR ModifiedOn >= @Since
	UNION 
	SELECT TicketId from TicketDimensions where @Since IS NULL
					OR ModifiedOn >= @Since
	UNION 
	SELECT TicketId from TimecardInfo where @Since IS NULL
					OR ModifiedOn >= @Since
	UNION 
	SELECT TicketId from ToolingInventory ti
		INNER JOIN TicketTool tt on ti.id = tt.ToolingId
	where @Since IS NULL
	OR ti.ModifiedOn >= @Since
	OR tt.ModifiedOn >= @Since
	UNION 
	SELECT TicketId from StockMaterial sm
		INNER JOIN TicketStock TS ON TS.[StockMaterialId] = SM.Id 
		where @Since IS NULL
		OR sm.ModifiedOn >= @Since
		OR TS.ModifiedOn >= @Since
	UNION 
	SELECT Tif.TicketId	FROM ProductColorInfo PCI 
		INNER JOIN [ProductMaster] PM  on PCI.ProductId = PM.Id
		INNER JOIN [TicketItemInfo] TIF ON TIF.[ProductId] = PM.Id
		WHERE @Since IS NULL 
		OR PCI.ModifiedOn >= @Since
		OR PM.ModifiedOn >= @Since
		OR TIF.ModifiedOn >= @Since
	) tic
	INNER JOIN TicketMaster tm on tic.TicketId = tm.ID
	INNER JOIN TicketShipping ts on tic.TicketId = ts.TicketId
	LEFT JOIN LastJobsRun ljr on tm.SourceTicketId = ljr.Ticket_No
	WHERE
	tm.SourceTicketType <> 0
	AND
	((tm.IsOpen = 1 and ts.ShipByDateTime >= GETUTCDATE()-181)
	OR ts.ShippedOnDate >= GETUTCDATE()-3
	OR ljr.Ticket_No is not null
	)

  COMMIT TRANSACTION;
END