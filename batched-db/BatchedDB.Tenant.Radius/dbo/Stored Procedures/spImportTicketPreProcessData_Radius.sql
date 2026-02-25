CREATE PROCEDURE [dbo].[spImportTicketPreProcessData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketPreProcessData_Radius',
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
		J.CompNum, J.PlantCode, J.JobCode, J.StatusCode, JC.JobCmpNum, JC.CmpType, JC.EstCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber, J.TableRecId 
	INTO #PV_Jobs
	FROM PV_job J
		INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
	where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

	-- Matching id in temporary table
	SELECT ticMaster.Id as TicketId, TicketNumber
	INTO #MatchingTickets
	from TicketPreProcess ticPreProc 
	INNER JOIN TicketMaster ticMaster ON ticPreProc.TicketId = ticMaster.ID 
	INNER JOIN #PV_Jobs tic on tic.TicketNumber = ticMaster.SourceTicketId
	WHERE ticMaster.Source = 'Radius' AND ticMaster.TenantId = @TenantId


	---- ProofComplete data
	;WITH itemapprovals AS 
(SELECT ia.CompNum, ia.ItemCode, ias.StatusDesc, ia.LastUpdatedDateTime, ROW_NUMBER() OVER (Partition by ia.CompNum, ia.ItemCode Order by ia.ApprovalDate DESC, ia.ApprovalTime DESC, ia.ApproTimeSecs DESC, ia.LastUpdatedDateTime DESC) as RowNumber
From PV_ItemApproval ia WITH(NOLOCK)
	INNER JOIN PV_ItemApprovStatus ias WITH(NOLOCK) on ia.StatusNum = ias.StatusNum
	WHERE ia.LevelNum = 1)

	SELECT *
	INTO #ItemApprovals
	FROM itemapprovals
	WHERE RowNumber = 1;

	Select TicketNumber AS JobCode
	INTO #ProofCompleteData
	from #PV_Jobs J
	INNER JOIN PV_JobLine jl on j.CompNum = jl.CompNum and j.JobCode = jl.JobCode -- and j.PlantCode = jl.PlantCode 
	LEFT JOIN #ItemApprovals ia on j.CompNum = ia.CompNum and jl.ItemCode = ia.ItemCode
	--INNER JOIN PM_Item PMI on jl.ItemCode = PMI.ItemCode and JL.CompNum = PMI.CompNum
	--INNER JOIN PV_ItemApproval ia on PMI.ItemCode = ia.ItemCode and PMI.CompNum = ia.CompNum
	--INNER JOIN PV_ItemApprovStatus ias on ia.CompNum = ias.CompNum and ia.StatusNum = ias.StatusNum
	--INNER JOIN PV_ItemApprovLevel ial on ia.CompNum = ial.CompNum and ia.LevelNum = ial.LevelNum
	--Where ial.LevelNum = 1
	group by j.TicketNumber
	Having( Count(*) = count(CASE WHEN ia.StatusDesc = 'Proof Approved' THEN 1 END) 
	OR Count(*) = count( CASE WHEN ia.StatusDesc = 'Proof Approved' and J.StatusCode = 'VDPACTIVE' THEN 1 END)
	OR Count(*) = count( CASE WHEN jl.ItemCode is null THEN 1 END) );

	---- ProofStatus data
	Select j.TicketNumber as JobCode
		,string_agg(ia.StatusDesc, ', ') within group (Order by jl.JobLineNum ASC) as ProofStatus
	INTO #ProofStatusData
	from #PV_Jobs J
	INNER JOIN PV_JobLine jl on j.CompNum = jl.CompNum and j.JobCode = jl.JobCode --and j.PlantCode = jl.PlantCode 
	LEFT JOIN #ItemApprovals ia on j.CompNum = ia.CompNum and jl.ItemCode = ia.ItemCode
	--INNER JOIN PM_Item PMI on jl.ItemCode = PMI.ItemCode and JL.CompNum = PMI.CompNum
	--INNER JOIN PV_ItemApproval ia on PMI.ItemCode = ia.ItemCode and PMI.CompNum = ia.CompNum
	--INNER JOIN PV_ItemApprovStatus ias on ia.CompNum = ias.CompNum and ia.StatusNum = ias.StatusNum
	--INNER JOIN PV_ItemApprovLevel ial on ia.CompNum = ial.CompNum and ia.LevelNum = ial.LevelNum
	--Where ial.LevelNum = 1
	group by j.TicketNumber;

	SET @blockName = 'SpecCache'; SET @startTime = GETDATE();

	--toolsIn data

		Select DISTINCT j.TicketNumber, j.CompNum , j.PlantCode , j.JobCode, ts.SpecCode, j.JobCmpNum, j.CmpType, t.StatusAvailable,t.ToolCode
			into #speccache
			From #PV_Jobs j
			LEFT JOIN PV_JobToolSpec jts on j.CompNum = jts.CompNum AND j.PlantCode = jts.PlantCode and j.JobCode = jts.JobCode --and j.JobCmpNum = jts.JobCmpNum  
			LEFT JOIN PV_ToolSpec ts on j.CompNum = ts.CompNum AND jts.SpecCode = ts.SpecCode --and jts.ToolTypeCode = ts.ToolTypeCode 
			LEFT JOIN PV_Tools t on j.CompNum = t.CompNum AND j.PlantCode = t.PlantCode and ts.SpecCode = t.SpecCode --and ts.ToolTypeCode = t.ToolTypeCode

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'SpecTools'; SET @startTime = GETDATE();

	--toolsIn data

		Select j.CompNum , j.PlantCode , j.JobCode, j.SpecCode, j.JobCmpNum, count(j.ToolCode) as NumTools 
			into #spectools
			From #speccache j
			Where j.StatusAvailable = 1
			Group by j.CompNum, j.PlantCode, j.JobCode, j.SpecCode, j.JobCmpNum
			Having count(j.ToolCode) > 0
	
	--Create Index ix5 on #spectools (CompNum, PlantCode, JobCode, SpecCode, JobCmpNum);

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'SpectoolsReceived'; SET @startTime = GETDATE();

		Select j.CompNum , j.PlantCode , j.JobCode, j.SpecCode, j.JobCmpNum, ISNULL(Case When st.NumTools > 0 Then 1 Else 0 End, 0) as SpecToolReceived
			into #spectoolsreceived
			From #speccache j
			Left JOIN #spectools st on st.CompNum = j.CompNum and st.PlantCode = j.PlantCode and st.JobCode = j.JobCode and st.SpecCode = j.SpecCode and st.JobCmpNum = j.JobCmpNum
			Where j.SpecCode IS NOT NULL
	
	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'JobSpecsRecieved'; SET @startTime = GETDATE();

		Select sr.CompNum, sr.PlantCode, sr.JobCode, sr.JobCmpNum, count(sr.JobCode) as NumSpecs, sum(sr.SpecToolReceived) as AvailableSpecs
			into #jobspecsreceived 
			From #spectoolsreceived sr
			Group by CompNum, PlantCode, JobCode, JobCmpNum

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'ToolsInData'; SET @startTime = GETDATE();

	Select Concat(CompNum,'_',PlantCode,'_',JobCode,'_',JobCmpNum) as JobCode, Case When NumSpecs = AvailableSpecs Then 1 Else 0 End as ToolsIn
	Into #ToolsInData
	From #jobspecsreceived jsr

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	SET @blockName = 'NoToolJobs'; SET @startTime = GETDATE();

	Select sc.TicketNumber JobCode, count(*) as NumSpecs
	Into #NoToolJobs
	From #speccache sc
	Where sc.SpecCode IS NULL and sc.CmpType IN (7,9,10)
	Group by sc.TicketNumber

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT

	SET @blockName = 'UDElementParse'; SET @startTime = GETDATE();

	Select j.TicketNumber as JobCode,
	count(IIF(uded.UDElement = 'Full Form Ready' AND uded.UDValue = 'Yes', 1, NULL)) as FullFormReady,
	count(IIF(uded.UDElement = 'Plates Staged' AND uded.UDValue = 'Yes', 1, NULL)) as PlatesStaged,
	count(IIF(uded.UDElement = 'Plates Mounted' AND uded.UDValue = 'Yes', 1, NULL)) as PlatesMounted,
	count(IIF(uded.UDElement = 'Tool Staged' AND uded.UDValue = 'Yes', 1, NULL)) as DieStaged,
	count(IIF(uded.UDElement = 'Inks Staged' AND uded.UDValue = 'Yes', 1, NULL)) as InksStaged,
	count(IIF(uded.UDElement = 'Stock Staged' AND uded.UDValue = 'Yes', 1, NULL)) as StockStaged
	INTO #UDValues
	From #PV_Jobs J	
	INNER JOIN PV_UDElementData uded on uded.UDLinkRecId = j.TableRecId 
	where UDGroup = 'Preproduction'
	group by j.TicketNumber

	INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT


	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'UpdateTicketPreProcess'; SET @startTime = GETDATE();

		Begin TRY		
					-- Update the records
			Update TicketPreProcess 
			set
				ModifiedOn = GETUTCDATE(),
				ArtStatus = NULL,
				ProofStatus = PS.ProofStatus,
				ToolStatus = NULL,
				ArtWorkComplete =1,
				ArtWorkStaged=CASE WHEN uv.FullFormReady IS NOT NULL AND uv.FullFormReady = 1 THEN 1 ELSE 0 END,
				ProofComplete = CASE WHEN PD.JobCode IS NOT NULL THEN 1 ELSE 0 END,
				ProofStaged=0,
				PlateComplete = CASE WHEN uv.PlatesStaged IS NOT NULL AND uv.PlatesStaged = 1 THEN 1 ELSE 0 END,
				PlateStaged= CASE WHEN uv.PlatesMounted IS NOT NULL AND uv.PlatesMounted = 1 THEN 1 ELSE 0 END,
				ToolsReceived =Case When isnull( td.ToolsIn,0) > 0 OR ntj.JobCode IS NOT NULL Then 1 Else 0 End,
				ToolsStaged=CASE WHEN uv.DieStaged IS NOT NULL AND uv.DieStaged = 1 THEN 1 ELSE 0 END,
				InkReceived = 1,
				InkStaged=CASE WHEN uv.InksStaged IS NOT NULL AND uv.InksStaged = 1 THEN 1 ELSE 0 END,
				StockReceived = 'In' ,
				StockStaged=CASE WHEN uv.StockStaged IS NOT NULL AND uv.StockStaged = 1 THEN 1 ELSE 0 END
			from
			TicketPreProcess ts 
			INNER JOIN TicketMaster ticMaster on ts.TicketId = ticMaster.id
			INNER JOIN #MatchingTickets mtic ON ticMaster.Id = mtic.TicketId
			INNER JOIN #PV_Jobs tic ON tic.TicketNumber = ticMaster.SourceTicketId AND tic.JobCode IS NOT NULL
			LEFT JOIN #ProofCompleteData PD on tic.TicketNumber= PD.JobCode
			LEFT JOIN #ProofStatusData PS on tic.TicketNumber = PS.JobCode
			LEFT JOIN #ToolsInData TD on tic.TicketNumber = TD.JobCode
			LEFT JOIN #NoToolJobs ntj on tic.TicketNumber = ntj.JobCode
			LEFT JOIN #UDValues uv on tic.TicketNumber = uv.JobCode
			

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)
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
		SET @blockName = 'InsertTicketPreProcess'; SET @startTime = GETDATE();

		Begin TRY
			-- Insert the new records
			INSERT INTO [dbo].[TicketPreProcess] ([TicketId],[CreatedOn],[ModifiedOn],[ArtStatus],[ProofStatus],[ToolStatus] ,[ArtWorkComplete] , [ArtWorkStaged],[ProofComplete] , [ProofStaged] ,[PlateComplete], [PlateStaged],[ToolsReceived] , [ToolsStaged],[InkReceived], [InkStaged],[StockReceived], [StockStaged])
		   SELECT 
				ticMaster.ID, --[TicketId]
				GETUTCDATE(), --[CreatedOn]
				GETUTCDATE(), --[ModifiedOn]
				NULL, --[ArtStatus]
				PS.ProofStatus, --[ProofStatus]
				NULL, --[ToolStatus]
				1,--[ArtWorkComplete],
				CASE WHEN uv.FullFormReady IS NOT NULL AND uv.FullFormReady = 1 THEN 1 ELSE 0 END,  --[ArtWorkStaged]
				CASE WHEN PD.JobCode IS NOT NULL THEN 1 ELSE 0 END,--[ProofReceived]
				0,  --[ProofStaged]
				CASE WHEN uv.PlatesStaged IS NOT NULL AND uv.PlatesStaged = 1 THEN 1 ELSE 0 END,--[PlateReceived]
				CASE WHEN uv.PlatesMounted IS NOT NULL AND uv.PlatesMounted = 1 THEN 1 ELSE 0 END,  --[PlateStaged]
				Case When isnull(td.ToolsIn,0) > 0 OR ntj.JobCode IS NOT NULL Then 1 Else 0 End, --[ToolsReceived]
				ToolsStaged=CASE WHEN uv.DieStaged IS NOT NULL AND uv.DieStaged = 1 THEN 1 ELSE 0 END,  --[ToolsStaged]
				1, --[inkreceived]
				CASE WHEN uv.InksStaged IS NOT NULL AND uv.InksStaged = 1 THEN 1 ELSE 0 END,  --[InkStaged]
				'In', --[StockReceived]
				CASE WHEN uv.StockStaged IS NOT NULL AND uv.StockStaged = 1 THEN 1 ELSE 0 END  --[StockStaged]
			FROM #PV_Jobs tic 
			INNER JOIN TicketMaster ticMaster on tic.TicketNumber = ticMaster.SourceTicketId
			LEFT JOIN #ProofCompleteData PD on tic.TicketNumber = PD.JobCode
			LEFT JOIN #ProofStatusData PS on tic.TicketNumber = PS.JobCode
			LEFT JOIN #ToolsInData TD on tic.TicketNumber = TD.JobCode
			LEFT JOIN #NoToolJobs ntj on tic.TicketNumber = ntj.JobCode
			LEFT JOIN #UDValues uv on tic.TicketNumber = uv.JobCode
			Where tic.TicketNumber NOT IN (select TicketNumber from #MatchingTickets) 
			AND tic.JobCode IS NOT NULL
			
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

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
			drop table if exists #MatchingTickets
			drop table if exists #ItemApprovals
			drop table if exists #ProofCompleteData
			drop table if exists #ProofStatusData
			drop table if exists #ToolsInData
			drop table if exists #NoToolJobs
			drop table if exists #PV_Jobs
			drop table if exists #speccache
			drop table if exists #jobspecsreceived
			drop table if exists #spectools
			drop table if exists #spectoolsreceived
			drop table if exists #UDValues
					   		
	
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