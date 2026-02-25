CREATE   FUNCTION [dbo].[udf_Check_Stock_Substitutes] (@StockFrom nvarchar(255),@StockTo nvarchar(255))

RETURNS int  

AS   
-- Returns Number of color differences between two tickets
BEGIN  
    DECLARE @ret int;
	--Declare @TicketFrom nvarchar(255);
	--Declare @TicketTo nvarchar(255);
	--set @TicketFrom = 87147;
	--set @TicketTo = 87144;
	;with StockSubstitues as (
	Select *
	FROM
		[dbo].[StockSubstitutes]
	WHERE 
		(StockNum=@StockFrom and StockSubstitute=@StockTo) OR (StockNum=@StockTo and StockSubstitute=@StockFrom))
    
	SELECT @ret = count(ss.StockNum)--@ret = SUM(cc.ColorChange)   
    FROM StockSubstitues ss
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
