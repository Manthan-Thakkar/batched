CREATE TABLE [dbo].[HolidaySchedule]
(
	[Id]			VARCHAR(36) NOT NULL,
	[Name]			NVARCHAR(32) NOT NULL,
	[Date]			DATETIME NOT NULL,
	[TenantId]		VARCHAR(36) NOT NULL,
	[CreatedOn]		DATETIME,
	[ModifiedOn]	DATETIME,
    CONSTRAINT [PK_HolidayScheduleId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
