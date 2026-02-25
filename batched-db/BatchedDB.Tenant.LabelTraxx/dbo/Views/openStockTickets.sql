/****** Create view for OpenStockTickets info  ******/

CREATE   VIEW [dbo].[openStockTickets]
AS

SELECT [Number]
      ,t.[CustomerNum]
      ,t.[CustomerName]
      ,[ShipVia]
      ,[OrderDate]
      ,[DateShipped]
      ,[OTSName]
      ,[ITSName]
      ,[EntryDate]
      ,[GeneralDescr]
      ,t.[Notes]
      ,[Ship_by_Date]
	  ,t.Due_on_Site_Date
      ,[TicketType]
      ,[TicQuantity]
      ,[TicketStatus]
	  ,ti.OrderQuantity
	  ,sp.ProductNo
	  ,sp.Desc1
	  ,sp.Location
	  ,sp.Available
	  ,sp.[PhysicalInv]
	  , CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END) as ShipTime
     , Case When t.Due_on_Site_Date IS NULL Then CAST(DATEADD(d, 30, GETDATE()) as Date)
	 		When t.Due_on_Site_Date < GETDATE() Then CAST(GETDATE() as Date)
			Else t.Due_on_Site_Date
			End as [Updated Due Date]
    , Case
				When t.Due_on_Site_Date IS NULL Then -3
				When GetDate()> (CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END)) Then -1
				When   datediff(hh, GETDATE(), (CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END))) < 4 
							Then 0
				Else 2 
				End as [TicketStatusValue]
		,Case
				When t.Due_on_Site_Date IS NULL Then 'Future Ticket'
				When GetDate()> (CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END)) Then 'Late'
				When   datediff(hh, GETDATE(), (CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END))) < 4 
							Then 'At Risk'
				Else 'On Track' 
				End as [TicketStatusText]
  FROM [dbo].[ticket] t
  Left Join [dbo].[ticketItem] ti on t.Number=ti.TicketNumber
  Left Join [dbo].[stockproduct] sp on ti.StockProductID=sp.id
  Where t.TicketType=0 and t.TicketStatus='Open' and t.OrderDate>='1/1/2019' and t.StockTicketType=2
