CREATE   FUNCTION [dbo].[udf_Calculate_Color_Changes] (@TicketFrom nvarchar(255),@TicketTo nvarchar(255))

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
	Having count(*) > 1
	)

	, TicketFromColors as (
	Select Color
	FROM
		dbo.OpenTicketColors
	WHERE 
		TicketNumber = @TicketFrom and Color in (Select Color from EligibleColors)
		)
	,
	TicketToColors as(
	Select Color
	FROM
		dbo.OpenTicketColors
	WHERE 
		TicketNumber = @TicketTo and Color in (Select Color from EligibleColors)
		)
	,
	ColorCheckTo as (
		Select *,
				Case When ttc.Color = 'C' Then
					Case When Exists (Select tfc.Color from TicketFromColors tfc Where tfc.Color in ('C', 'CYAN')) Then 0
						Else 1
					End
				When ttc.Color = 'M' Then
					Case When Exists (Select tfc.Color from TicketFromColors tfc Where tfc.Color in ('M', 'MAGENTA')) Then 0
						Else 1
					End
				When ttc.Color = 'Y' Then
					Case When Exists (Select tfc.Color from TicketFromColors tfc Where tfc.Color in ('Y', 'YELLOW')) Then 0
						Else 1
					End
				When ttc.Color = 'K' Then
					Case When Exists (Select tfc.Color from TicketFromColors tfc Where tfc.Color in ('K', 'BLACK')) Then 0
						Else 1
					End
				When ttc.Color in (Select tfc.Color From TicketFromColors tfc) Then 0
				Else 1
				End as ColorChange
		From TicketToColors ttc)
	,
	ColorCheckFrom as (
		Select *,
				Case When tfc.Color in (Select ttc.Color From TicketToColors ttc) Then 0
				Else 1
				End as ColorChange
		From TicketFromColors tfc)

    SELECT @ret = sum(cc.ColorChange)--@ret = SUM(cc.ColorChange)   
    FROM ColorCheckTo cc--(Select ColorChange From  ColorCheckTo Union All Select ColorChange From ColorCheckFrom) cc;
	IF (@ret IS NULL)   
        SET @ret = 0; 
	return @ret;
END;
