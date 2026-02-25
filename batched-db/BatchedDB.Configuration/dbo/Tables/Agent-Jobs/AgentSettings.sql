CREATE TABLE [dbo].[AgentSettings] (
	[ID]				VARCHAR (36)	NOT NULL,
	[AgentId]			VARCHAR(36)		NOT NULL CONSTRAINT [FK_AgentSettings_AgentID] FOREIGN KEY REFERENCES Agent(Id),
	[SettingKey]		NVARCHAR(100)	NOT NULL,
	[SettingValue]		NVARCHAR(MAX),
	[CreatedOn]			DATETIME		NOT NULL,
    [ModifiedOn]		DATETIME		NULL,
    CONSTRAINT [PK_AgentSettingsID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);
