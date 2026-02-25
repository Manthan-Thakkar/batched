/** Purpose of this view is to highlight routes for open tickets that do not have any feasible options **/ 

CREATE VIEW dbo.InfeasibleRoutes
AS

WITH FilteredFeasibleRoutes as (
select * from FeasibleRoutes
where RouteFeasible = 1
)

Select tm.SourceTicketId as Number, count(*) as InfeasibleTasks
From TicketTask tt
INNER JOIN TicketMaster tm on tt.TicketId=tm.ID
Left Join FilteredFeasibleRoutes fr on tt.Id=fr.TaskId
Where fr.RouteFeasible IS NULL AND tt.IsComplete = 0
Group by tm.SourceTicketId