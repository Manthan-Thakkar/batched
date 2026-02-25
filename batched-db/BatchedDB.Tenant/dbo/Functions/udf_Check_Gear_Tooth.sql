CREATE   FUNCTION [dbo].[udf_Check_Gear_Tooth] (@Press nvarchar(255),@GearTooth nvarchar(255))

RETURNS int  

AS   
-- Returns Number of color differences between two tickets
BEGIN  
    DECLARE @ret int;
	--Declare @TicketFrom nvarchar(255);
	--Declare @TicketTo nvarchar(255);
	--set @TicketFrom = 87147;
	--set @TicketTo = 87144;
	;with GearTeeth as (
	Select *
		From dbo.FlexoMagCylinders
	WHERE 
		(Press=@Press and ToothSize=@GearTooth))
    
	SELECT @ret = count(gt.Press)--@ret = SUM(cc.ColorChange)   
    FROM GearTeeth gt
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
