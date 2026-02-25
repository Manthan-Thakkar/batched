CREATE TABLE [dbo].[PressUpTime] (
    [ID]         INT IDENTITY(1,1) CONSTRAINT [PK_PressUpTimeID] PRIMARY KEY,
    [Press]      VARCHAR (100) NULL,
    [Start Time] DATETIME      NULL,
    [End Time]   DATETIME      NULL
);

