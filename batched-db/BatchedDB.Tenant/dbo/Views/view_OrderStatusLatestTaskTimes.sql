CREATE VIEW [dbo].[view_OrderStatusLatestTaskTimes]
AS

    WITH [RemainingTasks] AS
        (
            SELECT
                [TM].[ID] as [TicketId],
                IIF(COUNT([TT].[Id]) > 0, 1, 0) AS [IsTaskPending]
            FROM [dbo].[TicketMaster] [TM]
                LEFT JOIN [dbo].[TicketTask] [TT] ON [TM].[ID] = [TT].[TicketId] AND [TT].[IsComplete] = 0
                INNER JOIN [dbo].[TicketShipping] [TS] ON [TM].[ID] = [TS].[TicketId]
            WHERE [TS].[ShipByDateTime] IS NOT NULL
                AND (([TM].[IsOpen] = 1 OR [TM].[IsOnHold] = 1))
                AND [TM].[SourceTicketType] IN (0, 1, 3)
                AND [TM].[SourceStockTicketType] != 1
            GROUP BY [TM].[ID]
        )

    -- Latest task times calculation
    SELECT
        [RT].[TicketId],
        [RT].[IsTaskPending],
        CASE
            WHEN [TM].[SourceStatus] = 'Done' THEN [TS].[ShippedOnDate]
			ELSE MAX([SR].[EndsAt])
		END AS [LatestTaskTime]
    FROM [RemainingTasks] [RT]
        INNER JOIN [dbo].[TicketMaster] [TM] ON [RT].[TicketId] = [TM].[ID]
        INNER JOIN [dbo].[TicketShipping] [TS] ON [TM].[ID] = [TS].[TicketId]
        LEFT JOIN [dbo].[ScheduleReport] [SR] ON [TM].[SourceTicketId] = [SR].[SourceTicketId]
    GROUP BY [RT].[TicketId], [RT].[IsTaskPending], [TM].[SourceStatus], [TS].[ShippedOnDate];

GO