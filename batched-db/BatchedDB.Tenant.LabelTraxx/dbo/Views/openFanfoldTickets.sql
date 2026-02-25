/****** Create view for OpenFanfoldTickets info  ******/

Create   VIEW [dbo].[openFanfoldTickets]
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
	  ,ActQuantity
      ,[TicketStatus]
	  ,CASE WHEN t.ActQuantity < t.TicQuantity THEN (1 - ISNULL(t.ActQuantity*1.0,0)/t.TicQuantity)*t.EstFinHrs
		Else 0
		End as [EstFinHrs]
	  , CONVERT(DATETIME,CONVERT(VARCHAR,t.[Due_on_Site_Date]) + ' ' +
			CASE 
				WHEN t.ShipVia LIKE '%Ramberg%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Egen Bil%' Then '12:00:00'
				WHEN t.ShipVia LIKE '%Post o/natt%' Then '14:00:00'
				WHEN t.ShipVia LIKE '%Ferdig Pakket%' 
					THEN LEFT(t.ShipVia, charindex(' ', t.ShipVia) - 1)  

				ELSE '14:30:00'
			END) as ShipTime
     , Case When t.Due_on_Site_Date < GETDATE() OR t.Due_on_Site_Date IS NULL Then CAST(GETDATE() as Date)
			Else t.Due_on_Site_Date
			End as [Updated Due Date]
    , Case
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
			,(Select Top(1) EndTime
			From [dbo].[masterSchedule] ms
			Where ms.Number=t.Number
			Order by EndTime DESC) as [LatestTaskTime]
			,Case When (Select Top(1) EndTime
			From [dbo].[masterSchedule] ms
			Where ms.Number=t.Number
			Order by EndTime DESC) IS NULL Then Case When t.Due_on_Site_Date < GETDATE() OR t.Due_on_Site_Date IS NULL Then CAST(GETDATE() as Date)
														Else t.Due_on_Site_Date
														End
			Else Convert(Date, (Select Top(1) EndTime
			From [dbo].[masterSchedule] ms
			Where ms.Number=t.Number
			Order by EndTime DESC))
			End as [EstimatedCompletionDate]
			,(Select Top(1) Press
			From [dbo].[masterSchedule] ms
			Where ms.Number=t.Number
			Order by EndTime DESC) as [LastMachine]
  FROM [dbo].[ticket] t
  Where t.FinishType='Fanfolded' and t.TicketStatus='Open' and t.OrderDate>='1/1/2019'
