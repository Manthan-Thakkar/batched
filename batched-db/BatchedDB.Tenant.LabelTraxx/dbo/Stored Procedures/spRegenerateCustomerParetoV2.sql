CREATE PROCEDURE spRegenerateCustomerParetoV2
	-- Standard parameters for all stored procedures
	@TenantId		nvarchar(36),
	@CorelationId varchar(100)
AS	
BEGIN

	SET NOCOUNT ON;

	BEGIN
--	==============================logging variables (do not change)=======================================
	DECLARE 
		@spName					varchar(100) = 'spRegenerateCustomerParetoV2',
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
	
	declare @rollingMonths int = 12; -- number of months back to use for customer pareto
	declare @pareto_A decimal(6,5) = 0.80; -- percent of cumulative revenue to consider for A customers
	declare @pareto_B decimal(6,5) = 0.90; -- percent of cumulative revenue to consider for B customers

	-- REPEAT THIS BLOCK FOR ALL LOGICAL UNITS
	IF @IsError = 0	
	BEGIN
		SET @blockName = 'TruncateCustomerRank'; SET @startTime = GETDATE();
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			truncate table CustomerRank;

			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
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
		Begin TRY		
		--	INSERT YOUR LOGIC BLOCK HERE
			
			
			with revenueByCustomer as (
				SELECT 
					T.CustomerNum SourceCustomerId
					, SUM(I.Total) as Revenue
				FROM 
					dbo.Ticket T 
				INNER JOIN
					dbo.Invoice I 
					ON T.Number = I.TicketNum
				WHERE 
					T.DateShipped >= DATEADD(MONTH,-12, GETDATE())
					AND T.TicketType in (0,1,3)
				GROUP BY 
					T.CustomerNum

			)
			, CustomerRankCalculations as (
				select 
					rbc.SourceCustomerId
					, rbc.Revenue
					, SUM(Revenue) OVER() as TotalRevenue
					, CASE WHEN SUM(Revenue) OVER() = 0 THEN 0 ELSE  Revenue / (SUM(Revenue) OVER()) END as RevenuePercent
					, ROW_NUMBER() OVER(ORDER BY Revenue DESC) as RevenueRank
					, COUNT(SourceCustomerId) OVER() as TotalCustomers 
					, (ROW_NUMBER() OVER(ORDER BY Revenue DESC)) * 1.0 / (COUNT(SourceCustomerId) OVER()) as RevenuePercentile
				from 
					revenueByCustomer rbc 

			)
			, cumulativeCalculations as (

				--select top 10
				--	pc.*
				--	, (SELECT SUM(Revenue) FROM CustomerRankCalculations WHERE RevenueRank <= pc.RevenueRank) as CumulativeRevenue
				--from 
				--	CustomerRankCalculations pc 

				select 
					CRC1.SourceCustomerId, 
					CRC1.Revenue, 
					CRC1.TotalRevenue, 
					CRC1.RevenuePercent, 
					CRC1.RevenueRank, 
					CRC1.TotalCustomers, 
					CRC1.RevenuePercentile, 
					SUM(CRC2.Revenue) as CumulativeRevenue
				from CustomerRankCalculations CRC1
				inner join CustomerRankCalculations CRC2 on CRC1.RevenueRank >= CRC2.RevenueRank
				group by CRC1.SourceCustomerId, CRC1.Revenue, CRC1.TotalRevenue, CRC1.RevenuePercent, CRC1.RevenueRank, CRC1.TotalCustomers, CRC1.RevenuePercentile


			), output as (

				select 
					cc.*
					, CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue  END as CumulativeProportion
					, CASE 
						WHEN (CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue END) <= @pareto_A THEN 'A'
						WHEN (CASE WHEN TotalRevenue = 0 THEN 0 ELSE CumulativeRevenue / TotalRevenue END) <= @pareto_B THEN 'B'
						ELSE 'C'
					END as Rank
				from 
					cumulativeCalculations cc 

			)

			-- write data to table
			INSERT INTO CustomerRank(ID, TenantId, Source, SourceCustomerId, Revenue, TotalRevenue, CumulativeRevenue, CumulativeProportion, RevenuePercent, RevenuePercentile, RevenueRank, TotalCustomers, Rank, HasCustomRank, CreatedOn, ModifiedOn)
			select 
				NEWID(),
				@TenantId,
				'LabelTraxx',
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
				CAST(0 as bit) HasCustomRank,
				GETUTCDATE(),
				GETUTCDATE()
			from 
				output 


				
			SET @infoStr = 'TotalRowsAffected|' +  CONVERT(varchar, @@ROWCOUNT)

		END TRY
		Begin CATCH
--		==================================[Do not change]================================================
			SET @IsError = 1; Rollback;
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
GO