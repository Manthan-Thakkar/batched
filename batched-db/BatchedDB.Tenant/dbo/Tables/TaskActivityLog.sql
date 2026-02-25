CREATE TABLE [dbo].[TaskActivityLog] (
    [TaskActLogID] INT      NOT NULL,
    [TaskID]       INT      NOT NULL,
    [TableBatchID] INT      NOT NULL,
    [TaskStartTS]  DATETIME NULL,
    [TaskEndTS]    DATETIME NULL,
    [IsCompleted]  INT      NULL
);

