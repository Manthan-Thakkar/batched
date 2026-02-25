CREATE TABLE [dbo].[Timezone] (
    [ID]                 NVARCHAR (255) NOT NULL,
    [Name]               NVARCHAR (255) NOT NULL,
    [StandardName]       NVARCHAR (255) NULL,
    [DaylightSavingName] NVARCHAR (255) NULL,
    [DayLightSaving]     BIT            NOT NULL,
    CONSTRAINT [PK_TimezoneID] PRIMARY KEY CLUSTERED ([ID] ASC),
);

