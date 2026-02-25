/****** Object:  UserDefinedTableType [dbo].[udt_TimeZone]    Script Date: 27-10-2022 20:04:30 ******/
CREATE TYPE [dbo].[udt_TimeZone] AS TABLE(
    [Id][nvarchar](255) NOT NULL,
    [Name] [nvarchar](255) NOT NULL,
    [StandardName] [nvarchar](255) NULL,
    [DaylightSavingName] [nvarchar](255) NULL,
    [DayLightSaving] [bit] NOT NULL,
    [LinuxTZ] [nvarchar](255) NOT NULL
    )
GO