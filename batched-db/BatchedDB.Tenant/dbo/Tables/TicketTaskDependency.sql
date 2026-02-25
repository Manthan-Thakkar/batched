CREATE TABLE [dbo].[TicketTaskDependency]
	(
		Id							VARCHAR(36)		NOT NULL,
		TicketTaskDataId			VARCHAR(36)		NOT NULL,
		DependentTicketId			VARCHAR(36)		NOT NULL,
		DependentTicketTaskDataId	VARCHAR(36)		NOT NULL,
		CreatedOnUTC				DATETIME		NOT NULL,
		ModifiedOnUTC				DATETIME		NOT NULL,
		CONSTRAINT [FK_TicketTaskDep_TicketMasterId] FOREIGN KEY ([DependentTicketId]) REFERENCES TicketMaster(Id),
		CONSTRAINT [FK_TicketTaskDep_TicketTaskDataId] FOREIGN KEY ([TicketTaskDataId]) REFERENCES TicketTaskData(Id),
		CONSTRAINT [FK_TicketTaskDep_DependentTicketTaskDataId] FOREIGN KEY ([DependentTicketTaskDataId]) REFERENCES TicketTaskData(Id),
		CONSTRAINT [PK_TicketTaskDependencyId] PRIMARY KEY NONCLUSTERED ([Id] ASC)
	);