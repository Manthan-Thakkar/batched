CREATE TABLE [dbo].[PressDowntimeGenerated] (
    [Press]              VARCHAR (255) NULL,
    [Start Time]         DATETIME      NULL,
    [End Time]           DATETIME      NULL,
    [StartTimeReference] BIGINT        NULL,
    [EndTimeReference]   BIGINT        NULL,
    [downtimeMinutes]    BIGINT        NULL
);

