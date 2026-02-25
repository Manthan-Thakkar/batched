CREATE PROCEDURE [dbo].[spImportTicketDimensionsData_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		NVARCHAR(36),
	@CorelationId	VARCHAR(100)
AS		
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					VARCHAR(100) = 'spImportTicketDimensionsData_Radius',
		@__ErrorInfoLog			__ErrorInfoLog,
		@maxCustomMessageSize	INT = 4000, --keep this exactly same AS 4000
		@blockName				VARCHAR(100),
		@warningStr				NVARCHAR(4000),
		@infoStr				NVARCHAR(4000),
		@errorStr				NVARCHAR(4000),
		@IsError				BIT = 0,
		@startTime				DATETIME;
--	======================================================================================================
	END

	BEGIN TRANSACTION;
	
	DROP TABLE IF EXISTS #MatchingTicketDimensions;
	DROP TABLE IF EXISTS #MatchingNumLeftoverRolls;

	-- #PV_Jobs temp table WITH concatenated ticket number
	SELECT 
		J.*,JC.JobCmpNum,JC.NumberUp, CONCAT( J.CompNum,'_',J.PlantCode,'_',J.JobCode,'_',JC.JobCmpNum) AS TicketNumber, JC.PrintRepeat
	INTO #PV_Jobs
	FROM PV_job J
		INNER JOIN PV_JobComponent JC ON J.CompNum = JC.CompNum AND J.PlantCode = JC.PlantCode AND J.JobCode = JC.JobCode 
	where JC.CmpType IN (7,9,10) --jobs with more than one component will have cmp type of 9

	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'GeneratingTicketsMapping'; SET @startTime = GETDATE();
		DECLARE @MissingTicketDimensions INT;

		BEGIN TRY	
			-- Matching id in temporary table
			SELECT 
				TicketMaster.Id AS TicketId, 
				J.TicketNumber AS TicketNumber
			INTO
				#MatchingTicketDimensions
			FROM
				TicketDimensions
				INNER JOIN TicketMaster ON TicketDimensions.TicketId = TicketMaster.ID 
				INNER JOIN #PV_Jobs J ON J.TicketNumber = TicketMaster.SourceTicketId
			WHERE 
				TicketMaster.Source = 'Radius'
				AND TicketMaster.TenantId = @TenantId

			SET @infoStr ='TotalRowsAffected|'+ Convert(VARCHAR, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
		END
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	  	BEGIN
		SET @blockName = 'Data preperation'; SET @startTime = GETDATE();

		BEGIN TRY	

		--- Quantity data
		SELECT  
			SUM(JL.OrderedQty) Quantity,
			SUM(JL.ReceivedQty) ActualQuantity,
			J.TicketNumber AS TicketNumber
			INTO #QuantityData
		FROM #PV_Jobs J 
		INNER JOIN PV_JobLine JL ON J.JobCode = JL.JobCode AND J.CompNum = JL.CompNum -- AND J.PlantCode = JL.PlantCode
		GROUP BY J.TicketNumber
			

		--- Toolspecdata
		;WITH ToolSpecCalc AS (
			 SELECT  
				 TS.SizeDown AS SizeAround,
				 TS.Shape,
				 TS.SizeAcross,
				 TS.GapAcross AS ColumnSpace,
				 TS.GapDown AS RowSpace,
				 TS.Streams AS NumAcross,
				 TS.NumberDown AS NumAroundPlate,
				 TS.SizeDown + TS.GapDown AS LabelRepeat,
				 J.TicketNumber AS TicketNumber,
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum,J.JobCmpNum ORDER BY JTS.SeqNum ASC) AS row_number
			FROM #PV_Jobs J 
			INNER JOIN PV_JobToolSpec  JTS ON JTS.JobCode=J.JobCode AND JTS.CompNum=J.CompNum AND JTS.PlantCode = J.PlantCode-- AND JTS.JobCmpNum = J.JobCmpNum 
			INNER JOIN PV_ToolSpec TS ON JTS.CompNum = TS.CompNum AND JTS.SpecCode = TS.SpecCode
		)

		SELECT * INTO #ToolSpec  FROM ToolSpecCalc where row_number = 1

		;WITH NumCalc AS (
			SELECT 
				wp.[wi-pack-no-across] AS FinishedNumAcross,
				wp.[wi-pack-items-roll] AS FinishedNumLabels,
				wp.[wi-pack-diameter] AS CoreSize,
				wp.[wi-pack-maxdiam] AS outsideDiameter,
				wp.[wi-pack-wicket-qty] AS PackQuantity,
				wp.[wi-pack-length] AS RollingLength,
				CASE WHEN wp.[wi-pack-calc-method] = 1 THEN 'Products' 
					WHEN wp.[wi-pack-calc-method] = 2 THEN 'Rolls' 
					WHEN wp.[wi-pack-calc-method] = 3 THEN 'Sheets' 
					WHEN wp.[wi-pack-calc-method] = 4 THEN 'Folds' 
					ELSE ''
				END AS RollingUnit,
				J.TicketNumber AS TicketNumber,
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum ORDER BY J.jobcmpnum DESC) AS row_number
			FROM #PV_Jobs J 
			INNER JOIN [wi-pack] wp ON J.CompNum = wp.kco AND J.JobCode = wp.korder -- AND J.JobCmpNum = wp.[k-cmp-no]
		)

		SELECT * INTO #NumData FROM NumCalc where row_number = 1

		--FlatSize
		;WITH FlatSizeCalc AS (
			SELECT
				WP.[wi-p-blank-w] as FlatSizeWidth,
				WP.[wi-p-blank-l] as FlatSizeLength,
				J.TicketNumber,
				ROW_NUMBER() OVER(PARTITION BY J.jobcode,J.plantcode,J.compnum,J.JobCmpNum  ORDER BY J.JobCmpNum) AS row_number
			FROM #PV_Jobs J
			INNER JOIN [wi-profile] WP ON J.CompNum = WP.kco AND J.JobCode = WP.korder -- AND J.JobCmpNum = WP.[k-cmp-no]
		)
		SELECT * INTO #FlatSize FROM FlatSizeCalc WHERE row_number = 1

		SELECT
			CONCAT( CompNum,'_',PlantCode,'_',JobCode,'_',JobCmpNum) AS TicketNumber,
			SUM(InputQty)  AS EstimatedLength,
			SUM(OutputQty) AS ActualFootage
		INTO #JobStepCalc
		FROM PV_JobStep 
		Where StepType in (2,3) AND VRType = 2 AND [est-route-seq] = 1 --AND CmpType = 7
		GROUP BY CompNum,PlantCode,JobCode,JobCmpNum

		SELECT
			J.TicketNumber AS TicketNumber,
			SUM(p.[wi-rp-plate-qty])  NumberOfPlateChanges
		INTO #NoPlateChangesData 
		FROM #PV_Jobs J 
		INNER JOIN [wi-rplate] p ON J.CompNum = p.kco AND J.PlantCode = p.PlantCode AND J.JobCode = p.korder AND J.JobCmpNum = p.[k-cmp-no]
		GROUP BY J.TicketNumber

		SELECT
			TM.ID as TicketId,
			0 as ConsecutiveNumber, 
			ISNULL(Q.Quantity,0) as Quantity, 
			ISNULL(Q.ActualQuantity,0) as ActualQuantity,
			ISNULL(TS.SizeAcross,0) as SizeAcross,
			ISNULL(TS.SizeAround,0) as SizeAround,
			ISNULL(TS.Shape,0) as Shape,
			ISNULL(TS.ColumnSpace,0) as ColumnSpace,
			ISNULL(TS.RowSpace,0) as RowSpace,
			ISNULL(TS.NumAcross,0) as NumAcross,
			ISNULL(TS.NumAroundPlate,0) as NumAroundPlate,
			ISNULL(TS.LabelRepeat,0) as LabelRepeat,
			ISNULL( ND.FinishedNumAcross,0) as FinishedNumAcross,
			ISNULL( ND.FinishedNumLabels,0) as FinishedNumLabels,
			ISNULL( ND.CoreSize,0) as CoreSize,
			ISNULL( ND.OutsideDiameter,0) as OutsideDiameter,
			ISNULL(JS.EstimatedLength,0) as EsitmatedLength,
			0 as OverRunLength,
			ISNULL(N.NumberOfPlateChanges,0) as NoPlateChanges,
			(ceiling((Q.Quantity)/(CASE WHEN TS.NumAcross = 0 THEN 1 ELSE TS.NumAcross END * CASE WHEN TS.NumAroundPlate = 0 THEN 1 ELSE TS.NumAroundPlate END)) * (CASE WHEN TS.NumAroundPlate = 0 THEN 1 ELSE TS.NumAroundPlate END * (TS.SizeAround + TS.RowSpace)))/1000.0 as CalcLinearLength ,
			TRY_CONVERT(DECIMAL(10,2), CASE WHEN (Q.Quantity - Q.ActualQuantity > 0) THEN  (Q.Quantity - Q.ActualQuantity) ELSE 0 END/CASE WHEN ND.FinishedNumLabels=0 THEN 1 ELSE ND.FinishedNumLabels END) as CalcNumLeftoverRolls,
			(TS.SizeAround + TS.RowSpace)*(ND.FinishedNumLabels/CASE WHEN ND.FinishedNumAcross = 0 THEN 1 ELSE ND.FinishedNumAcross END) / 1000 as CalcFinishedRollLength,
			(CASE WHEN ND.FinishedNumAcross = 0 THEN 1 ELSE ND.FinishedNumAcross END) * (TS.SizeAcross + TS.ColumnSpace) as CalcCoreWidth,
			try_CONVERT(DECIMAL(10,5),CASE When ND.RollingUnit = 'Rolls' Then NULLIF(Q.Quantity,0) WHEN ND.FinishedNumLabels = 0 THEN NULL ELSE NULLIF(Q.Quantity,0)*1.0 / CASE WHEN ND.FinishedNumLabels=0 THEN 1 ELSE ND.FinishedNumLabels END END) / NULLIF(TS.NumAcross,0) * CASE WHEN ND.FinishedNumAcross = 0 THEN 1 ELSE ND.FinishedNumAcross END as CalcNumStops,
			GETUTCDATE() as ModifiedOn,
			ISNULL(JS.ActualFootage,0) as ActFootage,
			NULL as CoreType,
			ISNULL(ND.RollingLength,0) as RollLength,
			ND.RollingUnit as RollUnit,
			ISNULL(JS.EstimatedLength,0) as EstimatedLength,
			J.PrintRepeat,
			FS.FlatSizeWidth,
			FS.FlatSizeLength,
			ND.PackQuantity,
			J.NumberUp
		Into #ticketdimensions
		FROM #PV_Jobs J
			INNER JOIN TicketMaster TM ON J.TicketNumber = TM.SourceTicketID
			LEFT JOIN #MatchingTicketDimensions MTD ON J.TicketNumber = MTD.TicketNumber
			LEFT JOIN [TicketDimensions] TD ON TD.TicketId = MTD.TicketId 
			LEFT join #QuantityData Q ON J.TicketNumber = Q.TicketNumber
			LEFT JOIN #ToolSpec TS ON J.TicketNumber = TS.TicketNumber
			LEFT JOIN #NumData  ND ON J.TicketNumber = ND.TicketNumber
			LEFT JOIN #JobStepCalc JS ON J.TicketNumber = JS.TicketNumber
			left join #NoPlateChangesData N ON J.TicketNumber = N.TicketNumber
			LEFT JOIN #FlatSize FS ON J.TicketNumber = FS.TicketNumber

        END TRY
        BEGIN CATCH
        --==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
        END

    -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0 
        BEGIN
        SET @blockName = 'UpdateTicketDimensions'; SET @startTime = GETDATE();

        BEGIN TRY
            ----Update the records INTO TicketDimensions table
            Update
                TicketDimensions
            set
                ConsecutiveNumber       = td.ConsecutiveNumber, --- questions needed
                Quantity                = td.Quantity,
                ActualQuantity          = td.ActualQuantity,
                SizeAcross              = td.SizeAcross,
                SizeAround              = td.SizeAround,
                Shape                   = td.Shape,
                ColumnSpace             = td.ColumnSpace,
                RowSpace                = td.RowSpace,
                NumAcross               = td.NumAcross,
                NumAroundPlate          = td.NumAroundPlate,
                LabelRepeat             = td.LabelRepeat,
                FinishedNumAcross       = td.FinishedNumAcross,
                FinishedNumLabels       = td.FinishedNumLabels,
                CoreSize                = td.CoreSize,
                OutsideDiameter         = td.OutsideDiameter,
                EsitmatedLength         = td.EstimatedLength,
                OverRunLength           = td.OverRunLength,
                NoPlateChanges          = td.NoPlateChanges,
                CalcLinearLength        = td.CalcLinearLength,
                CalcNumLeftoverRolls    = td.CalcNumLeftoverRolls,
                CalcFinishedRollLength  = td.CalcFinishedRollLength,
                CalcCoreWidth           = td.CalcCoreWidth,
                CalcNumStops            = td.CalcNumStops,
                ModifiedOn              = td.ModifiedOn,
                ActFootage              = td.ActFootage,
                CoreType                = NULL,
                RollLength              = td.RollLength,
                RollUnit                = td.RollUnit,
                EstimatedLength         = td.EstimatedLength,
                PrintRepeat             = td.PrintRepeat,
                FlatSizeWidth           = td.FlatSizeWidth,
                FlatSizeLength          = td.FlatSizeLength,
                PackQuantity            = td.PackQuantity,
                NumberUp = td.NumberUp
            FROM 
                TicketDimensions td1 
                INNER JOIN #ticketdimensions td on td1.TicketId = td.TicketId
                --INNER JOIN #MatchingTicketDimensions MTD ON TD.TicketId = MTD.TicketId
                --INNER JOIN #PV_Jobs J ON J.TicketNumber = MTD.TicketNumber
                --LEFT join #QuantityData Q ON J.TicketNumber = Q.TicketNumber
                --LEFT JOIN #ToolSpec TS ON J.TicketNumber = TS.TicketNumber
                --LEFT JOIN #NumData  ND ON J.TicketNumber = ND.TicketNumber
                --LEFT JOIN #JobStepCalc JS ON J.TicketNumber = JS.TicketNumber
                --left join #NoPlateChangesData N ON J.TicketNumber = N.TicketNumber
                --LEFT JOIN #FlatSize FS ON J.TicketNumber = FS.TicketNumber
                

            SET @infoStr ='TotalRowsAffected|'+ Convert(VARCHAR, @@ROWCOUNT)
        
        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END

        -- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
    IF @IsError = 0 
        BEGIN
        SET @blockName = 'InsertTicketDimensions'; SET @startTime = GETDATE();

        BEGIN TRY
            ----Insert the records INTO TicketDimensions table
            INSERT INTO [TicketDimensions] (Id,TicketId,ConsecutiveNumber,Quantity, ActualQuantity,SizeAcross,  SizeAround,Shape,ColumnSpace,RowSpace,
                        NumAcross,NumAroundPlate,LabelRepeat,FinishedNumAcross,FinishedNumLabels,CoreSize,OutsideDiameter,EsitmatedLength,
                        OverRunLength,NoPlateChanges,CalcLinearLength,CalcNumLeftoverRolls,CalcFinishedRollLength,CalcCoreWidth,CalcNumStops,
                        CreatedOn,ModifiedOn,ActFootage,CoreType,RollLength,RollUnit, EstimatedLength, PrintRepeat,FlatSizeWidth,FlatSizeLength,
                        PackQuantity,NumberUp)
                SELECT 
					NEWID(),
                    td.TicketId,
                    td.ConsecutiveNumber,
					td.Quantity,
					td.ActualQuantity,
					td.SizeAcross,
					td.SizeAround,
					td.Shape,
					td.ColumnSpace,
					td.RowSpace,
					td.NumAcross,
					td.NumAroundPlate,
					td.LabelRepeat,
					td.FinishedNumAcross,
					td.FinishedNumLabels,
					td.CoreSize,
					td.OutsideDiameter,
					td.EstimatedLength,
					td.OverRunLength,
					td.NoPlateChanges,
					td.CalcLinearLength,
					td.CalcNumLeftoverRolls,
					td.CalcFinishedRollLength,
					td.CalcCoreWidth,
					td.CalcNumStops,
					GETUTCDATE(),
					td.ModifiedOn,
					td.ActFootage,
					NULL,
					td.RollLength,
					td.RollUnit,
					td.EstimatedLength,
					td.PrintRepeat,
					td.FlatSizeWidth,
					td.FlatSizeLength,
					td.PackQuantity,
                    td.NumberUp
                FROM 
                #ticketdimensions td 
                WHERE td.TicketId not in (SELECT TD.TicketId FROM TicketDimensions TD)

                SET @infoStr ='TotalRowsAffected|'+ Convert(VARCHAR, @@ROWCOUNT)

        END TRY
        BEGIN CATCH
