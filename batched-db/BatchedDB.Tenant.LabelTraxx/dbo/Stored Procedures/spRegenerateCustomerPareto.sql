CREATE PROCEDURE [dbo].[spRegenerateCustomerPareto]
	@TenantId varchar(36)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


		declare @rollingMonths int = 12; -- number of months back to use for customer pareto
		declare @pareto_A decimal(6,5) = 0.80; -- percent of cumulative revenue to consider for A customers
		declare @pareto_B decimal(6,5) = 0.90; -- percent of cumulative revenue to consider for B customers

		truncate table CustomerRank;
		
		-- calculate customer pareto rank
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
				, Revenue / (SUM(Revenue) OVER()) as RevenuePercent
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
				, CumulativeRevenue / TotalRevenue as CumulativeProportion
				, CASE 
					WHEN (CumulativeRevenue / TotalRevenue) <= @pareto_A THEN 'A'
					WHEN (CumulativeRevenue / TotalRevenue) <= @pareto_B THEN 'B'
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


END
