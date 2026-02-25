CREATE TABLE [dbo].[FlexoCylinders] (
    [ID]        INT IDENTITY(1,1) CONSTRAINT [PK_FlexoCylindersID] PRIMARY KEY,
    [Press]     VARCHAR (200) NULL,
    [ToothSize] INT           NULL,
    [Repeat]    FLOAT (53)    NULL
);

