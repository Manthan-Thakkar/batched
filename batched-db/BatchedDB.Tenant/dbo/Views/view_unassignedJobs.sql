CREATE   VIEW [dbo].[view_unassignedJobs]

AS

select 
	*,
	case when (upper(TaskWorkCenter) Like '%DIGITAL HP%') 
				then CONCAT_WS('_',upper(TaskWorkCenter), StockNum2, Stock2PressGrouping, Stockwidth2, DueDateBucket)
			when upper(TaskWorkCenter) Like '%DIGICON FINISHING%'
				then CONCAT_WS('_', upper(TaskWorkCenter), Varnish, MainTool, HotFoil, Embossing, StockNum1, CoreSize, DueDateBucket)
			when upper(TaskWorkCenter) Like '%FLEXO PRESS%' 
				then CONCAT_WS('_', upper(TaskWorkCenter), MainTool, StockNum2, InlineSheeter, HotFoil, StockNum1, Turnbar, SandpaperVarnish, ColdFoil, PeelandReveal)
			when upper(TaskWorkCenter) Like '%REWINDER%'
				then CONCAT_WS('_', upper(TaskWorkCenter), CoreSize, NoAcross, Number)
			when upper(TaskWorkCenter) = 'EFI JETRION'
				then CONCAT_WS('_', upper(TaskWorkCenter), StockNum2, Stockwidth2)
			when upper(TaskWorkCenter) Like '%BLANK LABEL PRESS%'
				then CONCAT_WS('_', upper(TaskWorkCenter), MainTool, CoreSize)
			else upper(TaskWorkCenter)
		end as taskClassification,
		case when (upper(TaskWorkCenter) Like '%DIGITAL HP%') 
				then CONCAT_WS('_',upper(TaskWorkCenter), CustomerNum, StockNum2, Stock2PressGrouping, Stockwidth2,
								Varnish, HotFoil, Embossing, StockNum1, MainTool, DueDateBucket)
			when upper(TaskWorkCenter) Like '%DIGICON FINISHING%'
				then CONCAT_WS('_', upper(TaskWorkCenter), Varnish, MainTool, HotFoil, Embossing, StockNum1, CoreSize, DueDateBucket)
			when upper(TaskWorkCenter) Like '%FLEXO PRESS%' 
				then CONCAT_WS('_', upper(TaskWorkCenter), MainTool, StockNum2, InlineSheeter, HotFoil, StockNum1, Turnbar, SandpaperVarnish, ColdFoil, PeelandReveal, Number)
			when upper(TaskWorkCenter) Like '%REWINDER%'
				then CONCAT_WS('_', upper(TaskWorkCenter), CoreSize, NoAcross, Number)
			when upper(TaskWorkCenter) = 'EFI JETRION'
				then CONCAT_WS('_', upper(TaskWorkCenter), StockNum2, Stockwidth2)
			when upper(TaskWorkCenter) Like '%BLANK LABEL PRESS%'
				then CONCAT_WS('_', upper(TaskWorkCenter), MainTool, CoreSize, Number)
			else upper(TaskWorkCenter)
		end as masterrollTaskClassification,
	0 jobFirstAvailable
FROM openFeasibleTicketRoutes
Where taskDueTimeReference IS NOT NULL

