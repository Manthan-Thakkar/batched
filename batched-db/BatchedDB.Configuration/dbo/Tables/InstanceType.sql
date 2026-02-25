CREATE TABLE [dbo].[InstanceType]
(
	[ID]				varchar(36)		NOT NULL,
	[InstanceType]		nvarchar(255)	NOT NULL,
	[SmallThreshold]	int				NOT NULL,
	[MediumThreshold]	int				NOT NULL,
	[LargeThreshold]	int				NOT NULL,
	[Threshold]			int				NOT NULL,
	[Platform]			nvarchar(64)	NOT NULL,
	CONSTRAINT [PK_InstanceType] PRIMARY KEY NONCLUSTERED ([Id] ASC)
)
