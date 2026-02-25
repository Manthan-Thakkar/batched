CREATE TABLE [dbo].[PressDownTime] (
    [ID]         INT IDENTITY(1,1) CONSTRAINT [PK_PressDownTimeID] PRIMARY KEY,
    [Press]      VARCHAR (100) NULL,
    [Start Time] DATETIME      NULL,
    [End Time]   DATETIME      NULL
);

