CREATE TABLE [dbo].[ShiftOverrideTimes]
(
	[Id]				VARCHAR(36) NOT NULL,
	[ShiftOverrideId]	VARCHAR(36) NOT NULL CONSTRAINT [FK_ShiftOverrideTimes_ShiftOverrideId] FOREIGN KEY REFERENCES ShiftOverride(Id),
	[StartTime]			TIME NOT NULL,
	[EndTime]			TIME NOT NULL,
	[CreatedOn]			DATETIME,
	[ModifiedOn]		DATETIME,
    CONSTRAINT [PK_ShiftOverrideTimesId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
