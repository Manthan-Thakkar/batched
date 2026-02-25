Create table TaskClassificationGroup(
	 Id					VARCHAR(36) CONSTRAINT [PK_TaskClassificationGroupId] PRIMARY KEY NOT NULL, 
	 WorkcenterTypeId	VARCHAR(36) NULL,
	 TicketAttributeId	VARCHAR(36) NULL CONSTRAINT [FK_TaskClassificationGroup_TicketAttributeId] FOREIGN KEY REFERENCES TicketAttribute(Id),
	 CreatedOn			DATETIME,
	 ModifiedOn			DATETIME
	 )