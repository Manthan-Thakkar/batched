CREATE TABLE [dbo].[ShiftCalender] (
    [TheDate]        DATE            NULL,
    [TheDateTime]    DATETIME        NULL,
    [TheHHMM]        NVARCHAR (4000) NULL,
    [isBizDay]       VARCHAR (1)     NULL,
    [TheDayName]     NVARCHAR (30)   NULL,
    [generated_date] DATE            NULL
);