--      ==================================[Do not change]================================================
            SET @IsError = 1; Rollback;
            SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(VARCHAR, ERROR_LINE())
        END CATCH
        INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
    END
    -- BLOCK END

--    ========================[final commit log (do not change)]=======================================
    IF @IsError = 0
    BEGIN
        COMMIT;
        INSERT INTO @__ErrorInfoLog VALUES(@corelationId, 'dbLog', @tenantId, 'database', 'Commited', 0, GETUTCDATE(), 
            @spName, 'final-commit', 'info', 'message|all blocks completed without any error')
    END
    SELECT *, 'tbl_ErrorInfoLog' AS __dataset_tableName FROM @__ErrorInfoLog AS ErrorInfoLog;
--      =================================================================================================



    DROP TABLE IF EXISTS #PV_Jobs;
    DROP TABLE IF EXISTS #MatchingTicketDimensions;
    DROP TABLE IF EXISTS #MatchingNumLeftoverRolls;
    DROP TABLE IF EXISTS #QuantityData
    DROP TABLE IF EXISTS #ToolSpec
    DROP TABLE IF EXISTS #NumData
    DROP TABLE IF EXISTS #JobStepCalc
    DROP TABLE IF EXISTS #NoPlateChangesData
    DROP TABLE IF EXISTS #FlatSize
    DROP TABLE IF EXISTS #PackMaterial
    DROP TABLE IF EXISTS #ticketdimensions;
END