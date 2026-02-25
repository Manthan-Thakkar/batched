CREATE TABLE [dbo].[masterSchedule] (
    [Number]            VARCHAR (255) NULL,
    [PressNumber]       VARCHAR (255) NULL,
    [Task]              VARCHAR (255) NULL,
    [StartTime]         DATETIME      NULL,
    [TaskMinutes]       FLOAT (53)    NULL,
    [changeoverMinutes] FLOAT (53)    NULL,
    [EndTime]           DATETIME      NULL,
    [Locked]            FLOAT (53)    NULL,
    [masterRollNumber]  VARCHAR (255) NULL,
    [runDate]           DATETIME      NULL
);

