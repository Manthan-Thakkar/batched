CREATE TABLE [dbo].[MasterEquipmentReference] (
    [ID]                       INT IDENTITY(1,1) CONSTRAINT [PK_MasterEquipmentReferenceID] PRIMARY KEY,
    [Press]                     VARCHAR (50)  NULL,
    [Description]               VARCHAR (400) NULL,
    [Location]                  VARCHAR (50)  NULL,
    [Value stream]              VARCHAR (100) NULL,
    [WorkCenter]                VARCHAR (50)  NULL,
    [Active]                    VARCHAR (50)  NULL,
    [Available For Planning]    VARCHAR (50)  NULL,
    [Available For Scheduling?] VARCHAR (50)  NULL,
    [Default Shift start]       DATETIME      NULL,
    [Default Shift End]         DATETIME      NULL,
    [Daily Total Hours]         VARCHAR (50)  NULL,
    [Sort Order]                VARCHAR (50)  NULL,
    [Notes]                     VARCHAR (400) NULL
);

