CREATE PROCEDURE [dbo].[spImportTicketItemData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketItemData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	int = 4000, --keep this exactly same as 4000
		@blockName				varchar(100),
		@warningStr				nvarchar(4000),
		@infoStr				nvarchar(4000),
		@errorStr				nvarchar(4000),
		@IsError				bit = 0,
		@startTime				datetime;
--	======================================================================================================
	END

	BEGIN TRANSACTION;

	-- #PV_Jobs temp table WITH concatenated ticket number
	SELECT 
		J.*,JC.JobCmpNum, JC.EstCmpNum, JC.CmpType, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
	INTO #PV_Jobs
	FROM PV_job J
		INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
	where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9


	SELECT
		JL.JobCode,
		JL.CompNum,
		LEFT(
			STRING_AGG(
				CONVERT(NVARCHAR(MAX), CONCAT(SOL.SOrderNum, '-', SOL.SOrderLineNum)),
				', '
			) WITHIN GROUP (ORDER BY SOL.SOrderNum, SOL.SOrderLineNum),
			1000
		) AS SalesOrderNumber,
		MIN(SO.SOrderDate) AS SalesOrderDate
	INTO #TempSalesOrder
	FROM PV_SOrderLine SOL
		INNER JOIN PV_SOrder SO
			ON SOL.CompNum = SO.CompNum AND SOL.PlantCode = SO.PlantCode AND SOL.SOrderNum = SO.SOrderNum
		LEFT JOIN PV_JobSOLink JSOL
			ON SOL.CompNum = JSOL.CompNum AND JSOL.SOPlantCode = SOL.PlantCode AND SOL.SOrderNum = JSOL.SOrderNum AND SOL.SOrderLineNum = JSOL.SOrderLineNum
		LEFT JOIN PV_JobLine JL
			ON JSOL.CompNum = JL.CompNum AND JSOL.PlantCode = JL.PlantCode AND JSOL.JobCode = JL.JobCode AND JSOL.JobLineNum = JL.JobLineNum
	GROUP BY JL.JobCode, JL.CompNum;

	
	select  
		Jl.TableRecId,
		JL.ItemCode,
		JL.OrderedQty,
		JL.JobLineStatus ,
		j.TicketNumber as TicketNumber,
		JL.ReceivedQty,
		JL.DimA as Width,
		JL.DimB as Length,
		JL.JobLineNum,
		TSO.SalesOrderNumber,
		FORMAT(TSO.SalesOrderDate, 'dd-MMM-yyyy') AS SalesOrderDate
	into #TicketItemInfoBaseData from #PV_Jobs J 
	-- inner join (select distinct * from [wi-profile]) p on j.JobCode = p.korder and p.[k-cmp-no] =
	-- CASE
	-- 	WHEN j.CmpType = 7
	-- 		THEN  j.JobCmpNum
	-- 	WHEN j.CmpType = 9
	-- 		THEN j.EstCmpNum 
	-- 	END	
	-- inner join [wi-seqqtyitem] s on j.JobCode = s.korder and p.[k-profile] = s.[k-profile] 
	inner join PV_JobLine JL on J.JobCode = JL.JobCode and J.CompNum = JL.CompNum --and s.[k-item-code] = JL.[ItemCode] 
	LEFT JOIN #TempSalesOrder TSO ON J.JobCode = TSO.JobCode AND J.CompNum = TSO.CompNum
	
    CREATE NONCLUSTERED INDEX [IX_TicketItemInfoBaseData_Temp] ON #TicketItemInfoBaseData (TableRecId)


	-- Matching id in temporary table
	SELECT ticItemInfo.Id as TicketItemId, ticitem.TableRecId as SourceTicketItemId
	INTO #MatchingTicketItems
	FROM #TicketItemInfoBaseData ticitem INNER JOIN TicketItemInfo ticItemInfo
	ON ticitem.TableRecId = ticItemInfo.SourceTicketItemId  AND ticitem.TableRecId IS NOT NULL


	;with SourceItemFinishTypeCalc as (
		Select 
			Jl.TableRecId , 
			CASE WHEN IP .PackType =1 then 'Products '
			WHEN IP .PackType =2 then 'Rolls'
			WHEN IP .PackType =3 then 'Fanfold'
			ELSE NULL END as FinishType,
			ROW_NUMBER() OVER(PARTITION BY Jl.TableRecId ORDER BY Jl.TableRecId DESC) AS row_number
		from #TicketItemInfoBaseData jl
		INNER JOIN PM_Item i on jl.ItemCode = i.ItemCode 
		INNER JOIN PV_ItemPacking ip on i.ItemCode = ip.ItemCode
	)

	select * into #SourceFinishType from SourceItemFinishTypeCalc where row_number = 1

		Select jl.TableRecId , min(soit.SOItemType) as SourcePriority
		into #TicketPriority 
		From #PV_Jobs j
		INNER JOIN #TicketItemInfoBaseData jl on j.TicketNumber = jl.TicketNumber
		INNER JOIN PV_JobSOLink jsol on j.CompNum = jsol.CompNum  and j.JobCode = jsol.JobCode and JL .JobLineNum = jsol.JobLineNum
		INNER JOIN PV_SOrder so on jsol.CompNum =so.CompNum and jsol.SOrderNum =so.SOrderNum 
		INNER JOIN PV_SOrderLine sol on so.CompNum = sol.CompNum and so.SOrderNum = sol.SOrderNum and jsol.SOrderLineNum = sol.SOrderLineNum 
		INNER JOIN PV_SOrderItemType soit on soit.CompNum = sol.CompNum and soit.SOItemTypeCode = sol.SOItemTypeCode
		group by jl.TableRecId

		select jl.TableRecId, min(uded.UDValue) as UDValue
		into #FinalUnwind
		from #TicketItemInfoBaseData jl
		INNER JOIN PM_Item i on jl.ItemCode = i.ItemCode 
		INNER JOIN PV_UDElementData uded on i.TableRecId = uded.UDLinkRecId and uded.LinkPoint = 3
		Where uded.UDElement = 'Direction Off'
		group by jl.TableRecId

		SELECT jl.CompNum , jl.PlantCode , jl.JobCode , jl.JobLineNum, jl.tablerecid, count(1) as NumColors
		into #NumColorsCalc 
		FROM PV_JobLine jl 
		INNER JOIN PM_Item i on jl.CompNum = i.CompNum and jl.ItemCode = i.ItemCode 
		INNER JOIN [item-coating] ic on i.CompNum = ic.kco and i.ItemCode = ic.[item-code]
		WHERE ic.TYPE = 'INK'
		GROUP BY jl.CompNum , jl.PlantCode , jl.JobCode , jl.JobLineNum, jl.tablerecid

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		DECLARE @UpdateMissingCount int
		

		SET @blockName = 'UpdateTicketItems'; SET @startTime = GETDATE();

		Begin TRY		
					-- Update the records
			Update TicketItemInfo 
			set
			    ProductId = pMstr.Id,
				StockProductId = spMstr.Id,
				NumColors = ISNULL(nc.NumColors, 0),
				OrderQuantity = ticitem.OrderedQty,
				ModifiedOn = GETUTCDATE(),
				WorkStatus = CASE WHEN ticitem.JobLineStatus =  0 THEN 'Active' else 'Complete' END, -- 9 = Complete, add condition for 9 in case only if 3rd status arrives
				SourceTicketItemFinishType = s.FinishType,
				SourceTicketItemFinalUnwind =f.UDValue,
				SourceTicketItemPriority = t.SourcePriority,
				Width = ticitem.Width,
				Length = ticitem.Length,
				ReceivedQuantity = ticitem.ReceivedQty,
				SalesOrderNumber = ticitem.SalesOrderNumber,
				SalesOrderDate = ticitem.SalesOrderDate
			from 
			TicketItemInfo ticItemInfo
			INNER JOIN #MatchingTicketItems mtic ON ticItemInfo.Id = mtic.TicketItemId
			INNER JOIN #TicketItemInfoBaseData ticitem ON ticitem.TableRecId = ticItemInfo.SourceTicketItemId-- AND ticitem.TableRecId IS NOT NULL
			LEFT JOIN StockProductMaster spMstr ON ticitem.ItemCode = spMstr.SourceStockProductId 
			LEFT JOIN ProductMaster pMstr ON ticitem.ItemCode = pMstr.SourceProductId
			LEFT JOIN #FinalUnwind f on ticitem.TableRecId = f.TableRecId
			LEFT JOIN #TicketPriority t on ticitem.TableRecId = t.TableRecId
			LEFT JOIN #SourceFinishType s on ticitem.TableRecId = s.TableRecId
			LEFT JOIN #NumColorsCalc nc on ticitem.TableRecId = nc.TableRecId


			
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

			--- Find the record which have product numer Or stock product id as null
			Select @UpdateMissingCount = COUNT(1) 
			from  #MatchingTicketItems mtic 
			INNER JOIN #TicketItemInfoBaseData ticitem ON ticitem.TableRecId = mtic.SourceTicketItemId
			AND ticitem.TableRecId IS  NULL
			WHERE ticItem.ItemCode IS  NULL

			--- Log warning if such records exists
			IF (@UpdateMissingCount > 0)
			BEGIN
			SET  @warningStr ='Missing_Records_For_Update_Count|'+ Convert(varchar, @UpdateMissingCount)
			END

			
		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	

	IF @IsError = 0	
	  	BEGIN
		DECLARE @InsertMissingProductStockProductCount int
		DECLARE @InsertMissingTicketMasterCount int
		SET @blockName = 'InsertTicketItems'; SET @startTime = GETDATE();

		Begin TRY
		-- Insert the new records
		INSERT INTO [dbo].[TicketItemInfo] ([Id]  ,[TicketId],[ProductId],[StockProductId],
		[NumColors],[OrderQuantity],[SourceTicketItemId],[CreatedOn],[ModifiedOn],[WorkStatus],[SourceTicketItemFinishType],[SourceTicketItemFinalUnwind],[SourceTicketItemPriority],
		[Width],[Length],[ReceivedQuantity], [SalesOrderNumber], [SalesOrderDate])
		   SELECT 
				NEWID(),
				ticMstr.ID,
				pMstr.Id,
				spMstr.Id,
				ISNULL(nc.NumColors, 0),
				ticItem.OrderedQty,
				ticItem.TableRecId,
				GETUTCDATE(),
				GETUTCDATE(),
				CASE WHEN ticitem.JobLineStatus =  0 THEN 'Active' else 'Complete' END ,-- 9 = Complete, add condition for 9 in case only if 3rd status arrives
				s.FinishType,
				f.UDValue,
				t.SourcePriority,
				ticItem.Width,
				ticItem.Length,
				ticitem.ReceivedQty,
				ticItem.SalesOrderNumber,
				ticItem.SalesOrderDate
			FROM #TicketItemInfoBaseData ticItem LEFT JOIN StockProductMaster spMstr
			ON ticitem.ItemCode = spMstr.SourceStockProductId 
			LEFT JOIN ProductMaster pMstr ON ticitem.ItemCode = pMstr.SourceProductId
			INNER JOIN TicketMaster ticMstr ON ticMstr.SourceTicketId = ticItem.Ticketnumber
			LEFT JOIN #FinalUnwind f on ticitem.TableRecId = f.TableRecId
			LEFT JOIN #TicketPriority t on ticitem.TableRecId = t.TableRecId
			LEFT JOIN #SourceFinishType s on ticitem.TableRecId = s.TableRecId
			LEFT JOIN #NumColorsCalc nc on ticitem.TableRecId = nc.TableRecId
			Where ticItem.TableRecId not in (select SourceTicketItemId from #MatchingTicketItems) 
			and ticItem.TableRecId IS NOT NULL
		-------
		
		--- Set info string for total rows affected
		SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
		----
		
		--- Not inserted due to null mapping from stock product/product
		Select TableRecId
		into #NullStockProductProduct
		from #TicketItemInfoBaseData
		Where (ItemCode Is Null)
		AND( TableRecId not in (select SourceTicketItemId from #MatchingTicketItems) 
		AND TableRecId IS NOT NULL)

		Select @InsertMissingProductStockProductCount = Count(1) from #NullStockProductProduct

		IF (@InsertMissingProductStockProductCount > 0)
		BEGIN
			SET  @warningStr =  'NullRows_TicketItem_ProductId_AND_StockProductId|'+ Convert(varchar, @InsertMissingProductStockProductCount)
		END
		-------
		
		--- Not inserted due to null mapping from ticket master
		Select @InsertMissingTicketMasterCount = Count(1) from #TicketItemInfoBaseData 
		where  TableRecId not in (select SourceTicketItemId from #MatchingTicketItems ) 
		and TableRecId not in (select TableRecId from #NullStockProductProduct)
		and TicketNumber not in (Select SourceTicketId from TicketMaster) 

		if (@InsertMissingTicketMasterCount>0)
		Begin 
			SET @warningStr =  COALESCE( @warningStr,'')+ '#MappingNotFound_TicketItem_TicketMaster|'+CAST((@InsertMissingTicketMasterCount) as varchar(10)) 
		End
		-------
		

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
				
		-- Delete temporary table
		drop table if exists #PV_Jobs;
		drop table if exists #MatchingTicketItems
		drop table if exists #NullStockProductProduct	  
		drop table if exists #TicketPriority
		drop table if exists #SourceFinishType
		drop table if exists #FinalUnwind
		drop table if exists #NumColorsCalc
		drop table if exists #TicketItemInfoBaseData
		drop table if exists #TempSalesOrder
	
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' as __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END