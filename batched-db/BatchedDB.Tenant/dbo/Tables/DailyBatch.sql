CREATE TABLE [dbo].[DailyBatch] (
    [DailyBatchID] INT      IDENTITY (1, 1) NOT NULL,
    [DailyBatchTS] DATETIME NULL,
    CONSTRAINT [PK_DailyBatchDailyBatchID] PRIMARY KEY CLUSTERED ([DailyBatchID] ASC)
);

