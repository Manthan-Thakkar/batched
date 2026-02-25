CREATE TABLE [dbo].[TableBatch] (
    [TableBatchID] INT          IDENTITY (1, 1) NOT NULL,
    [TableName]    VARCHAR (50) NULL,
    [IsActive]     INT          NULL,
    CONSTRAINT [PK_TableBatchTableBatchID] PRIMARY KEY CLUSTERED ([TableBatchID] ASC)
);

