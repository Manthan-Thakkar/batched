CREATE PROCEDURE [dbo].[spImportTicketStockData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spImportTicketStockData_Radius',
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
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'DeleteTicketStocks'; SET @startTime = GETDATE();

		BEGIN TRY		
			--Delete the records of TicketStock. 
			TRUNCATE TABLE [dbo].[TicketStock]
			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END


	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'InsertTicketStocks'; SET @startTime = GETDATE();
		DECLARE @MissingTicketMaster int;
		DECLARE @MissingStockMaterial int;

				-- #PV_Jobs temp table WITH concatenated ticket number
		SELECT 
			J.*,JC.JobCmpNum, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber
		INTO #PV_Jobs
		FROM PV_job J
			INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
		where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

		--PV_Job, PV_JobLine, PV_JobStep
		BEGIN TRY
			----Insert the records into TicketStock using Ticket table
			INSERT INTO [dbo].[TicketStock] ([Id], [TicketId], [StockMaterialId], [Sequence], [StockType] ,[Width], [Notes], [CreatedOn], [ModifiedOn], [RequiredQuantity], [TaskName], [Length])
				SELECT 
					NEWID(), 
					TM.ID,
					SM.Id, 
					ROW_NUMBER() OVER (PARTITION BY PVJ.TicketNumber ORDER BY PVJS.[est-route-seq] ASC,  PVJS.StepNum ASC), 
					CASE WHEN PVJS.StepType = 104 THEN 'HotFoil' WHEN PVJS.StepType in (105,115,116) THEN 'Laminate' WHEN PVJS.StepType = 113 THEN 'Substrate' ELSE NULL END, 
					ISNULL(PVR.DimA, 0),
					PVR.ReqText, 
					GETUTCDATE(),
					GETUTCDATE(),
					Case When PVR.RequiredQty - PVR.IssuedQty + PVR.IssReturnQty < 0 Then 0 Else PVR.RequiredQty - PVR.IssuedQty + PVR.IssReturnQty End,
					PVJS.LabStepNum,
					ISNULL(PVR.DimB,0)
				FROM
					#PV_Jobs PVJ 
				INNER JOIN TicketMaster TM ON PVJ.TicketNumber = TM.SourceTicketId
				INNER JOIN PV_JobStep PVJS ON PVJ.CompNum=PVJS.CompNum and PVJ.PlantCode = PVJS.PlantCode and PVJ.JobCode = PVJS.JobCode and PVJS.JobCmpNum = PVJ.JobCmpNum AND PVJS.StepType IN (104, 105, 113, 115,116) AND PVJS.JobCode IS NOT NULL
				INNER JOIN PV_JobStep PVJSL ON PVJ.CompNum = PVJSL.CompNum and PVJ.PlantCode = PVJSL.PlantCode and PVJ.JobCode = PVJSL.JobCode and PVJSL.JobCmpNum = PVJ.JobCmpNum and PVJS.LabStepNum = PVJSL.StepNum
				INNER JOIN PV_Req PVR ON PVJS.CompNum = PVR.CompNum AND PVJS.PlantCode = PVR.PlantCode AND PVJS.JobCode = PVR.JobCode AND PVJS.StepNum = PVR.StepNum
				INNER JOIN PM_Item PMI ON PMI.CompNum = PVR.CompNum AND PMI.ItemCode = PVR.ItemCode
				INNER JOIN StockMaterial SM ON SM.SourceStockId = PMI.ItemCode
				ORDER BY 
					TM.SourceTicketId ASC,
					PVJS.[est-route-seq] ASC

			SET @infoStr ='TotalRowsAffected|'+ Convert(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
    DROP TABLE IF EXISTS #PV_Jobs;
					   		
--	    ========================[final commit log (do not change)]=======================================
	IF @IsError = 0
	BEGIN
		COMMIT;
		INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
			@spName, 'final-commit', 'info', 'message|all blocks completed without any error')
	END
	SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--		=================================================================================================
END
