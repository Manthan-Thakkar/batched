CREATE TABLE [dbo].[StoredProcMaster] (
    [StoredProcID]       INT          NOT NULL,
    [StoredProcSequence] INT          NULL,
    [StoredProcName]     VARCHAR (50) NULL,
    [StoredProcParams]   VARCHAR (50) NULL,
    [IsActive]           INT          NULL
);

