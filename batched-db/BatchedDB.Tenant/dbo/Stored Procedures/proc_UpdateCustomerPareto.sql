
CREATE   PROCEDURE [dbo].[proc_UpdateCustomerPareto]
AS 
BEGIN -- begin procedure

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		declare @rollingMonths int = 12; -- number of months back to use for customer pareto
		declare @pareto_A decimal(6,5) = 0.80; -- percent of cumulative revenue to consider for A customers
		declare @pareto_B decimal(6,5) = 0.90; -- percent of cumulative revenue to consider for B customers

		-- drop customer pareto table before recreating it
		IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE 
			TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'customerPareto'))
			BEGIN
				DROP TABLE dbo.customerPareto
			END
		;

		-- calculate customer pareto rank
		with revByCustomer as (

			SELECT 
				ticket.CustomerNum
				--, SUM(ActualBillings_NetOfSalesTax) as customerRevenue
				, SUM(inv.Total) as customerRevenue
			FROM 
				dbo.Ticket ticket 
			INNER JOIN
				dbo.invoice inv 
				ON ticket.Number = inv.TicketNum
			WHERE 
				ticket.DateShipped >= DATEADD(MONTH,-12, GETDATE())
				AND ticket.ticketType in (0,1,3)
			GROUP BY 
				ticket.CustomerNum


		), paretoCalcs as (

			select 
				rbc.*
				, SUM(customerRevenue) OVER() as totalCustomerRevenue
				, customerRevenue / (SUM(customerRevenue) OVER()) as percOfTotalRevenue
				, ROW_NUMBER() OVER(ORDER BY customerRevenue DESC) as customerIndex
				, COUNT(CustomerNum) OVER() as totalCustomers 
				, (ROW_NUMBER() OVER(ORDER BY customerRevenue DESC)) *1.0 / (COUNT(CustomerNum) OVER()) as percOfTotalCustomers
			from 
				revByCustomer rbc 

		), cumulativeCalc as (

			select
				pc.*
				, (SELECT SUM(customerRevenue) FROM paretoCalcs WHERE customerIndex <= pc.customerIndex) as cumRevenue
			from 
				paretoCalcs pc 

		), output as (

			select 
				cc.*
				, cumRevenue / totalCustomerRevenue as cumProportion
				, CASE 
					WHEN (cumRevenue / totalCustomerRevenue) <= @pareto_A THEN 'A'
					WHEN (cumRevenue / totalCustomerRevenue) <= @pareto_B THEN 'B'
					ELSE 'C'
					END as customerRank
			from 
				cumulativeCalc cc 

		)

		-- write data to table
		select 
			*
			, GETDATE() as lastUpdated
		into 
			dbo.customerPareto
		from 
			output 


		IF XACT_STATE() > 0 COMMIT TRANSACTION
	
	END TRY

	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
	END CATCH

END -- end procedure 
