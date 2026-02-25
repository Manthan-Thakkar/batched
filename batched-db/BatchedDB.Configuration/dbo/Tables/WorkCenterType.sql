CREATE TABLE [dbo].[WorkCenterType] (
    [ID]          VARCHAR (36)  NOT NULL,
    [Name]        NVARCHAR (32)  NULL,
    [Description] NVARCHAR (256) NULL,
    [CreatedOn]   DATETIME      NULL,
    [ModifiedOn]  DATETIME      NULL,
    [IsEnabled]   BIT           NOT NULL,
    CONSTRAINT [PK_WorkCenterTypeID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);

