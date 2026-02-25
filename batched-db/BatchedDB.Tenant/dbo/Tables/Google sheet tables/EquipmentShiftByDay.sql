CREATE TABLE [dbo].[EquipmentShiftByDay] (
    [ID]          INT IDENTITY(1,1) CONSTRAINT [PK_EquipmentShiftByDayID] PRIMARY KEY,
    [Press]       VARCHAR (100) NULL,
    [TheDayName]  VARCHAR (50)  NULL,
    [Shift Start] DATETIME      NULL,
    [Shift End]   DATETIME      NULL,
    [Start Date]  DATETIME      NULL,
    [End Date]    DATETIME      NULL
);

