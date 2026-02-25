CREATE TABLE [dbo].[TaskBatch] (
    [TaskBatchID]          INT          IDENTITY (1, 1) NOT NULL,
    [TaskBatchTS]          DATETIME     NOT NULL,
    [TaskBatchCompleteTS]  DATETIME     NULL,
    [DataImportTS]         DATETIME     NULL,
    [DataImportCompleteTS] DATETIME     NULL,
    [TriggerType]          NVARCHAR (3) NULL,
    CONSTRAINT [PK_TaskBatchTaskBatchID] PRIMARY KEY CLUSTERED ([TaskBatchID] ASC)
);

