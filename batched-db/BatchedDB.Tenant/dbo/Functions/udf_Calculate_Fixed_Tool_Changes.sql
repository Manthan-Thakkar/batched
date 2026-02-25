CREATE   FUNCTION [dbo].[udf_Calculate_Fixed_Tool_Changes] (@TicketTo nvarchar(255))

RETURNS int  

AS   
-- Returns Number of color differences between two tickets
BEGIN  
    DECLARE @ret int;
	--Declare @TicketFrom nvarchar(255);
	--Declare @TicketTo nvarchar(255);
	--set @TicketFrom = 87147;
	--set @TicketTo = 87144;
	;with eligibletools as(
	Select Tool
	FROM
		dbo.OpenTicketTools
	Group by Tool
	Having count(*) <= 1
	)
	,
	TicketToTools as(
	Select Tool
	FROM
		dbo.OpenTicketTools
	WHERE 
		Number = @TicketTo and Tool in (Select Tool From eligibletools)
		)

    SELECT @ret = count(ttt.Tool)--@ret = SUM(cc.ColorChange)   
    FROM TicketToTools ttt --(Select ToolChange From  ToolCheckTo Union All Select ToolChange From ToolCheckFrom) tc;
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
