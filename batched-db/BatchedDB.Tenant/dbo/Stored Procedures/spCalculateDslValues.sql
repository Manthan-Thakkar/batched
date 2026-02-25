CREATE PROCEDURE [dbo].[spCalculateDslValues]
	@tickets udt_ticketInfo ReadOnly
AS
BEGIN
	--########## DO NOT CHANGE ANY PROJECTION COLUMN NAMES #############

	DROP TABLE IF EXISTS #TempStockInventory;
	DROP TABLE IF EXISTS #Tickets;
	DROP TABLE IF EXISTS #BaseTicketStock;
	DROP TABLE IF EXISTS #TempTicketMaster;
	DROP TABLE IF EXISTS #TempToolingSource;

	CREATE TABLE #Tickets
	(
		TicketId VARCHAR(36) NOT NULL PRIMARY KEY
	);

	INSERT INTO #Tickets (TicketId)
	SELECT DISTINCT TicketId
	FROM @tickets;

	SELECT
		TS.Id,
		TS.TicketId,
		TS.StockMaterialId,
		TS.Width,
		TS.Length,
		TS.RoutingNo,
		TS.Sequence,
		TS.[Notes]
	INTO #BaseTicketStock
	FROM TicketStock TS WITH(NOLOCK)
	INNER JOIN #Tickets T ON TS.TicketId = T.TicketId;

	CREATE NONCLUSTERED INDEX IX_BaseTicketStock_Ticket_Sequence
		ON #BaseTicketStock (TicketId, Sequence);

	CREATE NONCLUSTERED INDEX IX_BaseTicketStock_Ticket_Routing_Sequence
		ON #BaseTicketStock (TicketId, RoutingNo, Sequence);

	CREATE NONCLUSTERED INDEX IX_BaseTicketStock_StockMaterial
		ON #BaseTicketStock (StockMaterialId);

	SELECT TM.*
	INTO #TempTicketMaster
	FROM TicketMaster TM WITH(NOLOCK)
	INNER JOIN #Tickets T ON TM.ID = T.TicketId;

	SELECT
		TT.TicketId,
		TT.Sequence,
		TI.ID,
		TI.FlexoHotStamping,
		TI.DieSize,
		TI.GearTeeth,
		TI.Location,
		TI.SourceToolingId,
		TI.LinerCaliper,
		TI.NoAround,
		TI.Shape,
		TI.ToolDeliveryDate,
		TT.Description
	INTO #TempToolingSource
	FROM [dbo].[ToolingInventory] AS [TI] WITH(NOLOCK)
		INNER JOIN [dbo].[TicketTool] AS [TT] WITH(NOLOCK) ON [TT].[ToolingId] = [TI].[Id]
		INNER JOIN #Tickets AS [T] ON [T].TicketId = [TT].[TicketId];

	CREATE NONCLUSTERED INDEX IX_TempToolingSource_Ticket_Sequence
		ON #TempToolingSource (TicketId, Sequence);

	
	--ProductColorInfo
	SELECT distinct
		TIF.[TicketId] 				AS __ticketId,
		PCI.[Id] 					AS __contextId,
		PCI.[SourceColor] 			AS ProductColor_dsl,
		PCI.[Unit] 					AS ColorUnit_dsl,
		PCI.[SourceInkType] 		AS ProductInkType_dsl,
		PCI.[SourceNotes]           AS ProductColorNotes_dsl,
		PCI.[Anilox]				AS Anilox_dsl,
		PCI.SourceColorItemType		AS SourceColorItemType_dsl,
		PCI.ColorSide				AS ProductColorSide_dsl
	FROM 
		ProductColorInfo PCI WITH(NOLOCK)
	INNER JOIN 
		[ProductMASter] PM WITH(NOLOCK)
			on PCI.ProductId = PM.Id
	INNER JOIN 
			[TicketItemInfo] TIF WITH(NOLOCK)
				ON TIF.[ProductId] = PM.Id
	WHERE 
		TIF.[TicketId] IN (SELECT TicketId FROM #Tickets)

	SELECT
		[TIF].[TicketId] 			AS [__ticketId],
		MIN([PCI].[Id])				AS [__contextId],
		LEFT(
			STRING_AGG(
				CONVERT(NVARCHAR(MAX), CONCAT([PCI].[Unit], ' - ', [PCI].[SourceColor])),
				', '
			) WITHIN GROUP (
				ORDER BY [PM].[ProductNum], [PCI].[Unit], [PCI].[SourceColor]
			)
			, 4000
		) AS [ColorByUnit_dsl]

	FROM [dbo].[ProductColorInfo] [PCI] WITH(NOLOCK)
	INNER JOIN [dbo].[ProductMaster] [PM] WITH(NOLOCK) ON [PCI].[ProductId] = [PM].[Id]
	INNER JOIN [dbo].[TicketItemInfo] [TIF] WITH(NOLOCK) ON [TIF].[ProductId] = [PM].[Id]
	INNER JOIN @tickets [T] ON [TIF].[TicketId] = [T].[TicketId]
	GROUP BY [TIF].[TicketId];

	--ProductMASter
	SELECT distinct
		TIF.[TicketId]	 			AS __ticketId,
		PM.[Id] 					AS __contextId,
		PM.[NumColors] 				AS NumProductColors_dsl,
		PM.[SlitOnRewind] 			AS SlitOnRewind_dsl,
		PM.[SourceProductGroup] 	AS ProductGroup_dsl,
		PM.[ColorDesc] 				AS ProductColorDescription_dsl,
		PM.[ToolingNotes] 			AS ProductToolingNotes_dsl,
		PM.[NumFloods]				AS NumFloodsProduct_dsl,
		PM.ProductNum				AS ProductNum_dsl,
		PM.PlateId					AS PlateId_dsl,
		PM.CustomField1				AS CustomField1_dsl,
		PM.CriticalQuality			AS CriticalQuality_dsl,
		PM.ProdDescr                AS ProdDesc_dsl,
		PM.MaterialTrac             AS MaterialTrac_dsl,
		PM.ColumnPerf               AS ColumnPerf_dsl,
		PM.RowPerf                  AS RowPerf_dsl,
		PM.ProductGroupId           AS ProductGroupId_dsl,
		PM.ProductPopup1			AS ProductPopup1_dsl,
		PM.ProductPopup2			AS ProductPopup2_dsl,
		PM.ProductPopup3			AS ProductPopup3_dsl,
		PM.ProductPopup4			AS ProductPopup4_dsl,
		PM.ProductPopup5			AS ProductPopup5_dsl,
		PM.ProductPopup6			AS ProductPopup6_dsl,
		TIF.WorkStatus				AS WorkStatus_dsl,
		PM.Jobtype					AS Jobtype_dsl,
		PM.ProductType				AS ProductType_dsl,
		PM.SheetPackType			AS SheetPackType_dsl,
		PM.CoreWidth				AS ProductCoreWidth_dsl,
		PM.Notes					AS ProductNotes_dsl,
		PM.FinishedWidth			AS FinishedWidth_dsl,
		PM.FinishedLength			AS FinishedLength_dsl,
		PM.EquipNoColors			AS EquipNoColors_dsl,
		PM.EquipNoFloods			AS EquipNoFloods_dsl,
		PM.RevisionNumber			AS ProductRevisionNumber_dsl
	FROM 
		ProductMaster PM WITH(NOLOCK)
	INNER JOIN 
		[TicketItemInfo] TIF WITH(NOLOCK) 
			ON TIF.[ProductId] = PM.Id
	WHERE 
		TIF.[TicketId] IN (SELECT TicketId FROM #Tickets)

	--StockMaterial_seq1
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Group] 					AS Stock1GroupName_dsl,
		SM.[LinerCaliper] 			AS Stock1LinerCaliper_dsl,
		SM.[Classification] 		AS Stock1Classification_dsl,
		SM.[FaceStock] 				AS Stock1FaceStock_dsl,
		SM.[FaceColor] 				AS Stock1FaceColor_dsl,
		SM.[SourceStockId] 			AS Stock1Number_dsl,
		SM.[AdhesiveClass] 			AS Stock1AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS Stock1MFGSpecNum_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		#BaseTicketStock TS 
			ON TS.[StockMaterialId] = SM.Id 
				AND TS.[Sequence] = 1
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	--StockMaterial_seq2
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Classification] 		AS Stock2Classification_dsl,
		SM.[FaceStock] 				AS Stock2FaceStock_dsl,
		SM.[SourceStockId] 			AS Stock2Number_dsl,
		SM.[Group] 					AS Stock2GroupName_dsl,
		SM.[FaceColor] 				AS Stock2FaceColor_dsl,
		SM.[LinerCaliper] 			AS Stock2LinerCaliper_dsl,
		SM.[AdhesiveClass] 			AS Stock2AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS Stock2MFGSpecNum_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		#BaseTicketStock TS 
			ON TS.[StockMaterialId] = SM.Id 
			AND TS.[Sequence] = 2
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	--StockMaterial_seq3
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Group] 					AS Stock3GroupName_dsl,
		SM.[FaceColor] 				AS Stock3FaceColor_dsl,
		SM.[SourceStockId] 			AS Stock3Number_dsl,
		SM.[FaceStock] 				AS Stock3FaceStock_dsl,
		SM.[Classification] 		AS Stock3Classification_dsl,
		SM.[LinerCaliper] 			AS Stock3LinerCaliper_dsl,
		SM.[AdhesiveClass] 			AS Stock3AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS Stock3MFGSpecNum_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		#BaseTicketStock TS 
			ON TS.[StockMaterialId] = SM.Id 
			AND TS.[Sequence] = 3
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	--Will execute only when the routingNo is present in the TicketStock table
	DROP TABLE IF EXISTS #TempTicketStocks

	SELECT 
		TS.Id,
		ts.TicketId,
		TS.StockMaterialId,
		TS.Width,
		TS.Length,
		TS.RoutingNo,
		SM.[Group] 			,
		SM.[LinerCaliper] 	,		
		SM.[Classification] ,		
		SM.[FaceStock] 		,		
		SM.[FaceColor] 		,		
		SM.[SourceStockId] 	,		
		SM.[AdhesiveClass] 	,		
		SM.[MFGSpecNum]		,	
		TS.[NOTES]			,
		ROW_NUMBER() OVER (PARTITION BY TS.TicketId, TS.RoutingNo ORDER BY TS.Sequence) AS StockSeq
	INTO #TempTicketStocks
	FROM #BaseTicketStock TS
	INNER JOIN StockMaterial SM WITH (NOLOCK) ON TS.StockMaterialId = SM.Id
	WHERE
	TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	AND TS.RoutingNo IS NOT NULL

	CREATE NONCLUSTERED INDEX IX_TempTicketStocks_Ticket_Routing_Seq
		ON #TempTicketStocks (TicketId, RoutingNo, StockSeq);


	--StockMaterial_seq1
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip1Stock1GroupName_dsl,
		TS1.[LinerCaliper] 			    AS Equip1Stock1LinerCaliper_dsl,
		TS1.[Classification] 		    AS Equip1Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip1Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip1Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip1Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip1Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip1Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip1Stock1Description_dsl,

		TS2.[Group] 					AS Equip1Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip1Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip1Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip1Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip1Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip1Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip1Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip1Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip1Stock2Description_dsl,

		TS3.[Group] 					AS Equip1Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip1Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip1Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip1Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip1Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip1Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip1Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip1Stock3MFGSpecNum_dsl,
		TS3.[Notes]						AS Equip1Stock3Description_dsl,

		TS4.[Group] 					AS Equip1Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip1Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip1Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip1Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip1Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip1Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip1Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip1Stock4MFGSpecNum_dsl,
		TS4.[Notes]						AS Equip1Stock4Description_dsl,
		
		TS5.[Group] 					AS Equip1Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip1Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip1Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip1Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip1Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip1Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip1Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip1Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip1Stock5Description_dsl
	FROM 
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE [TS1].[RoutingNo] = 1 and ts1.StockSeq = 1

	--StockMaterial_seq2
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip2Stock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip2Stock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip2Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip2Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip2Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip2Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip2Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip2Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip2Stock1Description_dsl,

		TS2.[Group] 					AS Equip2Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip2Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip2Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip2Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip2Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip2Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip2Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip2Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip2Stock2Description_dsl,

		TS3.[Group] 					AS Equip2Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip2Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip2Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip2Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip2Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip2Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip2Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip2Stock3MFGSpecNum_dsl,	
		TS3.[Notes]						AS Equip2Stock3Description_dsl,

		TS4.[Group] 					AS Equip2Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip2Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip2Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip2Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip2Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip2Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip2Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip2Stock4MFGSpecNum_dsl,	
		TS4.[Notes]						AS Equip2Stock4Description_dsl,
		
		TS5.[Group] 					AS Equip2Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip2Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip2Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip2Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip2Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip2Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip2Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip2Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip2Stock5Description_dsl
	FROM
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND [TS1].[RoutingNo] = TS2.[RoutingNo] AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND [TS1].[RoutingNo] = TS3.[RoutingNo] AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND [TS1].[RoutingNo] = TS4.[RoutingNo] AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND [TS1].[RoutingNo] = TS5.[RoutingNo] AND TS5.StockSeq = 5
	WHERE [TS1].[RoutingNo] = 2 and ts1.StockSeq = 1

	--StockMaterial_seq3
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip3Stock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip3Stock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip3Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip3Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip3Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip3Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip3Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip3Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip3Stock1Description_dsl,

		TS2.[Group] 					AS Equip3Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip3Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip3Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip3Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip3Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip3Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip3Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip3Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip3Stock2Description_dsl,

		TS3.[Group] 					AS Equip3Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip3Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip3Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip3Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip3Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip3Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip3Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip3Stock3MFGSpecNum_dsl,	
		TS3.[Notes]						AS Equip3Stock3Description_dsl,

		TS4.[Group] 					AS Equip3Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip3Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip3Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip3Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip3Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip3Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip3Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip3Stock4MFGSpecNum_dsl,	
		TS4.[Notes]						AS Equip3Stock4Description_dsl,
		
		TS5.[Group] 					AS Equip3Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip3Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip3Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip3Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip3Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip3Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip3Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip3Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip3Stock5Description_dsl
	FROM 
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE [TS1].[RoutingNo] = 3 and ts1.StockSeq = 1

	--StockMaterial_seq4
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip4Stock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip4Stock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip4Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip4Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip4Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip4Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip4Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip4Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip4Stock1Description_dsl,

		TS2.[Group] 					AS Equip4Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip4Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip4Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip4Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip4Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip4Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip4Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip4Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip4Stock2Description_dsl,

		TS3.[Group] 					AS Equip4Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip4Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip4Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip4Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip4Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip4Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip4Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip4Stock3MFGSpecNum_dsl,	
		TS3.[Notes]						AS Equip4Stock3Description_dsl,

		TS4.[Group] 					AS Equip4Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip4Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip4Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip4Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip4Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip4Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip4Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip4Stock4MFGSpecNum_dsl,	
		TS4.[Notes]						AS Equip4Stock4Description_dsl,
		
		TS5.[Group] 					AS Equip4Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip4Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip4Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip4Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip4Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip4Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip4Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip4Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip4Stock5Description_dsl
	FROM 
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 4 and ts1.StockSeq = 1

	--StockMaterial_seq5
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip5Stock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip5Stock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip5Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip5Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip5Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip5Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip5Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip5Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip5Stock1Description_dsl,

		TS2.[Group] 					AS Equip5Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip5Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip5Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip5Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip5Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip5Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip5Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip5Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip5Stock2Description_dsl,

		TS3.[Group] 					AS Equip5Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip5Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip5Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip5Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip5Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip5Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip5Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip5Stock3MFGSpecNum_dsl,
		TS3.[Notes]						AS Equip5Stock3Description_dsl,	

		TS4.[Group] 					AS Equip5Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip5Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip5Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip5Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip5Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip5Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip5Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip5Stock4MFGSpecNum_dsl,	
		TS4.[Notes]						AS Equip5Stock4Description_dsl,		
		
		TS5.[Group] 					AS Equip5Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip5Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip5Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip5Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip5Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip5Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip5Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip5Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip5Stock5Description_dsl
	FROM 
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 5 and ts1.StockSeq = 1

	--StockMaterial_seq6
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip6Stock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip6Stock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip6Stock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip6Stock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip6Stock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip6Stock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip6Stock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip6Stock1MFGSpecNum_dsl,
		TS1.[Notes]						AS Equip6Stock1Description_dsl,	

		TS2.[Group] 					AS Equip6Stock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip6Stock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip6Stock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip6Stock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip6Stock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip6Stock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip6Stock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip6Stock2MFGSpecNum_dsl,
		TS2.[Notes]						AS Equip6Stock2Description_dsl,	

		TS3.[Group] 					AS Equip6Stock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip6Stock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip6Stock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip6Stock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip6Stock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip6Stock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip6Stock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip6Stock3MFGSpecNum_dsl,	
		TS3.[Notes]						AS Equip6Stock3Description_dsl,	

		TS4.[Group] 					AS Equip6Stock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip6Stock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip6Stock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip6Stock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip6Stock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip6Stock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip6Stock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip6Stock4MFGSpecNum_dsl,	
		TS4.[Notes]						AS Equip6Stock4Description_dsl,		
		
		TS5.[Group] 					AS Equip6Stock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip6Stock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip6Stock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip6Stock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip6Stock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip6Stock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip6Stock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip6Stock5MFGSpecNum_dsl,
		TS5.[Notes]						AS Equip6Stock5Description_dsl
	FROM 
		#TempTicketStocks TS1 
		LEFT JOIN #TempTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 6 and ts1.StockSeq = 1


	 --PlannedStockMaterial_seq1
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Group] 					AS PlannedStock1GroupName_dsl,
		SM.[LinerCaliper] 			AS PlannedStock1LinerCaliper_dsl,
		SM.[Classification] 		AS PlannedStock1Classification_dsl,
		SM.[FaceStock] 				AS PlannedStock1FaceStock_dsl,
		SM.[FaceColor] 				AS PlannedStock1FaceColor_dsl,
		SM.[SourceStockId] 			AS PlannedStock1Number_dsl,
		SM.[AdhesiveClass] 			AS PlannedStock1AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS PlannedStock1MFGSpecNum_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) on SM.id = TSA.ActualStockMaterialId
		INNER JOIN #BaseTicketStock TS ON TS.[StockMaterialId] = TSA.OriginalStockMaterialId AND TS.[Sequence] = 1
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	--PlannedStockMaterial_seq2
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Group] 					AS PlannedStock2GroupName_dsl,
		SM.[LinerCaliper] 			AS PlannedStock2LinerCaliper_dsl,
		SM.[Classification] 		AS PlannedStock2Classification_dsl,
		SM.[FaceStock] 				AS PlannedStock2FaceStock_dsl,
		SM.[FaceColor] 				AS PlannedStock2FaceColor_dsl,
		SM.[SourceStockId] 			AS PlannedStock2Number_dsl,
		SM.[AdhesiveClass] 			AS PlannedStock2AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS PlannedStock2MFGSpecNum_dsl
	FROM 
		StockMaterial SM
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) on SM.id = TSA.ActualStockMaterialId
		INNER JOIN #BaseTicketStock TS ON TS.[StockMaterialId] = TSA.OriginalStockMaterialId AND TS.[Sequence] = 2
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	
	--PlannedStockMaterial_seq3
	SELECT distinct
		TS.[TicketId] 				AS __ticketId,
		SM.[Id] 					AS __contextId,
		SM.[Group] 					AS PlannedStock3GroupName_dsl,
		SM.[LinerCaliper] 			AS PlannedStock3LinerCaliper_dsl,
		SM.[Classification] 		AS PlannedStock3Classification_dsl,
		SM.[FaceStock] 				AS PlannedStock3FaceStock_dsl,
		SM.[FaceColor] 				AS PlannedStock3FaceColor_dsl,
		SM.[SourceStockId] 			AS PlannedStock3Number_dsl,
		SM.[AdhesiveClass] 			AS PlannedStock3AdhesiveClass_dsl,
		SM.[MFGSpecNum]				AS PlannedStock3MFGSpecNum_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) on SM.id = TSA.ActualStockMaterialId
		INNER JOIN #BaseTicketStock TS ON TS.[StockMaterialId] = TSA.OriginalStockMaterialId AND TS.[Sequence] = 3
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	DROP TABLE IF EXISTS #TempPlannedTicketStocks
	SELECT distinct
		TS.[TicketId] 		,
		TS.[RoutingNo]		,
		SM.[Id] 			,
		SM.[Group] 			,
		SM.[LinerCaliper] 	,
		SM.[Classification] ,
		SM.[FaceStock] 		,
		SM.[FaceColor] 		,
		SM.[SourceStockId] 	,
		SM.[AdhesiveClass] 	,
		SM.[MFGSpecNum]		,
		ROW_NUMBER() OVER (PARTITION BY TS.TicketId, TS.RoutingNo ORDER BY TS.Sequence) AS StockSeq
	INTO #TempPlannedTicketStocks
	FROM 
		StockMaterial SM WITH(NOLOCK)
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) on SM.id = TSA.ActualStockMaterialId
		INNER JOIN #BaseTicketStock TS ON TS.[StockMaterialId] = TSA.OriginalStockMaterialId
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
		AND TS.RoutingNo IS NOT NULL

	CREATE NONCLUSTERED INDEX IX_TempPlannedTicketStocks_Ticket_Routing_Seq
		ON #TempPlannedTicketStocks (TicketId, RoutingNo, StockSeq);

			--PlannedStockMaterial_seq1
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip1PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip1PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip1PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip1PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip1PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip1PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip1PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip1PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip1PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip1PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip1PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip1PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip1PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip1PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip1PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip1PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip1PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip1PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip1PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip1PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip1PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip1PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip1PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip1PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip1PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip1PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip1PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip1PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip1PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip1PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip1PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip1PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip1PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip1PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip1PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip1PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip1PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip1PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip1PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip1PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 1 and ts1.StockSeq = 1

	--PlannedStockMaterial_seq2
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip2PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip2PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip2PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip2PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip2PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip2PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip2PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip2PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip2PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip2PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip2PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip2PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip2PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip2PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip2PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip2PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip2PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip2PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip2PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip2PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip2PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip2PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip2PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip2PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip2PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip2PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip2PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip2PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip2PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip2PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip2PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip2PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip2PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip2PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip2PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip2PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip2PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip2PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip2PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip2PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 2 and ts1.StockSeq = 1

	--PlannedStockMaterial_seq3
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip3PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip3PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip3PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip3PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip3PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip3PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip3PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip3PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip3PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip3PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip3PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip3PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip3PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip3PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip3PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip3PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip3PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip3PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip3PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip3PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip3PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip3PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip3PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip3PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip3PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip3PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip3PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip3PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip3PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip3PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip3PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip3PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip3PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip3PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip3PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip3PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip3PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip3PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip3PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip3PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 3 and ts1.StockSeq = 1

	--PlannedStockMaterial_seq4
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip4PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip4PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip4PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip4PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip4PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip4PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip4PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip4PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip4PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip4PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip4PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip4PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip4PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip4PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip4PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip4PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip4PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip4PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip4PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip4PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip4PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip4PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip4PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip4PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip4PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip4PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip4PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip4PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip4PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip4PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip4PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip4PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip4PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip4PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip4PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip4PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip4PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip4PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip4PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip4PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 4 and ts1.StockSeq = 1

	--PlannedStockMaterial_seq5
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip5PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip5PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip5PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip5PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip5PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip5PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip5PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip5PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip5PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip5PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip5PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip5PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip5PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip5PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip5PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip5PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip5PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip5PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip5PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip5PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip5PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip5PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip5PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip5PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip5PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip5PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip5PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip5PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip5PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip5PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip5PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip5PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip5PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip5PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip5PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip5PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip5PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip5PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip5PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip5PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 5 and ts1.StockSeq = 1

	--PlannedStockMaterial_seq6
	SELECT distinct
		TS1.[TicketId] 				AS __ticketId,
		TS1.[Id] 					AS __contextId,
		TS1.[Group] 					AS Equip6PlannedStock1GroupName_dsl,
		TS1.[LinerCaliper] 				AS Equip6PlannedStock1LinerCaliper_dsl,
		TS1.[Classification] 			AS Equip6PlannedStock1Classification_dsl,
		TS1.[FaceStock] 				AS Equip6PlannedStock1FaceStock_dsl,
		TS1.[FaceColor] 				AS Equip6PlannedStock1FaceColor_dsl,
		TS1.[SourceStockId] 			AS Equip6PlannedStock1Number_dsl,
		TS1.[AdhesiveClass] 			AS Equip6PlannedStock1AdhesiveClass_dsl,
		TS1.[MFGSpecNum]				AS Equip6PlannedStock1MFGSpecNum_dsl,

		TS2.[Group] 					AS Equip6PlannedStock2GroupName_dsl,
		TS2.[LinerCaliper] 				AS Equip6PlannedStock2LinerCaliper_dsl,
		TS2.[Classification] 			AS Equip6PlannedStock2Classification_dsl,
		TS2.[FaceStock] 				AS Equip6PlannedStock2FaceStock_dsl,
		TS2.[FaceColor] 				AS Equip6PlannedStock2FaceColor_dsl,
		TS2.[SourceStockId] 			AS Equip6PlannedStock2Number_dsl,
		TS2.[AdhesiveClass] 			AS Equip6PlannedStock2AdhesiveClass_dsl,
		TS2.[MFGSpecNum]				AS Equip6PlannedStock2MFGSpecNum_dsl,

		TS3.[Group] 					AS Equip6PlannedStock3GroupName_dsl,
		TS3.[LinerCaliper] 				AS Equip6PlannedStock3LinerCaliper_dsl,
		TS3.[Classification] 			AS Equip6PlannedStock3Classification_dsl,
		TS3.[FaceStock] 				AS Equip6PlannedStock3FaceStock_dsl,
		TS3.[FaceColor] 				AS Equip6PlannedStock3FaceColor_dsl,
		TS3.[SourceStockId] 			AS Equip6PlannedStock3Number_dsl,
		TS3.[AdhesiveClass] 			AS Equip6PlannedStock3AdhesiveClass_dsl,
		TS3.[MFGSpecNum]				AS Equip6PlannedStock3MFGSpecNum_dsl,

		TS4.[Group] 					AS Equip6PlannedStock4GroupName_dsl,
		TS4.[LinerCaliper] 				AS Equip6PlannedStock4LinerCaliper_dsl,
		TS4.[Classification] 			AS Equip6PlannedStock4Classification_dsl,
		TS4.[FaceStock] 				AS Equip6PlannedStock4FaceStock_dsl,
		TS4.[FaceColor] 				AS Equip6PlannedStock4FaceColor_dsl,
		TS4.[SourceStockId] 			AS Equip6PlannedStock4Number_dsl,
		TS4.[AdhesiveClass] 			AS Equip6PlannedStock4AdhesiveClass_dsl,
		TS4.[MFGSpecNum]				AS Equip6PlannedStock4MFGSpecNum_dsl,

		TS5.[Group] 					AS Equip6PlannedStock5GroupName_dsl,
		TS5.[LinerCaliper] 				AS Equip6PlannedStock5LinerCaliper_dsl,
		TS5.[Classification] 			AS Equip6PlannedStock5Classification_dsl,
		TS5.[FaceStock] 				AS Equip6PlannedStock5FaceStock_dsl,
		TS5.[FaceColor] 				AS Equip6PlannedStock5FaceColor_dsl,
		TS5.[SourceStockId] 			AS Equip6PlannedStock5Number_dsl,
		TS5.[AdhesiveClass] 			AS Equip6PlannedStock5AdhesiveClass_dsl,
		TS5.[MFGSpecNum]				AS Equip6PlannedStock5MFGSpecNum_dsl

	FROM 
		#TempPlannedTicketStocks TS1 
		LEFT JOIN #TempPlannedTicketStocks TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStocks TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS2.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStocks TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS2.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStocks TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS2.StockSeq = 5
	WHERE TS1.[RoutingNo] = 6 and ts1.StockSeq = 1

	----TicketDimensions
	SELECT
		TD.[TicketId] 									AS __ticketId,
		TD.[TicketId] 									AS __contextId,
		TD.[CalcFinishedRollLength]						AS FinishedRollLength_dsl,
		TD.[EsitmatedLength] 							AS EstimatedLength_dsl,
		TD.[ConsecutiveNumber] 							AS ConsecutiveNumber_dsl,
		TD.[CalcNumLeftoverRolls] 						AS NumLeftoverRolls_dsl,
		TD.[NumAcross] 									AS NumAcross_dsl,
		TD.[LabelRepeat] 								AS LabelRepeat_dsl,
		TD.[FinishedNumLabels] 							AS FinishedNumLabels_dsl,
		TD.[CoreSize] 									AS CoreSize_dsl,
		TD.[SizeAcross] 								AS SizeAcross_dsl,
		TD.[OutsideDiameter] 							AS OutsideDiameter_dsl,
		TD.[ActualQuantity] 							AS ActualQuantity_dsl,
		CAST(TD.[CalcNumStops] AS DECIMAL(38, 2))		AS NumStops_dsl,
		TD.[FinishedNumAcross]							AS FinishedNumAcross_dsl,
		TD.[CalcCoreWidth]								AS CoreWidth_dsl,
		TD.[NumAroundPlate]								AS NumAroundPlate_dsl,
		TD.[Shape]										AS Shape_dsl,
		TD.[Quantity]									AS Quantity_dsl,
		CAST(TD.[CalcLinearLength] AS DECIMAL(38, 2))	AS LinealLength_dsl,
		TD.[ColumnSpace]								AS ColumnSpace_dsl,
		TD.[OverRunLength]								AS OverRun_dsl,
		TD.NoPlateChanges                               AS NumberPlateChanges_dsl,
		TD.PrintRepeat									AS PrintRepeat_dsl,
		TD.FlatSizeWidth								AS FlatSizeWidth_dsl,
		TD.FlatSizeLength								AS FlatSizeLength_dsl,
		TD.PackQuantity									AS PackQuantity_dsl,
		TD.NumberUp										AS NumberUp_dsl
	FROM 
		TicketDimensions TD WITH(NOLOCK)
	WHERE 
		TD.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--TicketItemInfo
	SELECT
		TIF.[TicketId]							AS __ticketId,
		TIF.[Id] 								AS __contextId,
		TIF.[NumColors] 						AS NumItemColors_dsl,
		TIF.[OrderQuantity] 					AS ItemOrderQuantity_dsl,
		TIF.[MachineCount]						AS MachineCount_dsl,
		TIF.[SalesOrderNumber]					AS SalesOrderNumber_dsl,
		TIF.[SalesOrderDate]					AS SOrderDate_dsl
	FROM 
		TicketItemInfo TIF WITH(NOLOCK)
	WHERE 
		TIF.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--TicketMASter
	SELECT
		TM.[ID] 					AS __ticketId,
		TM.[ID] 					AS __contextId,
		TM.[FinalUnwind] 			AS FinalUnwind_dsl,
		TM.[SourceCustomerId] 		AS SourceCustomerId_dsl,
		TM.[CustomerName] 			AS CustomerName_dsl,
		TM.[CustomerPO] 			AS CustomerPO_dsl,
		TM.[SourceFinishType] 		AS FinishType_dsl,
		TM.[IsBacksidePrinted] 		AS BackSidePrinting_dsl,
		TM.[BackStageColorStrategy] AS BackStageColorStrategy_dsl,
		TM.[PriceMode] 				AS PriceMode_dsl,
		TM.[SourceTicketId] 		AS TicketNumber_dsl,
		TM.[Pinfeed]				AS Pinfeed_dsl,
		TM.[GeneralDescription]		AS GeneralDescription_dsl,
		TM.IsPrintReversed			AS IsPrintReversed_dsl,
		TM.UseTurretRewinder		AS UseTurretRewinder_dsl,
		TM.SourceTicketNotes        AS TicketNotes_dsl,
		TM.EndUserNum               AS EndUserNum_dsl,
		TM.EndUserName              AS EndUserName_dsl,
		TM.Tab                      AS Tab_dsl,
		TM.SizeAround				AS SizeAround_dsl,
		TM.ShrinkSleeveLayFlat		AS ShrinkSleeveLayFlat_dsl,
		TM.Shape					AS ToolingShape_dsl,
		TM.SourcePriority			AS TicketPriority_dsl,
		TM.InkStatus				AS InkStatus_dsl,
		TM.Terms					AS Terms_dsl,
		TM.RotoQuoteNumber			AS RotoQuoteNumber_dsl,
		TM.PlateStatus				AS PlateStatus_dsl,
		TM.FlexPackGusset			AS FlexPackGusset_dsl,
		TM.FlexPackHeight			AS FlexPackHeight_dsl,
		TM.SourceTicketType			AS TicketType_dsl,
		TM.EstPostPressHours		AS EstPostPressHours_dsl,
		TM.CoreType					AS CoreType_dsl,
		TM.IsStockAllocated			AS StockAllocated_dsl,
		TM.FinishNotes				AS FinishingNotes_dsl,
		TM.ShipStatus				AS ShipStatus_dsl,
		TM.Press_Status				AS PressStatus_dsl,
		TM.InternetSubmission		AS InternetSubmission_dsl,
		CAST(TM.TicketRowspace AS decimal(38, 4)) AS TicketRowspace_dsl,
		TM.OrderDate				AS OrderDate_dsl,
		TM.FinishStatus				AS FinishStatus_dsl,
		TM.SourceStatus				AS TicketStatus_dsl,
		TM.EnteredBy				AS EnteredBy_dsl,
		TM.PreviousTicketNumber		AS PrevJobNum_dsl,
		ISNULL(F.SourceFacilityId, '')          AS TicketLocation_dsl,
		TM.EstimatedPressSpeed		AS EstimatedPressSpeed_dsl
	FROM 
		#TempTicketMaster TM
		LEFT JOIN Facility F WITH(NOLOCK) 
		ON TM.FacilityId = F.ID
	WHERE 
		TM.[Id] IN (SELECT TicketId FROM #Tickets)
	--TicketShipping
	SELECT
		TS.[TicketId] 				AS __ticketId,
		TS.[ID] 					AS __contextId,
		TS.ShipState				AS ShipState_dsl,
		TS.[ShipByDateTime]			AS ShipTime_dsl	
	FROM 
		TicketShipping TS WITH(NOLOCK)
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--TicketNoteSELECT
	SELECT
		TN.[TicketId] 				AS __ticketId,
		TN.[ID] 					AS __contextId,
		TN.[Description] 			AS UserDefinedDescription_dsl,
		TN.[Notes] 					AS UserDefinedNote_dsl
	FROM 
		TicketNote TN WITH(NOLOCK)
	WHERE 
		TN.[TicketId] IN (SELECT TicketId FROM #Tickets)



	SELECT DISTINCT [StockMaterialId], [DimWidth], [DimLength], [Location]
	INTO #TempStockInventory
	FROM StockInventory
	WHERE [StockUsed] = 0

	CREATE NONCLUSTERED INDEX IX_TempStockInventory_Material_Dims
		ON #TempStockInventory (StockMaterialId, DimWidth, DimLength)
		INCLUDE (Location);


	--TicketStock_seq1
	SELECT
		TS.[TicketId] 						AS __ticketId,
		TS.[ID] 							AS __contextId,
		TS.[Width] 							AS Stock1Width_dsl,
		TS.[Length]							AS Stock1Length_dsl,
		STRING_AGG(TSI.[Location], ', ')	AS Stock1Location_dsl
	FROM 
		#BaseTicketStock TS
	LEFT JOIN #TempStockInventory TSI
		ON TS.[StockMaterialId] = TSI.[StockMaterialId]
			AND TS.[Width] = TSI.[DimWidth]
			AND (TS.[Length] IS NULL OR TSI.[DimLength] IS NULL OR TS.[Length] = TSI.[DimLength])
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 1
	GROUP BY
		TS.[TicketId], TS.[Id], TS.[Width], TS.[Length];


	--TicketStock_seq2
	SELECT
		TS.[TicketId] 						AS __ticketId,
		TS.[ID] 							AS __contextId,
		TS.[Width] 							AS Stock2Width_dsl,
		TS.[Length]							AS Stock2Length_dsl,
		STRING_AGG(TSI.[Location], ', ')	AS Stock2Location_dsl
	FROM 
		#BaseTicketStock TS
	LEFT JOIN #TempStockInventory TSI
		ON TS.[StockMaterialId] = TSI.[StockMaterialId]
			AND TS.[Width] = TSI.[DimWidth]
			AND (TS.[Length] IS NULL OR TSI.[DimLength] IS NULL OR TS.[Length] = TSI.[DimLength])
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 2
	GROUP BY
		TS.[TicketId], TS.[Id], TS.[Width], TS.[Length];


	--TicketStock_seq3
	SELECT
		TS.[TicketId] 						AS __ticketId,
		TS.[ID] 							AS __contextId,
		TS.[Width] 							AS Stock3Width_dsl,
		TS.[Length]							AS Stock3Length_dsl,
		STRING_AGG(TSI.[Location], ', ')	AS Stock3Location_dsl
	FROM 
		#BaseTicketStock TS
	LEFT JOIN #TempStockInventory TSI
		ON TS.[StockMaterialId] = TSI.[StockMaterialId]
			AND TS.[Width] = TSI.[DimWidth]
			AND (TS.[Length] IS NULL OR TSI.[DimLength] IS NULL OR TS.[Length] = TSI.[DimLength])
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 3
	GROUP BY
		TS.[TicketId], TS.[Id], TS.[Width], TS.[Length];

	DROP TABLE IF EXISTS #TempTicketStockDimensions

	SELECT
		TS.[TicketId] 					,
		TS.[ID] 						,
		TS.[Width] 						,
		TS.[Length]						,
		STRING_AGG(TSI.[Location], ', ') as Location,
		TS.[RoutingNo],
		ROW_NUMBER() OVER (PARTITION BY TS.TicketId, TS.RoutingNo ORDER BY TS.sequence) AS StockSeq
	INTO #TempTicketStockDimensions
	FROM 
		#BaseTicketStock TS
	LEFT JOIN #TempStockInventory TSI
		ON TS.[StockMaterialId] = TSI.[StockMaterialId]
			AND TS.[Width] = TSI.[DimWidth]
			AND (TS.[Length] IS NULL OR TSI.[DimLength] IS NULL OR TS.[Length] = TSI.[DimLength])
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) AND RoutingNo IS NOT NULL
	GROUP BY
		TS.[TicketId], TS.[Id], TS.[Width], TS.[Length],TS.Sequence,TS.RoutingNo;

	CREATE NONCLUSTERED INDEX IX_TempTicketStockDimensions_Ticket_Routing_Seq
		ON #TempTicketStockDimensions (TicketId, RoutingNo, StockSeq);



	--TicketStock_seq1
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip1Stock1Width_dsl,
		TD1.[Length]						AS Equip1Stock1Length_dsl,
		TD1.Location						AS Equip1Stock1Location_dsl,

		TD2.[Width] 						AS Equip1Stock2Width_dsl,
		TD2.[Length]						AS Equip1Stock2Length_dsl,
		TD2.Location						AS Equip1Stock2Location_dsl,

		TD3.[Width] 						AS Equip1Stock3Width_dsl,
		TD3.[Length]						AS Equip1Stock3Length_dsl,
		TD3.Location						AS Equip1Stock3Location_dsl,

		TD4.[Width] 						AS Equip1Stock4Width_dsl,
		TD4.[Length]						AS Equip1Stock4Length_dsl,
		TD4.Location						AS Equip1Stock4Location_dsl,

		TD5.[Width] 						AS Equip1Stock5Width_dsl,
		TD5.[Length]						AS Equip1Stock5Length_dsl,
		TD5.Location						AS Equip1Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 1 and TD1.StockSeq = 1

	--TicketStock_seq2
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip2Stock1Width_dsl,
		TD1.[Length]						AS Equip2Stock1Length_dsl,
		TD1.Location						AS Equip2Stock1Location_dsl,

		TD2.[Width] 						AS Equip2Stock2Width_dsl,
		TD2.[Length]						AS Equip2Stock2Length_dsl,
		TD2.Location						AS Equip2Stock2Location_dsl,

		TD3.[Width] 						AS Equip2Stock3Width_dsl,
		TD3.[Length]						AS Equip2Stock3Length_dsl,
		TD3.Location						AS Equip2Stock3Location_dsl,

		TD4.[Width] 						AS Equip2Stock4Width_dsl,
		TD4.[Length]						AS Equip2Stock4Length_dsl,
		TD4.Location						AS Equip2Stock4Location_dsl,

		TD5.[Width] 						AS Equip2Stock5Width_dsl,
		TD5.[Length]						AS Equip2Stock5Length_dsl,
		TD5.Location						AS Equip2Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 2 and TD1.StockSeq = 1 

	--TicketStock_seq3
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip3Stock1Width_dsl,
		TD1.[Length]						AS Equip3Stock1Length_dsl,
		TD1.Location						AS Equip3Stock1Location_dsl,
													
		TD2.[Width] 						AS Equip3Stock2Width_dsl,
		TD2.[Length]						AS Equip3Stock2Length_dsl,
		TD2.Location						AS Equip3Stock2Location_dsl,
													
		TD3.[Width] 						AS Equip3Stock3Width_dsl,
		TD3.[Length]						AS Equip3Stock3Length_dsl,
		TD3.Location						AS Equip3Stock3Location_dsl,
													
		TD4.[Width] 						AS Equip3Stock4Width_dsl,
		TD4.[Length]						AS Equip3Stock4Length_dsl,
		TD4.Location						AS Equip3Stock4Location_dsl,
													
		TD5.[Width] 						AS Equip3Stock5Width_dsl,
		TD5.[Length]						AS Equip3Stock5Length_dsl,
		TD5.Location						AS Equip3Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 3 and TD1.StockSeq = 1

	--TicketStock_seq4
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip4Stock1Width_dsl,
		TD1.[Length]						AS Equip4Stock1Length_dsl,
		TD1.Location						AS Equip4Stock1Location_dsl,

		TD2.[Width] 						AS Equip4Stock2Width_dsl,
		TD2.[Length]						AS Equip4Stock2Length_dsl,
		TD2.Location						AS Equip4Stock2Location_dsl,

		TD3.[Width] 						AS Equip4Stock3Width_dsl,
		TD3.[Length]						AS Equip4Stock3Length_dsl,
		TD3.Location						AS Equip4Stock3Location_dsl,

		TD4.[Width] 						AS Equip4Stock4Width_dsl,
		TD4.[Length]						AS Equip4Stock4Length_dsl,
		TD4.Location						AS Equip4Stock4Location_dsl,

		TD5.[Width] 						AS Equip4Stock5Width_dsl,
		TD5.[Length]						AS Equip4Stock5Length_dsl,
		TD5.Location						AS Equip4Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 4 and TD1.StockSeq = 1 

	--TicketStock_seq5
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip5Stock1Width_dsl,
		TD1.[Length]						AS Equip5Stock1Length_dsl,
		TD1.Location						AS Equip5Stock1Location_dsl,

		TD2.[Width] 						AS Equip5Stock2Width_dsl,
		TD2.[Length]						AS Equip5Stock2Length_dsl,
		TD2.Location						AS Equip5Stock2Location_dsl,

		TD3.[Width] 						AS Equip5Stock3Width_dsl,
		TD3.[Length]						AS Equip5Stock3Length_dsl,
		TD3.Location						AS Equip5Stock3Location_dsl,

		TD4.[Width] 						AS Equip5Stock4Width_dsl,
		TD4.[Length]						AS Equip5Stock4Length_dsl,
		TD4.Location						AS Equip5Stock4Location_dsl,

		TD5.[Width] 						AS Equip5Stock5Width_dsl,
		TD5.[Length]						AS Equip5Stock5Length_dsl,
		TD5.Location						AS Equip5Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 5 and TD1.StockSeq = 1 

	--TicketStock_seq6
	SELECT
		TD1.[TicketId] 						AS __ticketId,
		TD1.[ID] 							AS __contextId,
		TD1.[Width] 						AS Equip6Stock1Width_dsl,
		TD1.[Length]						AS Equip6Stock1Length_dsl,
		TD1.Location						AS Equip6Stock1Location_dsl,
													
		TD2.[Width] 						AS Equip6Stock2Width_dsl,
		TD2.[Length]						AS Equip6Stock2Length_dsl,
		TD2.Location						AS Equip6Stock2Location_dsl,
													
		TD3.[Width] 						AS Equip6Stock3Width_dsl,
		TD3.[Length]						AS Equip6Stock3Length_dsl,
		TD3.Location						AS Equip6Stock3Location_dsl,
													
		TD4.[Width] 						AS Equip6Stock4Width_dsl,
		TD4.[Length]						AS Equip6Stock4Length_dsl,
		TD4.Location						AS Equip6Stock4Location_dsl,
													
		TD5.[Width] 						AS Equip6Stock5Width_dsl,
		TD5.[Length]						AS Equip6Stock5Length_dsl,
		TD5.Location						AS Equip6Stock5Location_dsl
	FROM 
		#TempTicketStockDimensions TD1
		LEFT JOIN #TempTicketStockDimensions TD2 ON TD1.TicketId = TD2.TicketId AND TD1.RoutingNo = TD2.RoutingNo AND TD2.StockSeq = 2
		LEFT JOIN #TempTicketStockDimensions TD3 ON TD1.TicketId = TD3.TicketId AND TD1.RoutingNo = TD3.RoutingNo AND TD3.StockSeq = 3
		LEFT JOIN #TempTicketStockDimensions TD4 ON TD1.TicketId = TD4.TicketId AND TD1.RoutingNo = TD4.RoutingNo AND TD4.StockSeq = 4
		LEFT JOIN #TempTicketStockDimensions TD5 ON TD1.TicketId = TD5.TicketId AND TD1.RoutingNo = TD5.RoutingNo AND TD5.StockSeq = 5
	WHERE TD1.[RoutingNo] = 6 and TD1.StockSeq = 1 



	--PlannedTicketStock_seq1
	SELECT DISTINCT
		TS.[TicketId] 			AS __ticketId,
		TS.[ID] 				AS __contextId,
		TSA.[ActualWidth] 		AS PlannedStock1Width_dsl,
		TSA.[ActualLength]		AS PlannedStock1Length_dsl
	FROM 
		#BaseTicketStock TS
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) ON TS.StockMaterialId = TSA.OriginalStockMaterialId AND TS.[Sequence] = 1
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
		AND RoutingNo IS NULL
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) 
	--PlannedTicketStock_seq2
	SELECT DISTINCT
		TS.[TicketId] 			AS __ticketId,
		TS.[ID] 				AS __contextId,
		TSA.[ActualWidth] 		AS PlannedStock2Width_dsl,
		TSA.[ActualLength]		AS PlannedStock2Length_dsl
	FROM 
		#BaseTicketStock TS
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) ON TS.StockMaterialId = TSA.OriginalStockMaterialId AND TS.[Sequence] = 2
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
		AND RoutingNo IS NULL
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--PlannedTicketStock_seq3
	SELECT DISTINCT
		TS.[TicketId] 			AS __ticketId,
		TS.[ID] 				AS __contextId,
		TSA.[ActualWidth] 		AS PlannedStock3Width_dsl,
		TSA.[ActualLength]		AS PlannedStock3Length_dsl
	FROM 
		#BaseTicketStock TS
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) ON TS.StockMaterialId = TSA.OriginalStockMaterialId AND TS.[Sequence] = 3
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length)
		AND RoutingNo IS NULL
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	DROP TABLE IF EXISTS #TempPlannedTicketStockDimensions
	SELECT DISTINCT
		TS.[TicketId] 		,
		TS.[ID] 			,
		TSA.[ActualWidth] 	,
		TSA.[ActualLength]	,
		TS.[RoutingNo],
		ROW_NUMBER() OVER (PARTITION BY TS.TicketId, TS.[RoutingNo] ORDER BY TS.Sequence) AS StockSeq
	INTO #TempPlannedTicketStockDimensions
	FROM 
		#BaseTicketStock TS
		INNER JOIN TicketStockAvailability_temp TSA WITH(NOLOCK) ON TS.StockMaterialId = TSA.OriginalStockMaterialId
		AND TSA.TicketId = TS.TicketId
		AND TSA.OriginalWidth = TS.Width
		AND (TSA.OriginalLength IS NULL OR TSA.OriginalLength = TS.Length) AND RoutingNo IS NOT NULL
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets) 

	CREATE NONCLUSTERED INDEX IX_TempPlannedTicketStockDimensions_Ticket_Routing_Seq
		ON #TempPlannedTicketStockDimensions (TicketId, RoutingNo, StockSeq);

	--PlannedTicketStock_seq1
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip1PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip1PlannedStock1Length_dsl,

		TS2.[ActualWidth] 		AS Equip1PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip1PlannedStock2Length_dsl,

		TS3.[ActualWidth] 		AS Equip1PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip1PlannedStock3Length_dsl,

		TS4.[ActualWidth] 		AS Equip1PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip1PlannedStock4Length_dsl,

		TS5.[ActualWidth] 		AS Equip1PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip1PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 1 and ts1.StockSeq = 1

	--PlannedTicketStock_seq2
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip2PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip2PlannedStock1Length_dsl,

		TS2.[ActualWidth] 		AS Equip2PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip2PlannedStock2Length_dsl,

		TS3.[ActualWidth] 		AS Equip2PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip2PlannedStock3Length_dsl,

		TS4.[ActualWidth] 		AS Equip2PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip2PlannedStock4Length_dsl,

		TS5.[ActualWidth] 		AS Equip2PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip2PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 2 and ts1.StockSeq = 1

	--PlannedTicketStock_seq3
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip3PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip3PlannedStock1Length_dsl,

		TS2.[ActualWidth] 		AS Equip3PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip3PlannedStock2Length_dsl,

		TS3.[ActualWidth] 		AS Equip3PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip3PlannedStock3Length_dsl,

		TS4.[ActualWidth] 		AS Equip3PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip3PlannedStock4Length_dsl,

		TS5.[ActualWidth] 		AS Equip3PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip3PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 3 and ts1.StockSeq = 1

	--PlannedTicketStock_seq4
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip4PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip4PlannedStock1Length_dsl,

		TS2.[ActualWidth] 		AS Equip4PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip4PlannedStock2Length_dsl,

		TS3.[ActualWidth] 		AS Equip4PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip4PlannedStock3Length_dsl,

		TS4.[ActualWidth] 		AS Equip4PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip4PlannedStock4Length_dsl,

		TS5.[ActualWidth] 		AS Equip4PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip4PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 4 and ts1.StockSeq = 1

	--PlannedTicketStock_seq5
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip5PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip5PlannedStock1Length_dsl,

		TS2.[ActualWidth] 		AS Equip5PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip5PlannedStock2Length_dsl,

		TS3.[ActualWidth] 		AS Equip5PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip5PlannedStock3Length_dsl,

		TS4.[ActualWidth] 		AS Equip5PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip5PlannedStock4Length_dsl,

		TS5.[ActualWidth] 		AS Equip5PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip5PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 5 and ts1.StockSeq = 1

	--PlannedTicketStock_seq6
	SELECT DISTINCT
		TS1.[TicketId] 			AS __ticketId,
		TS1.[ID] 				AS __contextId,
		TS1.[ActualWidth] 		AS Equip6PlannedStock1Width_dsl,
		TS1.[ActualLength]		AS Equip6PlannedStock1Length_dsl,
										
		TS2.[ActualWidth] 		AS Equip6PlannedStock2Width_dsl,
		TS2.[ActualLength]		AS Equip6PlannedStock2Length_dsl,
										
		TS3.[ActualWidth] 		AS Equip6PlannedStock3Width_dsl,
		TS3.[ActualLength]		AS Equip6PlannedStock3Length_dsl,
										
		TS4.[ActualWidth] 		AS Equip6PlannedStock4Width_dsl,
		TS4.[ActualLength]		AS Equip6PlannedStock4Length_dsl,
										
		TS5.[ActualWidth] 		AS Equip6PlannedStock5Width_dsl,
		TS5.[ActualLength]		AS Equip6PlannedStock5Length_dsl
	FROM 
		#TempPlannedTicketStockDimensions TS1 
		LEFT JOIN #TempPlannedTicketStockDimensions TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempPlannedTicketStockDimensions TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempPlannedTicketStockDimensions TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempPlannedTicketStockDimensions TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 6 and ts1.StockSeq = 1


	--TimeCardInfo
	SELECT
		TCI.[TicketId] 			AS __ticketId,
		TCI.[ID] 				AS __contextId,
		TCI.[SourceEquipmentId] AS TimecardEquipment_dsl,
		TCI.[Totalizer]			AS Totalizer_dsl
	FROM 
		TimeCardInfo TCI WITH(NOLOCK)
	WHERE 
		TCI.[TicketId] IN (SELECT TicketId FROM #Tickets)



	--ToolingInventory_Seq1
	SELECT distinct
		TT.[TicketId] 			AS [__ticketId],
		TT.[ID] 				AS [__contextId],
		TT.[FlexoHotStamping] 	AS [Tool1FlexoHotS_dsl],
		TT.[DieSize] 			AS [Tool1DieSize_dsl],
		TT.[GearTeeth] 			AS [Tool1GearTeeth_dsl],
		TT.[Location] 			AS [Tool1Location_dsl],
		TT.[SourceToolingId] 	AS [Tool1Number_dsl],
		TT.[LinerCaliper]		AS [Tool1LinerCaliper_dsl],
		TT.[NoAround]			AS [Tool1NumberAround_dsl],
		TT.[Shape]				AS [Tool1Shape_dsl],
		TT.[ToolDeliveryDate]	AS [Tool1DeliveryDate_dsl],
		TT.[Description]		AS [Tool1Description_dsl]
	FROM #TempToolingSource TT
	WHERE TT.[Sequence] = 1;


	--ToolingInventory_Seq2
	SELECT distinct
		TT.[TicketId] 			AS [__ticketId],
		TT.[ID] 				AS [__contextId],
		TT.[FlexoHotStamping] 	AS [Tool2FlexoHotS_dsl],
		TT.[DieSize] 			AS [Tool2DieSize_dsl],
		TT.[GearTeeth] 			AS [Tool2GearTeeth_dsl],
		TT.[Location] 			AS [Tool2Location_dsl],
		TT.[SourceToolingId] 	AS [Tool2Number_dsl],
		TT.[LinerCaliper]		AS [Tool2LinerCaliper_dsl],
		TT.[NoAround]			AS [Tool2NumberAround_dsl],
		TT.[Shape]				AS [Tool2Shape_dsl],
		TT.[ToolDeliveryDate]	AS [Tool2DeliveryDate_dsl],
		TT.[Description]		AS [Tool2Description_dsl]
	FROM #TempToolingSource TT
	WHERE TT.[Sequence] = 2;


	--ToolingInventory_Seq3
	SELECT distinct
		TT.[TicketId] 			AS [__ticketId],
		TT.[ID] 				AS [__contextId],
		TT.[FlexoHotStamping] 	AS [Tool3FlexoHotS_dsl],
		TT.[DieSize] 			AS [Tool3DieSize_dsl],
		TT.[GearTeeth] 			AS [Tool3GearTeeth_dsl],
		TT.[Location] 			AS [Tool3Location_dsl],
		TT.[SourceToolingId] 	AS [Tool3Number_dsl],
		TT.[LinerCaliper]		AS [Tool3LinerCaliper_dsl],
		TT.[NoAround]			AS [Tool3NumberAround_dsl],
		TT.[Shape]				AS [Tool3Shape_dsl],
		TT.[ToolDeliveryDate]	AS [Tool3DeliveryDate_dsl],
		TT.[Description]		AS [Tool3Description_dsl]
	FROM #TempToolingSource TT
	WHERE TT.[Sequence] = 3;


	--ToolingInventory_Seq4
	SELECT distinct
		TT.[TicketId] 			AS [__ticketId],
		TT.[ID] 				AS [__contextId],
		TT.[FlexoHotStamping] 	AS [Tool4FlexoHotS_dsl],
		TT.[DieSize] 			AS [Tool4DieSize_dsl],
		TT.[GearTeeth] 			AS [Tool4GearTeeth_dsl],
		TT.[Location] 			AS [Tool4Location_dsl],
		TT.[SourceToolingId] 	AS [Tool4Number_dsl],
		TT.[LinerCaliper]		AS [Tool4LinerCaliper_dsl],
		TT.[NoAround]			AS [Tool4NumberAround_dsl],
		TT.[Shape]				AS [Tool4Shape_dsl],
		TT.[ToolDeliveryDate]	AS [Tool4DeliveryDate_dsl],
		TT.[Description]		AS [Tool4Description_dsl]
	FROM #TempToolingSource TT
	WHERE TT.[Sequence] = 4;


	--ToolingInventory_Seq5
	SELECT distinct
		TT.[TicketId] 			AS [__ticketId],
		TT.[ID] 				AS [__contextId],
		TT.[FlexoHotStamping] 	AS [Tool5FlexoHotS_dsl],
		TT.[DieSize] 			AS [Tool5DieSize_dsl],
		TT.[GearTeeth] 			AS [Tool5GearTeeth_dsl],
		TT.[Location] 			AS [Tool5Location_dsl],
		TT.[SourceToolingId] 	AS [Tool5Number_dsl],
		TT.[LinerCaliper]		AS [Tool5LinerCaliper_dsl],
		TT.[NoAround]			AS [Tool5NumberAround_dsl],
		TT.[Shape]				AS [Tool5Shape_dsl],
		TT.[ToolDeliveryDate]	AS [Tool5DeliveryDate_dsl],
		TT.[Description]		AS [Tool5Description_dsl]
	FROM #TempToolingSource TT
	WHERE TT.[Sequence] = 5;



	--Ticket Colors
	Select distinct
		OTC.[TicketId]			AS __ticketId,
		OTC.[TicketId]			AS __contextId, 
		OTC.Color			AS Color_dsl
	FROM
		OpenTicketColorsV2 OTC WITH(NOLOCK)
	WHERE 
		OTC.[TicketId] IN (SELECT TicketId FROM #Tickets)

  --Ticket Tools
	Select distinct
		TT.[TicketId] 			AS __ticketId,
		TT.[ID]				    AS __contextId, 
		TI.SourceToolingId		AS Tool_dsl,
		TI.Pitch				AS Pitch_dsl
	FROM
	TicketTool TT WITH(NOLOCK)
	Inner join ToolingInventory TI WITH(NOLOCK) on TT.ToolingId = TI.Id
	WHERE 
		TT.[TicketId] IN (SELECT TicketId FROM #Tickets)
	
	--Stock1Substitute
	SELECT distinct
		TS.[TicketId] 					AS __ticketId,
		SM.[Id] 						AS __contextId,
		SM.SourceStockId				AS Stock1Substitute_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		StockMaterialSubstitute SMS WITH(NOLOCK) on SM.Id = SMS.AlternateStockMaterialId
	INNER JOIN 
		#BaseTicketStock TS ON TS.[StockMaterialId] = SMS.StockMaterialId AND TS.[Sequence] = 1
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--Stock2Substitute
	SELECT distinct
		TS.[TicketId] 					AS __ticketId,
		SM.[Id] 						AS __contextId,
		SM.SourceStockId				AS Stock2Substitute_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		StockMaterialSubstitute SMS WITH(NOLOCK) on SM.Id = SMS.AlternateStockMaterialId
	INNER JOIN 
		#BaseTicketStock TS ON TS.[StockMaterialId] = SMS.StockMaterialId AND TS.[Sequence] = 2
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)
	--Stock3Substitute
	SELECT distinct
		TS.[TicketId] 					AS __ticketId,
		SM.[Id] 						AS __contextId,
		SM.SourceStockId				AS Stock3Substitute_dsl
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		StockMaterialSubstitute SMS WITH(NOLOCK) on SM.Id = SMS.AlternateStockMaterialId
	INNER JOIN 
		#BaseTicketStock TS ON TS.[StockMaterialId] = SMS.StockMaterialId AND TS.[Sequence] = 3
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	DROP TABLE IF EXISTS #TempTicketStockSubstitutes
	SELECT distinct
		TS.[TicketId] 	,
		SM.[Id] 		,
		SM.SourceStockId,
		TS.RoutingNo,
		ROW_NUMBER() OVER (PARTITION BY TS.TicketId, TS.[RoutingNo] ORDER BY TS.Sequence) AS StockSeq
	INTO #TempTicketStockSubstitutes
	FROM 
		StockMaterial SM WITH(NOLOCK)
	INNER JOIN 
		StockMaterialSubstitute SMS WITH(NOLOCK) on SM.Id = SMS.AlternateStockMaterialId
	INNER JOIN 
		#BaseTicketStock TS ON TS.[StockMaterialId] = SMS.StockMaterialId
	WHERE 
		TS.[TicketId] IN (SELECT TicketId FROM #Tickets)

	CREATE NONCLUSTERED INDEX IX_TempTicketStockSubstitutes_Ticket_Routing_Seq
		ON #TempTicketStockSubstitutes (TicketId, RoutingNo, StockSeq);

	

	--Stock1Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip1Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip1Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip1Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip1Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip1Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 1 and ts1.StockSeq = 1

	--Stock2Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip2Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip2Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip2Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip2Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip2Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 2 and ts1.StockSeq = 1

	--Stock3Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip3Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip3Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip3Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip3Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip3Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 3 and ts1.StockSeq = 1

	--Stock4Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip4Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip4Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip4Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip4Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip4Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 4 and ts1.StockSeq = 1

	--Stock5Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip5Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip5Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip5Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip5Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip5Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 5 and ts1.StockSeq = 1

	--Stock6Substitute
	SELECT distinct
		TS1.[TicketId] 					AS __ticketId,
		TS1.[Id] 						AS __contextId,
		TS1.SourceStockId				AS Equip6Stock1Substitute_dsl,
		TS2.SourceStockId				AS Equip6Stock2Substitute_dsl,
		TS3.SourceStockId				AS Equip6Stock3Substitute_dsl,
		TS4.SourceStockId				AS Equip6Stock4Substitute_dsl,
		TS5.SourceStockId				AS Equip6Stock5Substitute_dsl
	FROM 
		#TempTicketStockSubstitutes TS1 
		LEFT JOIN #TempTicketStockSubstitutes TS2 ON TS1.TicketId = TS2.TicketId AND TS1.RoutingNo = TS2.RoutingNo AND TS2.StockSeq = 2
		LEFT JOIN #TempTicketStockSubstitutes TS3 ON TS1.TicketId = TS3.TicketId AND TS1.RoutingNo = TS3.RoutingNo AND TS3.StockSeq = 3
		LEFT JOIN #TempTicketStockSubstitutes TS4 ON TS1.TicketId = TS4.TicketId AND TS1.RoutingNo = TS4.RoutingNo AND TS4.StockSeq = 4
		LEFT JOIN #TempTicketStockSubstitutes TS5 ON TS1.TicketId = TS5.TicketId AND TS1.RoutingNo = TS5.RoutingNo AND TS5.StockSeq = 5
	WHERE TS1.[RoutingNo] = 6 and ts1.StockSeq = 1


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

			EMPress.WorkCenterName		AS Equipment1WorkCenter_dsl,
			EMEquip.WorkCenterName		AS Equipment2WorkCenter_dsl,
			EMEquip3.WorkCenterName		AS Equipment3WorkCenter_dsl,
			EMEquip4.WorkCenterName		AS Equipment4WorkCenter_dsl,
			EMEquip5.WorkCenterName		AS Equipment5WorkCenter_dsl,
			EMEquip6.WorkCenterName		AS Equipment6Workcenter_dsl,
			EMEquip7.WorkCenterName		AS Equipment7Workcenter_dsl,

			TM.PressDone				AS Equipment1Done_dsl,
			TM.EquipDone				AS Equipment2Done_dsl,
			TM.Equip3Done				AS Equipment3Done_dsl,
			TM.Equip4Done				AS Equipment4Done_dsl,
			TM.Equip5Done				AS Equipment5Done_dsl,
			TM.Equip6Done				AS Equipment6Done_dsl,
			TM.Equip7Done				AS Equipment7Done_dsl,

			TM.EstRunHrs				AS Equipment1RunHours_dsl,
			TM.EquipEstRunHrs			AS Equipment2RunHours_dsl,
			TM.Equip3EstRunHrs			AS Equipment3RunHours_dsl,
			TM.Equip4EstRunHrs			AS Equipment4RunHours_dsl,
			TM.Equip5EstRunHrs			AS Equipment5RunHours_dsl,
			TM.Equip6EstRunHrs			AS Equipment6RunHours_dsl,
			TM.Equip7EstRunHrs			AS Equipment7RunHours_dsl,

			TPP.ToolStatus				AS ToolStatus_dsl,
			TPP.ProofStatus				AS ProofStatus_dsl,
			TPP.ArtStatus				AS ArtStatus_dsl,
			TPP.StockReceived			AS StockIn_dsl, --Redundant
			TPP.ToolsReceived			AS ToolsIn_dsl, --Redundant

			 --add new dsl here
			TPP.ArtWorkComplete			AS ArtWorkReceived_dsl,
			TPP.ArtWorkStaged			AS ArtWorkStaged_dsl,
			TPP.ProofComplete			AS ProofReceived_dsl,
			TPP.ProofStaged				AS ProofStaged_dsl,
			TPP.PlateComplete			AS PlateReceived_dsl,
			TPP.PlateStaged				AS PlateStaged_dsl,
			TPP.ToolsReceived			AS ToolsReceived_dsl,
			TPP.ToolsStaged				AS ToolsStaged_dsl,
			TPP.InkReceived 			AS InkReceived_dsl,
			TPP.InkStaged 				AS InkStaged_dsl,
			TPP.StockReceived			AS StockReceived_dsl,
			TPP.StockStaged				AS StockStaged_dsl,

			TM.Equip1TaskName			AS Equipment1TaskName_dsl,
			TM.Equip2TaskName			AS Equipment2TaskName_dsl,
			TM.Equip3TaskName			AS Equipment3TaskName_dsl,
			TM.Equip4TaskName			AS Equipment4TaskName_dsl,
			TM.Equip5TaskName			AS Equipment5TaskName_dsl,
			TM.Equip6TaskName			AS Equipment6TaskName_dsl,
			TM.Equip7TaskName			AS Equipment7TaskName_dsl,

			EMPress.FacilityName		AS Equipment1FacilityName_dsl,
			EMEquip.FacilityName		AS Equipment2FacilityName_dsl,
			EMEquip3.FacilityName		AS Equipment3FacilityName_dsl,
			EMEquip4.FacilityName		AS Equipment4FacilityName_dsl,
			EMEquip5.FacilityName		AS Equipment5FacilityName_dsl,
			EMEquip6.FacilityName		AS Equipment6FacilityName_dsl,
			EMEquip7.FacilityName		AS Equipment7FacilityName_dsl,

			TM.EstMRHrs					AS Equipment1MRHours_dsl,
			TM.Equip2MakeReadyHours		AS Equipment2MRHours_dsl,
			TM.Equip3MakeReadyHours		AS Equipment3MRHours_dsl,
			TM.Equip4MakeReadyHours		AS Equipment4MRHours_dsl,
			TM.Equip5MakeReadyHours		AS Equipment5MRHours_dsl,
			TM.Equip6MakeReadyHours		AS Equipment6MRHours_dsl,
			TM.Equip7MakeReadyHours		AS Equipment7MRHours_dsl

		FROM 
			#TempTicketMaster TM							WITH(NOLOCK)
			INNER JOIN	#Tickets T									ON	TM.ID = T.TicketId
			INNER JOIN	TicketPreProcess TPP		WITH(NOLOCK)	ON	TM.ID = TPP.TicketId
			INNER JOIN	TicketShipping TS			WITH(NOLOCK)	ON	TM.ID = TS.TicketId
			LEFT JOIN	EquipmentMaster EMPress		WITH(NOLOCK)	ON	TM.Press = EMPress.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip		WITH(NOLOCK)	ON	TM.EquipID = EMEquip.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip3	WITH(NOLOCK)	ON	TM.Equip3ID = EMEquip3.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip4	WITH(NOLOCK)	ON	TM.Equip4ID = EMEquip4.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip5	WITH(NOLOCK)	ON	TM.Equip5Id = EMEquip5.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip6	WITH(NOLOCK)	ON	TM.Equip6Id = EMEquip6.SourceEquipmentId
			LEFT JOIN	EquipmentMaster EMEquip7	WITH(NOLOCK)	ON	TM.Equip7Id = EMEquip7.SourceEquipmentId;


--Ticket Task 1
    SELECT distinct
        TI.[TicketId]           AS __ticketId,
        TI.[ID]                 AS __contextId,
		TI.TaskName				AS Task1Name_dsl,
		EM.facilityId			AS Equipment1FacilityID_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 1

    --TicketTask2
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task2Name_dsl,
		EM.facilityId				AS Equipment2FacilityID_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 2

    --TicketTask3
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task3Name_dsl,
		EM.facilityId				AS Equipment3FacilityID_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 3

    --TicketTask4
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task4Name_dsl,
		EM.facilityId				AS Equipment4FacilityID_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 4

    --TicketTask5
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task5Name_dsl,
		EM.facilityId				AS Equipment5FacilityID_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 5

	--TicketTask6
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task6Name_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 6

	--TicketTask7
    SELECT distinct
        TI.[TicketId]               AS __ticketId,
        TI.[ID]                     AS __contextId,
		TI.TaskName					AS Task7Name_dsl
    FROM 
        TicketTask TI WITH(NOLOCK)
        INNER JOIN EquipmentMaster EM WITH(NOLOCK) on TI.OriginalEquipmentId = EM.ID
    WHERE 
        [TicketId]  IN (SELECT TicketId FROM #Tickets) AND [Sequence] = 7

	--CustomerMaster
    SELECT 
		TM.[ID] 					AS __ticketId,
		TM.[ID] 					AS __contextId,
		CM.CustomField1				AS CustomerPopupname1_dsl,
		CM.CustomerGroup			AS CustomerGroup_dsl
    FROM 
        CustomerMaster CM WITH(NOLOCK)
		INNER JOIN #TempTicketMaster TM on CM.SourceCustomerID = TM.SourceCustomerId
	WHERE TM.ID  IN (SELECT TicketId FROM #Tickets)

	--OrderedStockDate
	DECLARE @HoursToAdd int = 0
			SELECT @HoursToAdd = ISNULL(CV.Value, 0)
			FROM ConfigurationMaster CM WITH(NOLOCK)
			    LEFT JOIN ConfigurationValue CV WITH(NOLOCK)
			        ON CM.Id = CV.ConfigId
			WHERE NAME = 'StockArrivalHours';
			
			WITH POM
			AS (SELECT PromisedDeliveryDate,
			           RequestedDeliveryDate,
			           StockMaterialId,
					   Notes
			    FROM PurchaseOrderMaster WITH(NOLOCK)
			    WHERE PurchaseOrderType = 'Stock'
			          AND IsOpen = 1
			          AND PromisedDeliveryDate <> '1970-01-01'
			          AND PromisedDeliveryDate IS NOT NULL
			          AND PromisedDeliveryDate >= DATEADD(DAY, -180, GETDATE())
			   )
			SELECT TS.TicketId AS __ticketId,
				   TS.TicketId AS __contextId,
			       DATEADD(hour, @HoursToAdd, CAST(MIN(POM.PromisedDeliveryDate) AS datetime)) AS OrderedStockDate_dsl,
				   LEFT(STRING_AGG(CONVERT(nvarchar(max), POM.Notes), ', '), 200) AS PurchaseOrderNotes_dsl
			FROM #BaseTicketStock TS
			    INNER JOIN TicketPreProcess TPP WITH(NOLOCK)
			        ON TS.TicketId = TPP.TicketId
			    INNER JOIN StockMaterial SM WITH(NOLOCK)
			        ON SM.Id = TS.StockMaterialId
			           AND TS.[Sequence] = 2
			    INNER JOIN POM WITH(NOLOCK)
			        ON SM.Id = POM.StockMaterialId
			WHERE TS.TicketId IN (SELECT TicketId FROM #Tickets)
			      AND TPP.StockReceived IN ( 'Ord' ) 
			GROUP BY TS.TicketId


	-- Ticket Notes DSL
		SELECT 
			TM.[ID] 					AS __ticketId,
			TM.[ID] 					AS __contextId,
			TGN.[Notes]					AS TicketNotesDescription_dsl
		FROM TicketGeneralNotes TGN WITH(NOLOCK)
			INNER JOIN #TempTicketMaster TM on TGN.TicketId = TM.ID
		WHERE TM.ID IN (SELECT TicketId FROM #Tickets)


	--WCTimecardQuantityDSL
		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC1TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Press = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC2TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.EquipID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC3TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip3ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC4TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip4ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC5TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip5Id = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC6TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source WITH(NOLOCK) on TM.Equip6ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC WITH(NOLOCK) on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI WITH(NOLOCK) on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id

		select
			TM.Id						AS __ticketId,
			TM.Id						AS __contextId,
			SUM(TCI.ActualNetQuantity)  AS WC7TimecardQuantity_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM_Source on TM.Equip7ID = SourceEquipmentId
			inner join EquipmentMaster EM_WC on EM_Source.WorkcenterTypeId = EM_WC.WorkcenterTypeId
			inner join TimecardInfo TCI on EM_WC.Id = TCI.EquipmentId and TCI.TicketId = TM.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)
			group by TM.Id


---- ValueStreams
		--Equipment1ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name  AS Equipment1ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Press = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment2ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name AS Equipment2ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.EquipId = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment3ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name  AS Equipment3ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Equip3Id = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment4ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name AS Equipment4ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Equip4Id = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment5ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name		AS Equipment5ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Equip5Id = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment6ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name  AS Equipment6ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Equip6Id = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)

		--Equipment7ValueStream_dsl
		select DISTINCT
			TM.ID		AS __ticketId,
			TM.ID		AS __contextId,
			EM.ID		AS EquipmentId,
			EM.Name		AS EquipmentName,
			VS.Name  AS Equipment7ValueStream_dsl
			from #TempTicketMaster TM
			inner join EquipmentMaster EM WITH(NOLOCK) on TM.Equip7Id = EM.SourceEquipmentId
			left join EquipmentValueStream EVS WITH(NOLOCK) on EM.ID = EVS.EquipmentId
			left join ValueStream VS WITH(NOLOCK) on EVS.ValueStreamId = VS.Id
			where TM.Id IN (SELECT TicketId FROM #Tickets)


		--StockProductMaster
		SELECT DISTINCT
			TIF.TicketId 				AS __ticketId,
			SPM.ProductId 				AS __contextId,
			SPM.BackOrderedQuantity		AS BackOrdered_dsl,
			SPM.InventoryQuantity		AS InventoryQuantity_dsl
		FROM StockProductMaster SPM WITH(NOLOCK)
		INNER JOIN TicketItemInfo TIF WITH(NOLOCK) ON TIF.[ProductId] = SPM.ProductId
		WHERE TIF.TicketId IN (SELECT TicketId FROM #Tickets)

			--requiredInk
		SELECT DISTINCT
			tif.[TicketId] 						AS __ticketId,
			tici.[Id] 						AS __contextId,
			tici.SourceInk AS RequiredInk_dsl
		FROM 
			TicketItemColorInfo tici
		INNER JOIN TicketItemInfo TIF WITH(NOLOCK) ON TIF.ID = tici.TicketItemInfoId
		where TIF.TicketId IN (SELECT TicketId FROM #Tickets)
		order by tif.[TicketId], tici.SourceInk

		DROP TABLE IF EXISTS #TempToolingSource;
		DROP TABLE IF EXISTS #TempTicketMaster;
		DROP TABLE IF EXISTS #BaseTicketStock;

		DROP TABLE IF EXISTS #TempTicketStocks
		DROP TABLE IF EXISTS #TempPlannedTicketStocks	
		DROP TABLE IF EXISTS #TempTicketStockDimensions
		DROP TABLE IF EXISTS #TempPlannedTicketStockDimensions
		DROP TABLE IF EXISTS #TempTicketStockSubstitutes


	-- LT 9.3 => Tooling DSL
	IF EXISTS (SELECT 1 FROM [dbo].[TicketTool] WHERE [RoutingNumber] IS NOT NULL)
	BEGIN
		DROP TABLE IF EXISTS [dbo].[#TempTooling];

		SELECT
			[TT].[TicketId],
			[TI].[ID],
			[TI].[FlexoHotStamping],
			[TI].[DieSize],
			[TI].[GearTeeth],
			[TI].[Location],
			[TI].[SourceToolingId],
			[TI].[LinerCaliper],
			[TI].[NoAround],
			[TI].[Shape],
			[TI].[ToolDeliveryDate],
			[TT].[Description],
			[TT].[RoutingNumber],
			ROW_NUMBER() OVER (PARTITION BY [TT].[TicketId], [TT].[RoutingNumber] ORDER BY [TI].[Id]) AS [ToolNum]
		INTO [dbo].[#TempTooling]
		FROM [dbo].[ToolingInventory] AS [TI]
			INNER JOIN [dbo].[TicketTool] AS [TT] ON [TT].[ToolingId] = [TI].[Id]
			INNER JOIN #Tickets AS [T] ON [T].[TicketId] = [TT].[TicketId];

		CREATE NONCLUSTERED INDEX [IX_TempTooling_Ticket_RoutingNumber_ToolNum] ON [dbo].[#TempTooling] ([TicketId], [RoutingNumber], [ToolNum]);


		-- Equipment 1 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS [__ticketId],
			[EQT1].[ID] 				AS [__contextId],
    
			-- EQUIPMENT 1 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS [Equip1Tool1FlexoHotS_dsl],
			[EQT1].[DieSize] 			AS [Equip1Tool1DieSize_dsl],
			[EQT1].[GearTeeth] 		    AS [Equip1Tool1GearTeeth_dsl],
			[EQT1].[Location] 			AS [Equip1Tool1Location_dsl],
			[EQT1].[SourceToolingId] 	AS [Equip1Tool1Number_dsl],
			[EQT1].[LinerCaliper]		AS [Equip1Tool1LinerCaliper_dsl],
			[EQT1].[NoAround]			AS [Equip1Tool1NumberAround_dsl],
			[EQT1].[Shape]				AS [Equip1Tool1Shape_dsl],
			[EQT1].[ToolDeliveryDate]	AS [Equip1Tool1DeliveryDate_dsl],
			[EQT1].[Description]		AS [Equip1Tool1Description_dsl],

			-- EQUIPMENT 1 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS [Equip1Tool2FlexoHotS_dsl],
			[EQT2].[DieSize] 			AS [Equip1Tool2DieSize_dsl],
			[EQT2].[GearTeeth] 		    AS [Equip1Tool2GearTeeth_dsl],
			[EQT2].[Location] 			AS [Equip1Tool2Location_dsl],
			[EQT2].[SourceToolingId] 	AS [Equip1Tool2Number_dsl],
			[EQT2].[LinerCaliper]		AS [Equip1Tool2LinerCaliper_dsl],
			[EQT2].[NoAround]			AS [Equip1Tool2NumberAround_dsl],
			[EQT2].[Shape]				AS [Equip1Tool2Shape_dsl],
			[EQT2].[ToolDeliveryDate]	AS [Equip1Tool2DeliveryDate_dsl],
			[EQT2].[Description]		AS [Equip1Tool2Description_dsl],

			-- EQUIPMENT 1 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS [Equip1Tool3FlexoHotS_dsl],
			[EQT3].[DieSize] 			AS [Equip1Tool3DieSize_dsl],
			[EQT3].[GearTeeth] 		    AS [Equip1Tool3GearTeeth_dsl],
			[EQT3].[Location] 			AS [Equip1Tool3Location_dsl],
			[EQT3].[SourceToolingId] 	AS [Equip1Tool3Number_dsl],
			[EQT3].[LinerCaliper]		AS [Equip1Tool3LinerCaliper_dsl],
			[EQT3].[NoAround]			AS [Equip1Tool3NumberAround_dsl],
			[EQT3].[Shape]				AS [Equip1Tool3Shape_dsl],
			[EQT3].[ToolDeliveryDate]	AS [Equip1Tool3DeliveryDate_dsl],
			[EQT3].[Description]		AS [Equip1Tool3Description_dsl],

			-- EQUIPMENT 1 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS [Equip1Tool4FlexoHotS_dsl],
			[EQT4].[DieSize] 			AS [Equip1Tool4DieSize_dsl],
			[EQT4].[GearTeeth] 		    AS [Equip1Tool4GearTeeth_dsl],
			[EQT4].[Location] 			AS [Equip1Tool4Location_dsl],
			[EQT4].[SourceToolingId] 	AS [Equip1Tool4Number_dsl],
			[EQT4].[LinerCaliper]		AS [Equip1Tool4LinerCaliper_dsl],
			[EQT4].[NoAround]			AS [Equip1Tool4NumberAround_dsl],
			[EQT4].[Shape]				AS [Equip1Tool4Shape_dsl],
			[EQT4].[ToolDeliveryDate]	AS [Equip1Tool4DeliveryDate_dsl],
			[EQT4].[Description]		AS [Equip1Tool4Description_dsl],

			-- EQUIPMENT 1 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS [Equip1Tool5FlexoHotS_dsl],
			[EQT5].[DieSize] 			AS [Equip1Tool5DieSize_dsl],
			[EQT5].[GearTeeth] 		    AS [Equip1Tool5GearTeeth_dsl],
			[EQT5].[Location] 			AS [Equip1Tool5Location_dsl],
			[EQT5].[SourceToolingId] 	AS [Equip1Tool5Number_dsl],
			[EQT5].[LinerCaliper]		AS [Equip1Tool5LinerCaliper_dsl],
			[EQT5].[NoAround]			AS [Equip1Tool5NumberAround_dsl],
			[EQT5].[Shape]				AS [Equip1Tool5Shape_dsl],
			[EQT5].[ToolDeliveryDate]	AS [Equip1Tool5DeliveryDate_dsl],
			[EQT5].[Description]		AS [Equip1Tool5Description_dsl]

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 1 AND [EQT1].[ToolNum] = 1;


		-- Equipment 2 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS [__ticketId],
			[EQT1].[ID] 				AS [__contextId],
    
			-- EQUIPMENT 2 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS Equip2Tool1FlexoHotS_dsl,
			[EQT1].[DieSize] 			AS Equip2Tool1DieSize_dsl,
			[EQT1].[GearTeeth] 		    AS Equip2Tool1GearTeeth_dsl,
			[EQT1].[Location] 			AS Equip2Tool1Location_dsl,
			[EQT1].[SourceToolingId] 	AS Equip2Tool1Number_dsl,
			[EQT1].[LinerCaliper]		AS Equip2Tool1LinerCaliper_dsl,
			[EQT1].[NoAround]			AS Equip2Tool1NumberAround_dsl,
			[EQT1].[Shape]				AS Equip2Tool1Shape_dsl,
			[EQT1].[ToolDeliveryDate]	AS Equip2Tool1DeliveryDate_dsl,
			[EQT1].[Description]		AS Equip2Tool1Description_dsl,

			-- EQUIPMENT 2 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS Equip2Tool2FlexoHotS_dsl,
			[EQT2].[DieSize] 			AS Equip2Tool2DieSize_dsl,
			[EQT2].[GearTeeth] 		    AS Equip2Tool2GearTeeth_dsl,
			[EQT2].[Location] 			AS Equip2Tool2Location_dsl,
			[EQT2].[SourceToolingId] 	AS Equip2Tool2Number_dsl,
			[EQT2].[LinerCaliper]		AS Equip2Tool2LinerCaliper_dsl,
			[EQT2].[NoAround]			AS Equip2Tool2NumberAround_dsl,
			[EQT2].[Shape]				AS Equip2Tool2Shape_dsl,
			[EQT2].[ToolDeliveryDate]	AS Equip2Tool2DeliveryDate_dsl,
			[EQT2].[Description]		AS Equip2Tool2Description_dsl,

			-- EQUIPMENT 2 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS Equip2Tool3FlexoHotS_dsl,
			[EQT3].[DieSize] 			AS Equip2Tool3DieSize_dsl,
			[EQT3].[GearTeeth] 		    AS Equip2Tool3GearTeeth_dsl,
			[EQT3].[Location] 			AS Equip2Tool3Location_dsl,
			[EQT3].[SourceToolingId] 	AS Equip2Tool3Number_dsl,
			[EQT3].[LinerCaliper]		AS Equip2Tool3LinerCaliper_dsl,
			[EQT3].[NoAround]			AS Equip2Tool3NumberAround_dsl,
			[EQT3].[Shape]				AS Equip2Tool3Shape_dsl,
			[EQT3].[ToolDeliveryDate]	AS Equip2Tool3DeliveryDate_dsl,
			[EQT3].[Description]		AS Equip2Tool3Description_dsl,

			-- EQUIPMENT 2 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS Equip2Tool4FlexoHotS_dsl,
			[EQT4].[DieSize] 			AS Equip2Tool4DieSize_dsl,
			[EQT4].[GearTeeth] 		    AS Equip2Tool4GearTeeth_dsl,
			[EQT4].[Location] 			AS Equip2Tool4Location_dsl,
			[EQT4].[SourceToolingId] 	AS Equip2Tool4Number_dsl,
			[EQT4].[LinerCaliper]		AS Equip2Tool4LinerCaliper_dsl,
			[EQT4].[NoAround]			AS Equip2Tool4NumberAround_dsl,
			[EQT4].[Shape]				AS Equip2Tool4Shape_dsl,
			[EQT4].[ToolDeliveryDate]	AS Equip2Tool4DeliveryDate_dsl,
			[EQT4].[Description]		AS Equip2Tool4Description_dsl,

			-- EQUIPMENT 2 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS Equip2Tool5FlexoHotS_dsl,
			[EQT5].[DieSize] 			AS Equip2Tool5DieSize_dsl,
			[EQT5].[GearTeeth] 		    AS Equip2Tool5GearTeeth_dsl,
			[EQT5].[Location] 			AS Equip2Tool5Location_dsl,
			[EQT5].[SourceToolingId] 	AS Equip2Tool5Number_dsl,
			[EQT5].[LinerCaliper]		AS Equip2Tool5LinerCaliper_dsl,
			[EQT5].[NoAround]			AS Equip2Tool5NumberAround_dsl,
			[EQT5].[Shape]				AS Equip2Tool5Shape_dsl,
			[EQT5].[ToolDeliveryDate]	AS Equip2Tool5DeliveryDate_dsl,
			[EQT5].[Description]		AS Equip2Tool5Description_dsl

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 2 AND [EQT1].[ToolNum] = 1;


		-- Equipment 3 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS __ticketId,
			[EQT1].[ID] 				AS __contextId,
    
			-- EQUIPMENT 3 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS Equip3Tool1FlexoHotS_dsl,
			[EQT1].[DieSize] 			AS Equip3Tool1DieSize_dsl,
			[EQT1].[GearTeeth] 		    AS Equip3Tool1GearTeeth_dsl,
			[EQT1].[Location] 			AS Equip3Tool1Location_dsl,
			[EQT1].[SourceToolingId] 	AS Equip3Tool1Number_dsl,
			[EQT1].[LinerCaliper]		AS Equip3Tool1LinerCaliper_dsl,
			[EQT1].[NoAround]			AS Equip3Tool1NumberAround_dsl,
			[EQT1].[Shape]				AS Equip3Tool1Shape_dsl,
			[EQT1].[ToolDeliveryDate]	AS Equip3Tool1DeliveryDate_dsl,
			[EQT1].[Description]		AS Equip3Tool1Description_dsl,

			-- EQUIPMENT 3 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS Equip3Tool2FlexoHotS_dsl,
			[EQT2].[DieSize] 			AS Equip3Tool2DieSize_dsl,
			[EQT2].[GearTeeth] 		    AS Equip3Tool2GearTeeth_dsl,
			[EQT2].[Location] 			AS Equip3Tool2Location_dsl,
			[EQT2].[SourceToolingId] 	AS Equip3Tool2Number_dsl,
			[EQT2].[LinerCaliper]		AS Equip3Tool2LinerCaliper_dsl,
			[EQT2].[NoAround]			AS Equip3Tool2NumberAround_dsl,
			[EQT2].[Shape]				AS Equip3Tool2Shape_dsl,
			[EQT2].[ToolDeliveryDate]	AS Equip3Tool2DeliveryDate_dsl,
			[EQT2].[Description]		AS Equip3Tool2Description_dsl,

			-- EQUIPMENT 3 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS Equip3Tool3FlexoHotS_dsl,
			[EQT3].[DieSize] 			AS Equip3Tool3DieSize_dsl,
			[EQT3].[GearTeeth] 		    AS Equip3Tool3GearTeeth_dsl,
			[EQT3].[Location] 			AS Equip3Tool3Location_dsl,
			[EQT3].[SourceToolingId] 	AS Equip3Tool3Number_dsl,
			[EQT3].[LinerCaliper]		AS Equip3Tool3LinerCaliper_dsl,
			[EQT3].[NoAround]			AS Equip3Tool3NumberAround_dsl,
			[EQT3].[Shape]				AS Equip3Tool3Shape_dsl,
			[EQT3].[ToolDeliveryDate]	AS Equip3Tool3DeliveryDate_dsl,
			[EQT3].[Description]		AS Equip3Tool3Description_dsl,

			-- EQUIPMENT 3 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS Equip3Tool4FlexoHotS_dsl,
			[EQT4].[DieSize] 			AS Equip3Tool4DieSize_dsl,
			[EQT4].[GearTeeth] 		    AS Equip3Tool4GearTeeth_dsl,
			[EQT4].[Location] 			AS Equip3Tool4Location_dsl,
			[EQT4].[SourceToolingId] 	AS Equip3Tool4Number_dsl,
			[EQT4].[LinerCaliper]		AS Equip3Tool4LinerCaliper_dsl,
			[EQT4].[NoAround]			AS Equip3Tool4NumberAround_dsl,
			[EQT4].[Shape]				AS Equip3Tool4Shape_dsl,
			[EQT4].[ToolDeliveryDate]	AS Equip3Tool4DeliveryDate_dsl,
			[EQT4].[Description]		AS Equip3Tool4Description_dsl,

			-- EQUIPMENT 3 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS Equip3Tool5FlexoHotS_dsl,
			[EQT5].[DieSize] 			AS Equip3Tool5DieSize_dsl,
			[EQT5].[GearTeeth] 		    AS Equip3Tool5GearTeeth_dsl,
			[EQT5].[Location] 			AS Equip3Tool5Location_dsl,
			[EQT5].[SourceToolingId] 	AS Equip3Tool5Number_dsl,
			[EQT5].[LinerCaliper]		AS Equip3Tool5LinerCaliper_dsl,
			[EQT5].[NoAround]			AS Equip3Tool5NumberAround_dsl,
			[EQT5].[Shape]				AS Equip3Tool5Shape_dsl,
			[EQT5].[ToolDeliveryDate]	AS Equip3Tool5DeliveryDate_dsl,
			[EQT5].[Description]		AS Equip3Tool5Description_dsl

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 3 AND [EQT1].[ToolNum] = 1;


		-- Equipment 4 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS __ticketId,
			[EQT1].[ID] 				AS __contextId,
    
			-- EQUIPMENT 4 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS Equip4Tool1FlexoHotS_dsl,
			[EQT1].[DieSize] 			AS Equip4Tool1DieSize_dsl,
			[EQT1].[GearTeeth] 		    AS Equip4Tool1GearTeeth_dsl,
			[EQT1].[Location] 			AS Equip4Tool1Location_dsl,
			[EQT1].[SourceToolingId] 	AS Equip4Tool1Number_dsl,
			[EQT1].[LinerCaliper]		AS Equip4Tool1LinerCaliper_dsl,
			[EQT1].[NoAround]			AS Equip4Tool1NumberAround_dsl,
			[EQT1].[Shape]				AS Equip4Tool1Shape_dsl,
			[EQT1].[ToolDeliveryDate]	AS Equip4Tool1DeliveryDate_dsl,
			[EQT1].[Description]		AS Equip4Tool1Description_dsl,

			-- EQUIPMENT 4 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS Equip4Tool2FlexoHotS_dsl,
			[EQT2].[DieSize] 			AS Equip4Tool2DieSize_dsl,
			[EQT2].[GearTeeth] 		    AS Equip4Tool2GearTeeth_dsl,
			[EQT2].[Location] 			AS Equip4Tool2Location_dsl,
			[EQT2].[SourceToolingId] 	AS Equip4Tool2Number_dsl,
			[EQT2].[LinerCaliper]		AS Equip4Tool2LinerCaliper_dsl,
			[EQT2].[NoAround]			AS Equip4Tool2NumberAround_dsl,
			[EQT2].[Shape]				AS Equip4Tool2Shape_dsl,
			[EQT2].[ToolDeliveryDate]	AS Equip4Tool2DeliveryDate_dsl,
			[EQT2].[Description]		AS Equip4Tool2Description_dsl,

			-- EQUIPMENT 4 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS Equip4Tool3FlexoHotS_dsl,
			[EQT3].[DieSize] 			AS Equip4Tool3DieSize_dsl,
			[EQT3].[GearTeeth] 		    AS Equip4Tool3GearTeeth_dsl,
			[EQT3].[Location] 			AS Equip4Tool3Location_dsl,
			[EQT3].[SourceToolingId] 	AS Equip4Tool3Number_dsl,
			[EQT3].[LinerCaliper]		AS Equip4Tool3LinerCaliper_dsl,
			[EQT3].[NoAround]			AS Equip4Tool3NumberAround_dsl,
			[EQT3].[Shape]				AS Equip4Tool3Shape_dsl,
			[EQT3].[ToolDeliveryDate]	AS Equip4Tool3DeliveryDate_dsl,
			[EQT3].[Description]		AS Equip4Tool3Description_dsl,

			-- EQUIPMENT 4 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS Equip4Tool4FlexoHotS_dsl,
			[EQT4].[DieSize] 			AS Equip4Tool4DieSize_dsl,
			[EQT4].[GearTeeth] 		    AS Equip4Tool4GearTeeth_dsl,
			[EQT4].[Location] 			AS Equip4Tool4Location_dsl,
			[EQT4].[SourceToolingId] 	AS Equip4Tool4Number_dsl,
			[EQT4].[LinerCaliper]		AS Equip4Tool4LinerCaliper_dsl,
			[EQT4].[NoAround]			AS Equip4Tool4NumberAround_dsl,
			[EQT4].[Shape]				AS Equip4Tool4Shape_dsl,
			[EQT4].[ToolDeliveryDate]	AS Equip4Tool4DeliveryDate_dsl,
			[EQT4].[Description]		AS Equip4Tool4Description_dsl,

			-- EQUIPMENT 4 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS Equip4Tool5FlexoHotS_dsl,
			[EQT5].[DieSize] 			AS Equip4Tool5DieSize_dsl,
			[EQT5].[GearTeeth] 		    AS Equip4Tool5GearTeeth_dsl,
			[EQT5].[Location] 			AS Equip4Tool5Location_dsl,
			[EQT5].[SourceToolingId] 	AS Equip4Tool5Number_dsl,
			[EQT5].[LinerCaliper]		AS Equip4Tool5LinerCaliper_dsl,
			[EQT5].[NoAround]			AS Equip4Tool5NumberAround_dsl,
			[EQT5].[Shape]				AS Equip4Tool5Shape_dsl,
			[EQT5].[ToolDeliveryDate]	AS Equip4Tool5DeliveryDate_dsl,
			[EQT5].[Description]		AS Equip4Tool5Description_dsl

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 4 AND [EQT1].[ToolNum] = 1;


		-- Equipment 5 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS __ticketId,
			[EQT1].[ID] 				AS __contextId,
    
			-- EQUIPMENT 5 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS Equip5Tool1FlexoHotS_dsl,
			[EQT1].[DieSize] 			AS Equip5Tool1DieSize_dsl,
			[EQT1].[GearTeeth] 		    AS Equip5Tool1GearTeeth_dsl,
			[EQT1].[Location] 			AS Equip5Tool1Location_dsl,
			[EQT1].[SourceToolingId] 	AS Equip5Tool1Number_dsl,
			[EQT1].[LinerCaliper]		AS Equip5Tool1LinerCaliper_dsl,
			[EQT1].[NoAround]			AS Equip5Tool1NumberAround_dsl,
			[EQT1].[Shape]				AS Equip5Tool1Shape_dsl,
			[EQT1].[ToolDeliveryDate]	AS Equip5Tool1DeliveryDate_dsl,
			[EQT1].[Description]		AS Equip5Tool1Description_dsl,

			-- EQUIPMENT 5 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS Equip5Tool2FlexoHotS_dsl,
			[EQT2].[DieSize] 			AS Equip5Tool2DieSize_dsl,
			[EQT2].[GearTeeth] 		    AS Equip5Tool2GearTeeth_dsl,
			[EQT2].[Location] 			AS Equip5Tool2Location_dsl,
			[EQT2].[SourceToolingId] 	AS Equip5Tool2Number_dsl,
			[EQT2].[LinerCaliper]		AS Equip5Tool2LinerCaliper_dsl,
			[EQT2].[NoAround]			AS Equip5Tool2NumberAround_dsl,
			[EQT2].[Shape]				AS Equip5Tool2Shape_dsl,
			[EQT2].[ToolDeliveryDate]	AS Equip5Tool2DeliveryDate_dsl,
			[EQT2].[Description]		AS Equip5Tool2Description_dsl,

			-- EQUIPMENT 5 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS Equip5Tool3FlexoHotS_dsl,
			[EQT3].[DieSize] 			AS Equip5Tool3DieSize_dsl,
			[EQT3].[GearTeeth] 		    AS Equip5Tool3GearTeeth_dsl,
			[EQT3].[Location] 			AS Equip5Tool3Location_dsl,
			[EQT3].[SourceToolingId] 	AS Equip5Tool3Number_dsl,
			[EQT3].[LinerCaliper]		AS Equip5Tool3LinerCaliper_dsl,
			[EQT3].[NoAround]			AS Equip5Tool3NumberAround_dsl,
			[EQT3].[Shape]				AS Equip5Tool3Shape_dsl,
			[EQT3].[ToolDeliveryDate]	AS Equip5Tool3DeliveryDate_dsl,
			[EQT3].[Description]		AS Equip5Tool3Description_dsl,

			-- EQUIPMENT 5 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS Equip5Tool4FlexoHotS_dsl,
			[EQT4].[DieSize] 			AS Equip5Tool4DieSize_dsl,
			[EQT4].[GearTeeth] 		    AS Equip5Tool4GearTeeth_dsl,
			[EQT4].[Location] 			AS Equip5Tool4Location_dsl,
			[EQT4].[SourceToolingId] 	AS Equip5Tool4Number_dsl,
			[EQT4].[LinerCaliper]		AS Equip5Tool4LinerCaliper_dsl,
			[EQT4].[NoAround]			AS Equip5Tool4NumberAround_dsl,
			[EQT4].[Shape]				AS Equip5Tool4Shape_dsl,
			[EQT4].[ToolDeliveryDate]	AS Equip5Tool4DeliveryDate_dsl,
			[EQT4].[Description]		AS Equip5Tool4Description_dsl,

			-- EQUIPMENT 5 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS Equip5Tool5FlexoHotS_dsl,
			[EQT5].[DieSize] 			AS Equip5Tool5DieSize_dsl,
			[EQT5].[GearTeeth] 		    AS Equip5Tool5GearTeeth_dsl,
			[EQT5].[Location] 			AS Equip5Tool5Location_dsl,
			[EQT5].[SourceToolingId] 	AS Equip5Tool5Number_dsl,
			[EQT5].[LinerCaliper]		AS Equip5Tool5LinerCaliper_dsl,
			[EQT5].[NoAround]			AS Equip5Tool5NumberAround_dsl,
			[EQT5].[Shape]				AS Equip5Tool5Shape_dsl,
			[EQT5].[ToolDeliveryDate]	AS Equip5Tool5DeliveryDate_dsl,
			[EQT5].[Description]		AS Equip5Tool5Description_dsl

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 5 AND [EQT1].[ToolNum] = 1;


		-- Equipment 6 => Tooling DSL
		SELECT

			[EQT1].[TicketId] 			AS __ticketId,
			[EQT1].[ID] 				AS __contextId,
    
			-- Equipment 6 => TOOL 1
			[EQT1].[FlexoHotStamping] 	AS Equip6Tool1FlexoHotS_dsl,
			[EQT1].[DieSize] 			AS Equip6Tool1DieSize_dsl,
			[EQT1].[GearTeeth] 		    AS Equip6Tool1GearTeeth_dsl,
			[EQT1].[Location] 			AS Equip6Tool1Location_dsl,
			[EQT1].[SourceToolingId] 	AS Equip6Tool1Number_dsl,
			[EQT1].[LinerCaliper]		AS Equip6Tool1LinerCaliper_dsl,
			[EQT1].[NoAround]			AS Equip6Tool1NumberAround_dsl,
			[EQT1].[Shape]				AS Equip6Tool1Shape_dsl,
			[EQT1].[ToolDeliveryDate]	AS Equip6Tool1DeliveryDate_dsl,
			[EQT1].[Description]		AS Equip6Tool1Description_dsl,

			-- Equipment 6 => TOOL 2
			[EQT2].[FlexoHotStamping] 	AS Equip6Tool2FlexoHotS_dsl,
			[EQT2].[DieSize] 			AS Equip6Tool2DieSize_dsl,
			[EQT2].[GearTeeth] 		    AS Equip6Tool2GearTeeth_dsl,
			[EQT2].[Location] 			AS Equip6Tool2Location_dsl,
			[EQT2].[SourceToolingId] 	AS Equip6Tool2Number_dsl,
			[EQT2].[LinerCaliper]		AS Equip6Tool2LinerCaliper_dsl,
			[EQT2].[NoAround]			AS Equip6Tool2NumberAround_dsl,
			[EQT2].[Shape]				AS Equip6Tool2Shape_dsl,
			[EQT2].[ToolDeliveryDate]	AS Equip6Tool2DeliveryDate_dsl,
			[EQT2].[Description]		AS Equip6Tool2Description_dsl,

			-- Equipment 6 => TOOL 3
			[EQT3].[FlexoHotStamping] 	AS Equip6Tool3FlexoHotS_dsl,
			[EQT3].[DieSize] 			AS Equip6Tool3DieSize_dsl,
			[EQT3].[GearTeeth] 		    AS Equip6Tool3GearTeeth_dsl,
			[EQT3].[Location] 			AS Equip6Tool3Location_dsl,
			[EQT3].[SourceToolingId] 	AS Equip6Tool3Number_dsl,
			[EQT3].[LinerCaliper]		AS Equip6Tool3LinerCaliper_dsl,
			[EQT3].[NoAround]			AS Equip6Tool3NumberAround_dsl,
			[EQT3].[Shape]				AS Equip6Tool3Shape_dsl,
			[EQT3].[ToolDeliveryDate]	AS Equip6Tool3DeliveryDate_dsl,
			[EQT3].[Description]		AS Equip6Tool3Description_dsl,

			-- Equipment 6 => TOOL 4
			[EQT4].[FlexoHotStamping] 	AS Equip6Tool4FlexoHotS_dsl,
			[EQT4].[DieSize] 			AS Equip6Tool4DieSize_dsl,
			[EQT4].[GearTeeth] 		    AS Equip6Tool4GearTeeth_dsl,
			[EQT4].[Location] 			AS Equip6Tool4Location_dsl,
			[EQT4].[SourceToolingId] 	AS Equip6Tool4Number_dsl,
			[EQT4].[LinerCaliper]		AS Equip6Tool4LinerCaliper_dsl,
			[EQT4].[NoAround]			AS Equip6Tool4NumberAround_dsl,
			[EQT4].[Shape]				AS Equip6Tool4Shape_dsl,
			[EQT4].[ToolDeliveryDate]	AS Equip6Tool4DeliveryDate_dsl,
			[EQT4].[Description]		AS Equip6Tool4Description_dsl,

			-- Equipment 6 => TOOL 5
			[EQT5].[FlexoHotStamping] 	AS Equip6Tool5FlexoHotS_dsl,
			[EQT5].[DieSize] 			AS Equip6Tool5DieSize_dsl,
			[EQT5].[GearTeeth] 		    AS Equip6Tool5GearTeeth_dsl,
			[EQT5].[Location] 			AS Equip6Tool5Location_dsl,
			[EQT5].[SourceToolingId] 	AS Equip6Tool5Number_dsl,
			[EQT5].[LinerCaliper]		AS Equip6Tool5LinerCaliper_dsl,
			[EQT5].[NoAround]			AS Equip6Tool5NumberAround_dsl,
			[EQT5].[Shape]				AS Equip6Tool5Shape_dsl,
			[EQT5].[ToolDeliveryDate]	AS Equip6Tool5DeliveryDate_dsl,
			[EQT5].[Description]		AS Equip6Tool5Description_dsl

		FROM [dbo].[#TempTooling] AS [EQT1]
			LEFT JOIN [dbo].[#TempTooling] AS [EQT2] ON [EQT2].[TicketId] = [EQT1].[TicketId] AND [EQT2].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT2].[ToolNum] = 2
			LEFT JOIN [dbo].[#TempTooling] AS [EQT3] ON [EQT3].[TicketId] = [EQT1].[TicketId] AND [EQT3].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT3].[ToolNum] = 3
			LEFT JOIN [dbo].[#TempTooling] AS [EQT4] ON [EQT4].[TicketId] = [EQT1].[TicketId] AND [EQT4].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT4].[ToolNum] = 4
			LEFT JOIN [dbo].[#TempTooling] AS [EQT5] ON [EQT5].[TicketId] = [EQT1].[TicketId] AND [EQT5].[RoutingNumber] = [EQT1].[RoutingNumber] AND [EQT5].[ToolNum] = 5

		WHERE [EQT1].[RoutingNumber] = 6 AND [EQT1].[ToolNum] = 1;


		DROP TABLE IF EXISTS [dbo].[#TempTooling];
	END

END