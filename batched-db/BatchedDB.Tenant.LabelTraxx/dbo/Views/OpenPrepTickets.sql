Create   View [dbo].[OpenPrepTickets]

As

Select *, Case When tt.StockIn='Ord' Then ISNULL(Case When cast((Select Top (1) [REQUESTEDDELIVERYDATE]
														From [dbo].[purchaseorder]
														Where CLOSED=0 and [ORDERSTOCKNUM]=tt.StockNum2 and POTYPE='Stock'
														Order by DateReq ASC) as varchar(255)) = '1970-01-01' Then 'Ord No Date'
														Else cast((Select Top (1) [REQUESTEDDELIVERYDATE]
														From [dbo].[purchaseorder]
														Where CLOSED=0 and [ORDERSTOCKNUM]=tt.StockNum2 and POTYPE='Stock'
														Order by DateReq ASC) as varchar(255))
														End
														, 'Ord No PO')
		Else tt.StockIn
		End As [StockInText]
		,Case When tt.StockIn='In' Then 1
		When tt.StockIn='Ord' Then -1
		Else 0
		End As [StockInStatus]
		, Case When ArtDone=1 Then 'Yes' Else 'No' End as [ArtStatText]
		, Case When ProofDone=1 Then 'Yes' Else 'No' End as [ProofStatText]
		, Case When PlateDone=1 Then 'Yes' Else 'No' End as [PlateStatText]
		, Case When ToolsIn=1 Then 'Yes' Else  ISNULL(cast((Select Top (1) DateReq
											From [dbo].[purchaseorder]
											Where CLOSED=0 and [TOOLNUM]=tt.MainTool and POTYPE='Tool'
											Order by DateReq ASC) as varchar(255)), 'No') End as [ToolStatText]
		, Case When Is_Ink_In=1 Then 'Yes' Else 'No' End as [InkStatText]
From Ticket tt
Where tt.TicketStatus='Open' and tt.TicketType Not In (1, 3, 0)
