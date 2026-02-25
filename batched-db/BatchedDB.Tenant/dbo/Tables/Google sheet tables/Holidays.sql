CREATE TABLE [dbo].[Holidays] (
    [ID]      INT IDENTITY(1,1) CONSTRAINT [PK_HolidaysID] PRIMARY KEY,
    [Holiday] VARCHAR (255) NULL,
    [Date]    DATETIME      NULL
);

