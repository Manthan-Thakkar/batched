CREATE TABLE [dbo].[Agent] (
    [ID]              VARCHAR (36)      NOT NULL,
    [Name]            NVARCHAR (64)     NOT NULL,
    [TenantId]		  VARCHAR (36)      NOT NULL CONSTRAINT [FK_Agent_TenantId] FOREIGN KEY REFERENCES Tenant(Id),
    [ApiKey]		  NVARCHAR(50)      NOT NULL,
    [TypeId]		  VARCHAR(36)     CONSTRAINT [FK_Agent_TypeId] FOREIGN KEY REFERENCES AgentType(Id),--FK to AgentType
	[LastHeartBeat]	  DATETIME,
	[AliveSince]	  DATETIME,
	[IsEnabled] 	  BIT               NOT NULL,
    [CreatedOn]       DATETIME          NOT NULL,
    [ModifiedOn]      DATETIME          NULL,
    CONSTRAINT [PK_AgentID] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);