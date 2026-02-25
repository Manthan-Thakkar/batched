CREATE TABLE [dbo].[ReadFileS3] (
    [ReadFileID]        INT          IDENTITY (1, 1) NOT NULL,
    [ReadFileTitle]     VARCHAR (50) NULL,
    [TableName]         VARCHAR (50) NULL,
    [TaskBatchID]       INT          NULL,
    [ReadFileTimeStamp] DATETIME     NOT NULL,
    CONSTRAINT [PK_ReadFileS3ReadFileID] PRIMARY KEY CLUSTERED ([ReadFileID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ReadFileS3]
    ON [dbo].[ReadFileS3]([ReadFileTitle] ASC);

