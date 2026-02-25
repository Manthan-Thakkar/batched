CREATE TABLE [dbo].[TicketTaskData] --successor to TicketTask
	(
		Id					VARCHAR(36)		NOT NULL,
		TicketId			VARCHAR(36)		NOT NULL,
		TaskName			NVARCHAR(255)   NOT NULL,
		[Sequence]			SMALLINT		NOT NULL,
		OriginalEquipmentId	VARCHAR(36)	    NOT NULL, 
		ActualEquipmentId	VARCHAR(36)	    NULL,
		WorkcenterId		VARCHAR(36)		NULL,
		IsComplete			bit				NOT  NULL,
		EstMakeReadyHours	real			NULL,
		EstWashupHours		real			NULL,
		EstRunHours			real			NULL,
		EstTotalHours		real			NULL,
		EstMaxDueDateTime	DATETIME		NULL,
		EstMeters			real			null,
		IsProductionReady	bit             NOT NULL,
		NetQuantityProduced real			NULL,

		--Rules Engine Fields
		--Naseem: check naming conventions around '_'
		--Naseem: we could populate these during the spSinkRulesImports stored procedure 
		IsApplicable				bit				NULL,
		[RE_TaskName]				NVARCHAR(255)   NULL,
		[RE_Sequence]				SMALLINT		NULL,
		[RE_OriginalEquipmentId]	VARCHAR(36)	    NULL,
		[RE_ActualEquipmentId]		VARCHAR(36)	    NULL, 
		[RE_WorkcenterId]			VARCHAR(36)		NULL,
		[RE_IsComplete]				bit				NULL,
		[RE_EstMakeReadyHours]		real			NULL,
		[RE_EstWashupHours]			real			NULL,
		[RE_EstRunHours]			real			NULL,
		[RE_EstTotalHours]			real			NULL,
		[RE_EstMaxDueDateTime]		DATETIME		NULL,
		[RE_Pass]					int             NULL,
		[RE_DoublePassJob]			int				NULL,
		[RE_DoublePassReInsertionFlag] int			NULL,
		[RE_EstMeters]				real			NULL,
		[RE_IsProductionReady]		bit             NULL,
		[RE_Lag]					real			NULL,
		[RE_Delay]					real            NULL,
		--Meta Fields
		CreatedOnUTC		DATETIME		NOT NULL,
		ModifiedOnUTC		DATETIME		NOT NULL,
		CONSTRAINT [FK_TicketTaskData_Original_EquipmentMasterId] FOREIGN KEY ([OriginalEquipmentId]) REFERENCES EquipmentMaster(Id),
		CONSTRAINT [FK_TicketTaskData_TicketMasterId] FOREIGN KEY ([TicketId]) REFERENCES TicketMaster(Id),
		CONSTRAINT [PK_TicketTaskDataId] PRIMARY KEY NONCLUSTERED ([Id] ASC),

		CONSTRAINT [FK_TicketTaskData_RE_Original_EquipmentMasterId] FOREIGN KEY ([RE_OriginalEquipmentId]) REFERENCES EquipmentMaster(Id)
	);