CREATE   FUNCTION [dbo].[udf_Calculate_Fixed_Color_Changes] (@TicketTo nvarchar(255))

RETURNS int  

AS   
-- Returns Number of color differences between two tickets
BEGIN  
    DECLARE @ret int;
	--Declare @TicketFrom nvarchar(255);
	--Declare @TicketTo nvarchar(255);
	--set @TicketFrom = 87147;
	--set @TicketTo = 87144;
	;with EligibleColors as (

	Select Color
	From dbo.OpenTicketColors
	Group by Color
	Having count(*) <= 1
	)
,
	TicketToColors as(
	Select Color
	FROM
		dbo.OpenTicketColors
	WHERE 
		TicketNumber = @TicketTo and Color in (Select Color from EligibleColors)
		)

    SELECT @ret = count(ttc.Color)--@ret = SUM(cc.ColorChange)   
    FROM TicketToColors ttc--(Select ColorChange From  ColorCheckTo Union All Select ColorChange From ColorCheckFrom) cc;
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
