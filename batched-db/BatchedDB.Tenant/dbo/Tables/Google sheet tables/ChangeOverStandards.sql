CREATE TABLE [dbo].[ChangeOverStandards] (
    [ID]                       INT IDENTITY(1,1) CONSTRAINT PK_ChangeOverStandardsID PRIMARY KEY,
    [Location]                 VARCHAR (50)  NULL,
    [Press]                    VARCHAR (400) NULL,
    [Workcenter]               VARCHAR (100) NULL,
    [Changeover Type]          VARCHAR (100) NULL,
    [Estimated Time (minutes)] FLOAT (53)    NULL,
    [How To Identify]          VARCHAR (255) NULL,
    [Description]              VARCHAR (200) NULL,
    [Notes]                    VARCHAR (400) NULL
);

