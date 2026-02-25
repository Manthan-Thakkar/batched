CREATE PROCEDURE spImportStockMaterialData
	@TenantId nvarchar(36)
AS
BEGIN

	--Identify the matching records in the StockMaterial table based upon matching Stock.StockNum and StockMaterial.SourceStockId with additional conditions of Source='LabelTraxx' and TenantId = @tenantId

	select SM.ID StockMaterialId, S.StockNum StockId, S.LinerCaliper LinerCaliper 
	into #MatchingStocks
	from StockMaterial SM
	inner join Stock S on S.StockNum = SM.SourceStockId and S.StockNum is not null
	where SM.Source='LabelTraxx' and SM.TenantId = @TenantId;

	--update StockMaterial
	UPDATE SM 
	set 
		FaceColor =	ISNULL(S.FaceColor,''), FaceStock =	ISNULL(S.FaceStock,''), Classification = ISNULL(S.Classification,''), IsEnabled = IIF(S.Inactive=0, 1, 0), ModifiedOn = GETUTCDATE(),
		SourceCreatedOn = CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)),
		SourceModifiedOn =CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108))
	from StockMaterial SM
	inner join #MatchingStocks MS on SM.Id = MS.StockMaterialId
	inner join Stock S on S.StockNum = SM.SourceStockId and S.StockNum is not null
		
	--insert StockMaterial

	INSERT INTO StockMaterial(Id,TenantId,Source,SourceStockId,FaceColor,FaceStock,LinerCaliper,Classification,IsEnabled,SourceCreatedOn,SourceModifiedOn,CreatedOn,ModifiedOn)
	select
		NEWID(), 
		@TenantId,
		'LabelTraxx',
		StockNum,
		ISNULL(S.FaceColor,''),
		ISNULL(S.FaceStock,''),
		S.LinerCaliper,
		ISNULL(S.Classification,''),
		IIF(S.Inactive=0, 1, 0),
		CONVERT(DATETIME, CONVERT(CHAR(8), EnteredDate, 112) + ' ' + CONVERT(CHAR(8), EnteredTime, 108)) SourceCreatedOn,
		CONVERT(DATETIME, CONVERT(CHAR(8), ModifiedDate, 112) + ' ' + CONVERT(CHAR(8), ModifiedTime, 108)) SourceModifiedOn,
		GETUTCDATE(),
		GETUTCDATE()
	from Stock S
	where StockNum not in (select StockId from #MatchingStocks) and S.StockNum is not null

				
	--insert StockMaterialSubstitute
	delete from StockMaterialSubstitute

	insert into StockMaterialSubstitute(Id, StockMaterialId, AlternateStockMaterialId, CreatedOn, ModifiedOn)
	select DISTINCT
		NEWID(), SM.Id, SM2.Id, GETUTCDATE(), GETUTCDATE()
	from Stock S
	inner join StockMaterial SM on S.StockNum = SM.SourceStockId
	inner join Stock S2 on S.StockSubstitute_1 = S2.StockNum
	inner join StockMaterial SM2 on S2.StockNum = SM2.SourceStockId
	where S.StockSubstitute_1 is not null and S.StockNum is not null
		
	union all

	select DISTINCT
		NEWID(), SM.Id, SM2.Id, GETUTCDATE(), GETUTCDATE()
	from Stock S
	inner join StockMaterial SM on S.StockNum = SM.SourceStockId
	inner join Stock S2 on S.StockSubstitute_2 = S2.StockNum
	inner join StockMaterial SM2 on S2.StockNum = SM2.SourceStockId
	where S.StockSubstitute_2 is not null and S.StockNum is not null

	union all
		
	select DISTINCT
		NEWID(), SM.Id, SM2.Id, GETUTCDATE(), GETUTCDATE()
	from Stock S
	inner join StockMaterial SM on S.StockNum = SM.SourceStockId
	inner join Stock S2 on S.StockSubstitute_3 = S2.StockNum
	inner join StockMaterial SM2 on S2.StockNum = SM2.SourceStockId
	where S.StockSubstitute_3 is not null and S.StockNum is not null



	drop table #MatchingStocks

END


