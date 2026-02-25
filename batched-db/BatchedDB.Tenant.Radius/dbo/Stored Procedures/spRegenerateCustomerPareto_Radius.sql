CREATE PROCEDURE [dbo].[spRegenerateCustomerPareto_Radius]
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spRegenerateCustomerPareto_Radius',
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
	
	DECLARE @rollingMonths int = 12; -- number of months back to use for customer pareto
	DECLARE @pareto_A decimal(6,5) = 0.80; -- percent of cumulative revenue to consider for A customers
	DECLARE @pareto_B decimal(6,5) = 0.90; -- percent of cumulative revenue to consider for B customers

	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'TruncateCustomerRank'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			TRUNCATE TABLE CustomerRank;

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
	-- REPEATE THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'InsertCustomerRank'; SET @startTime = GETDATE();
		BEGIN TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			
			WITH revenueByCustomer AS (
				SELECT 
					PVS.CustCode SourceCustomerId
					, SUM(PVSL.BillValue) AS Revenue
				FROM 
					PV_SOrder PVS
				INNER JOIN
					PV_SOrderLine PVSL 
					ON PVS.SOrderNum = PVSL.SOrderNum
				WHERE 
					PVS.CompletedDate >= DATEADD(MONTH,-12, GETDATE())
				GROUP BY 
					PVS.CustCode

			)
			, CustomerRankCalculations AS (
				SELECT 
					rbc.SourceCustomerId
					, rbc.Revenue
					, SUM(Revenue) OVER() as TotalRevenue
					, CASE WHEN SUM(Revenue) OVER() = 0 THEN 0 ELSE  Revenue / (SUM(Revenue) OVER()) END AS RevenuePercent
					, ROW_NUMBER() OVER(ORDER BY Revenue DESC) as RevenueRank
					, COUNT(SourceCustomerId) OVER() as TotalCustomers 
					, (ROW_NUMBER() OVER(ORDER BY Revenue DESC)) * 1.0 / (COUNT(SourceCustomerId) OVER()) AS RevenuePercentile
				FROM 
					revenueByCustomer rbc 

			)
			, cumulativeCalculations AS (

				--select top 10
				--	pc.*
				--	, (SELECT SUM(Revenue) FROM CustomerRankCalculations WHERE RevenueRank <= pc.RevenueRank) as CumulativeRevenue
				--from 
				--	CustomerRankCalculations pc 

				SELECT 
					CRC1.SourceCustomerId, 
					CRC1.Revenue, 
					CRC1.TotalRevenue, 
					CRC1.RevenuePercent, 
					CRC1.RevenueRank, 
					CRC1.TotalCustomers, 
					CRC1.RevenuePercentile, 
					SUM(CRC2.Revenue) AS CumulativeRevenue
				FROM CustomerRankCalculations CRC1
				INNER JOIN CustomerRankCalculations CRC2 ON CRC1.RevenueRank >= CRC2.RevenueRank
				GROUP BY CRC1.SourceCustomerId, CRC1.Revenue, CRC1.TotalRevenue, CRC1.RevenuePercent, CRC1.RevenueRank, CRC1.TotalCustomers, CRC1.RevenuePercentile


			), revenueOutput AS (

				SELECT 
					cc.*
					, CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue  END AS CumulativeProportion
					, CASE 
						WHEN (CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue END) <= @pareto_A THEN 'A'
						WHEN (CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue END) <= @pareto_B THEN 'B'
						ELSE 'C'
					END AS Rank
				FROM 
					cumulativeCalculations cc 

			)

			-- write data to table
			INSERT INTO CustomerRank(ID, TenantId, Source, SourceCustomerId, Revenue, TotalRevenue, CumulativeRevenue, CumulativeProportion, RevenuePercent, RevenuePercentile, RevenueRank, TotalCustomers, Rank, HasCustomRank, CreatedOn, ModifiedOn)
			SELECT 
				NEWID(),
				@TenantId,
				'Radius',
				SourceCustomerId,
				Revenue,
				TotalRevenue,
				CumulativeRevenue,
				CumulativeProportion,
				RevenuePercent,
				RevenuePercentile,
				RevenueRank,
				TotalCustomers,
				Rank,
				CAST(0 AS bit) HasCustomRank,
				GETUTCDATE(),
				GETUTCDATE()
			FROM 
				revenueOutput 


				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		BEGIN CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; ROLLBACK;
			SET @ErrorStr = 'systemError|' +  ERROR_MESSAGE() +'#ErrorLine|'+ CONVERT(varchar, ERROR_LINE())
--		=======================[Concate more error strings after this]===================================
        --	SET @ErrorStr = @ErrorStr + '#Some_More_Infos|Some_Useful_value'	
		END CATCH
		INSERT @__ErrorInfoLog EXEC spLogCreator @CorelationId, @TenantId, @SPName, @IsError, @startTime, @maxCustomMessageSize, @blockName OUTPUT, @warningStr OUTPUT, @errorStr OUTPUT, @infoStr OUTPUT
	END
	-- BLOCK END
	
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

