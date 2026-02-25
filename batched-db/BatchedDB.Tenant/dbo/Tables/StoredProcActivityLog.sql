CREATE TABLE [dbo].[StoredProcActivityLog] (
    [StoredProcActLogID] INT      NOT NULL,
    [StoredProcID]       INT      NOT NULL,
    [TaskBatchID]        INT      NOT NULL,
    [StoredProcStartTS]  DATETIME NULL,
    [StoredProcEndTS]    DATETIME NULL,
    [IsCompleted]        INT      NULL
);

