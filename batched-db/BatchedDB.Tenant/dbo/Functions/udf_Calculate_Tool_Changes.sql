CREATE   FUNCTION [dbo].[udf_Calculate_Tool_Changes] (@TicketFrom nvarchar(255),@TicketTo nvarchar(255))

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
	Having count(*) > 1
	)
	
	,
	TicketFromTools as (
	Select Tool
	FROM
		dbo.OpenTicketTools
	WHERE 
		Number = @TicketFrom and Tool in (Select eligibletools.Tool From eligibletools)
		)
	,	
	TicketToTools as(
	Select Tool
	FROM
		dbo.OpenTicketTools
	WHERE 
		Number = @TicketTo and Tool in (Select eligibletools.Tool From eligibletools)
		)
	,
	ToolCheckTo as (
		Select *,
				Case When ttt.Tool in (Select tft.Tool from TicketFromTools tft) Then 0
				Else 1
				End as ToolChange
		From TicketToTools ttt)
	,
	ToolCheckFrom as (
		Select *,
				Case When tft.Tool in (Select ttt.Tool from TicketToTools ttt) Then 0
				Else 1
				End as ToolChange
		From TicketFromTools tft)

    SELECT @ret = sum(tc.ToolChange)--@ret = SUM(cc.ColorChange)   
    FROM ToolCheckTo tc --(Select ToolChange From  ToolCheckTo Union All Select ToolChange From ToolCheckFrom) tc;
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
