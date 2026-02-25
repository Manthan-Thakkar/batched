CREATE TABLE [dbo].[AgentType] (
    [Id]              VARCHAR (36)      NOT NULL,
    [Type]            VARCHAR (50)      NOT NULL,
    [CreatedOn]       DATETIME          NOT NULL,
    [ModifiedOn]      DATETIME          NULL,
    CONSTRAINT [PK_AgentTypeId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
);