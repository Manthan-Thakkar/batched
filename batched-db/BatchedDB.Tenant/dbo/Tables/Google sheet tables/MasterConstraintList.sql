CREATE TABLE [dbo].[MasterConstraintList] (
    [ID]             INT IDENTITY(1,1) CONSTRAINT [PK_MasterConstraintListID] PRIMARY KEY,
    [Location]       VARCHAR (100) NULL,
    [Press]          VARCHAR (100) NULL,
    [WorkCenter]     VARCHAR (50)  NULL,
    [ConstraintType] VARCHAR (100) NULL,
    [Operator]       VARCHAR (50)  NULL,
    [Limit]          VARCHAR (50)  NULL,
    [HowToIdentify]  VARCHAR (200) NULL,
    [Description]    VARCHAR (255) NULL,
    [Notes]          VARCHAR (400) NULL
);

