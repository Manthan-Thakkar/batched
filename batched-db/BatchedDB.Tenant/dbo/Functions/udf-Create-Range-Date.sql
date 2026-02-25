CREATE   FUNCTION [dbo].[udf-Create-Range-Date] (@DateFrom datetime,@DateTo datetime,@DatePart varchar(10),@Incr int)

Returns 
@ReturnVal Table (RetVal datetime)

As
Begin
    With DateTable As (
        Select DateFrom = @DateFrom
        Union All
        Select Case @DatePart
               When 'YY' then DateAdd(YY, @Incr, df.dateFrom)
               When 'QQ' then DateAdd(QQ, @Incr, df.dateFrom)
               When 'MM' then DateAdd(MM, @Incr, df.dateFrom)
               When 'WK' then DateAdd(WK, @Incr, df.dateFrom)
               When 'DD' then DateAdd(DD, @Incr, df.dateFrom)
               When 'HH' then DateAdd(HH, @Incr, df.dateFrom)
               When 'MI' then DateAdd(MI, @Incr, df.dateFrom)
               When 'SS' then DateAdd(SS, @Incr, df.dateFrom)
               End
        From DateTable DF
        Where DF.DateFrom < @DateTo
    )

    Insert into @ReturnVal(RetVal) Select DateFrom From DateTable option (maxrecursion 0)

    Return
End
